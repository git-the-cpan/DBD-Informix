/*
 * @(#)dbdimp.ec	51.1 97/02/26 10:11:12
 *
 * DBD::Informix for Perl Version 5 -- implementation details
 *
 * Portions Copyright
 *           (c) 1994,1995 Tim Bunce
 *           (c) 1995,1996 Alligator Descartes
 *           (c) 1994      Bill Hailes
 *           (c) 1996      Terry Nightingale
 *           (c) 1996,1997 Jonathan Leffler
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 */

/*TABSTOP=4*/

#ifndef lint
static const char sccs[] = "@(#)dbdimp.ec	51.1 97/02/26";
#endif

#include <stdio.h>
#include <string.h>

#define MAIN_PROGRAM	/* Embed SCCS identification of JLSS headers */
#include "Informix.h"
#include "decsci.h"

/*
** Check whether key defined by key length (kl) and key value (kv)
** matches keyword (kw), which should be a character literal ("KeyWord")!
*/
#define KEY_MATCH(kl, kv, kw) ((kl) == (sizeof(kw) - 1) && strEQ((kv), (kw)))

DBISTATE_DECLARE;

static const char module[] = "DBD::Informix";

static SV *dbd_errnum = NULL;
static SV *dbd_errstr = NULL;

/* One day, this will go! */
static void del_statement(imp_sth_t *imp_sth);

/* ================================================================= */
/* ==================== Driver Level Operations ==================== */
/* ================================================================= */

/* Do some semi-standard initialization */
void
dbd_dr_init(dbistate)
dbistate_t     *dbistate;
{
	DBIS = dbistate;
	dbd_errnum = GvSV(gv_fetchpv("DBD::Informix::err", 1, SVt_IV));
	dbd_errstr = GvSV(gv_fetchpv("DBD::Informix::errstr", 1, SVt_PV));
}

/* Formally initialize the DBD::Informix driver structure */
int
dbd_ix_driver(SV *drh)
{
	D_imp_drh(drh);

	imp_drh->n_connections = 0;			/* No active connections */
	imp_drh->current_connection = 0;	/* No name */
#if ESQLC_VERSION < 600
	imp_drh->multipleconnections = 1;		/* Multiple connections allowed */
#else
	imp_drh->multipleconnections = 0;		/* Multiple connections forbidden */
#endif /* ESQLC_VERSION */
	new_headlink(&imp_drh->head);		/* Linked list of connections */
	return 1;
}

/* Relay function for use by destroy_chain() */
/* Destroys a statement when a database connection is destroyed */
static void dbd_st_destroyer(void *data)
{
	dbd_ix_debug(1, "%s::dbd_st_destroyer()\n", module);
	del_statement((imp_sth_t *)data);
}

/* Delete all the statements (and other data) associated with a connection */
static void del_connection(imp_dbh_t *imp_dbh)
{
	dbd_ix_debug(1, "Enter %s::del_connection()\n", module);
	destroy_chain(&imp_dbh->head, dbd_st_destroyer);
	dbd_ix_debug(1, "Exit %s::del_connection()\n", module);
}

/* Relay (interface) function for use by destroy_chain() */
/* Destroys a database connection when a driver is destroyed */
static void dbd_db_destroyer(void *data)
{
	dbd_ix_debug(1, "%s::dbd_db_destroyer()\n", module);
	del_connection((imp_dbh_t *)data);
}

/* Disconnect all connections (cleanly) */
int dbd_dr_disconnectall(imp_drh_t *imp_drh)
{
	dbd_ix_debug(1, "Enter %s::dbd_dr_disconnectall()\n", module);
	destroy_chain(&imp_drh->head, del_connection);
	dbd_ix_debug(1, "Exit %s::dbd_dr_disconnectall()\n", module);
}

/* Print message if debug level set high enough */
void
dbd_ix_debug(int n, char *fmt, const char *arg)
{
	if (DBIS->debug >= n)
		warn(fmt, arg);
}

/* Format a Informix error message (both SQL and ISAM parts) */
void            dbd_ix_seterror(ErrNum rc)
{
	char            errbuf[256];
	char            fmtbuf[256];
	char            sql_buf[256];
	char            isambuf[256];
	char            msgbuf[sizeof(sql_buf)+sizeof(isambuf)];

	if (rc < 0)
	{
		/* Format SQL (primary) error */
		if (rgetmsg(rc, errbuf, sizeof(errbuf)) != 0)
			strcpy(errbuf, "<<Failed to locate SQL error message>>");
		sprintf(fmtbuf, errbuf, sqlca.sqlerrm);
		sprintf(sql_buf, "SQL: %ld: %s", rc, fmtbuf);

		/* Format ISAM (secondary) error */
		if (sqlca.sqlerrd[1] != 0)
		{
			if (rgetmsg(sqlca.sqlerrd[1], errbuf, sizeof(errbuf)) != 0)
				strcpy(errbuf, "<<Failed to locate ISAM error message>>");
			sprintf(fmtbuf, errbuf, sqlca.sqlerrm);
			sprintf(isambuf, "ISAM: %ld: %s", sqlca.sqlerrd[1], fmtbuf);
		}
		else
			isambuf[0] = '\0';

		/* Concatenate SQL and ISAM messages */
		/* Note that the messages have trailing newlines */
		strcpy(msgbuf, sql_buf);
		strcat(msgbuf, isambuf);

		/* Record error number and error message */
		sv_setiv(dbd_errnum, (IV)rc);
		sv_setpv(dbd_errstr, msgbuf);
	}
}

/* Record (and report) and SQL error, saving SQLCA information */
void            dbd_ix_sqlcode(imp_dbh_t *imp_dbh)
{
	/* Save the current sqlca record */
	imp_dbh->sqlca = sqlca;

	/* If there is an error, record it */
	if (sqlca.sqlcode < 0)
	{
		dbd_ix_seterror(sqlca.sqlcode);
		if (imp_dbh->autoreport)
		{
			STRLEN len;
			warn("%s", SvPV(dbd_errstr, len));
		}
	}
}

/* Convert string into BlobLocn value */
static BlobLocn blob_bindtype(SV *valuesv)
{
	STRLEN vlen;
	char *value = SvPV(valuesv, vlen);
	BlobLocn locn = BLOB_DEFAULT;

	if (KEY_MATCH(vlen, value, "InMemory"))
		locn = BLOB_IN_MEMORY;
	else if (KEY_MATCH(vlen, value, "InFile"))
		locn = BLOB_IN_NAMEFILE;
	else if (KEY_MATCH(vlen, value, "DummyValue"))
		locn = BLOB_DUMMY_VALUE;
	else if (KEY_MATCH(vlen, value, "NullValue"))
		locn = BLOB_NULL_VALUE;
	else
		locn = BLOB_DEFAULT;
	return(locn);
}

/* Convert string into BlobLocn value */
static char *blob_bindname(BlobLocn locn)
{
	char *value = 0;

	switch (locn)
	{
	case BLOB_IN_MEMORY:
		value =  "InMemory";
		break;
	case BLOB_IN_NAMEFILE:
		value = "InFile";
		break;
	case BLOB_DUMMY_VALUE:
		value = "DummyValue";
		break;
	case BLOB_NULL_VALUE:
		value = "NullValue";
		break;
	default:
		value = "Default";
		break;
	}
	return(value);
}

/* ================================================================= */
/* =================== Database Level Operations =================== */
/* ================================================================= */

/* Initialize a connection structure, allocating names */
static void     new_connection(imp_dbh)
imp_dbh_t      *imp_dbh;
{
	static long     connection_num = 0;
	sprintf(imp_dbh->nm_connection, "x_%09ld", connection_num);
	imp_dbh->is_onlinedb  = False;
	imp_dbh->is_loggeddb  = False;
	imp_dbh->is_modeansi  = False;
	imp_dbh->is_txactive  = False;
	imp_dbh->autocommit   = False;
	imp_dbh->is_connected = False;
	connection_num++;
}

int
dbd_db_connect(imp_dbh, name, user, pass)
imp_dbh_t      *imp_dbh;
char           *name;			/* Database name */
char           *user;			/* User name */
char           *pass;			/* Password */
{
	D_imp_drh_from_dbh;
	Boolean conn_ok;

	new_connection(imp_dbh);
	if (name && !*name)
		name = 0;

#if ESQLC_VERSION >= 600
	if (user && !*user)
		user = 0;
	if (pass && !*pass)
		pass = 0;
	/* 6.00 and later versions of Informix-ESQL/C support CONNECT */
	conn_ok = dbd_ix_connect(imp_dbh->nm_connection, name, user, pass);
#else
	/* Pre-6.00 versions of Informix-ESQL/C do not support CONNECT */
	/* Use DATABASE statement */
	conn_ok = dbd_ix_opendatabase(name);
#endif	/* ESQLC_VERSION >= 600 */

	if (sqlca.sqlcode < 0)
	{
		/* Failure of some sort */
		dbd_ix_seterror(sqlca.sqlcode);
		return 0;
	}

	/* Examine sqlca to see what sort of database we are hooked up to */
	imp_dbh->database = name;
	imp_dbh->is_onlinedb = (sqlca.sqlwarn.sqlwarn3 == 'W');
	imp_dbh->is_modeansi = (sqlca.sqlwarn.sqlwarn2 == 'W');
	imp_dbh->is_loggeddb = (sqlca.sqlwarn.sqlwarn1 == 'W');
	imp_dbh->is_connected = conn_ok;
	if (imp_dbh->is_modeansi)
		imp_dbh->is_txactive = True;

	/* Unlogged databases are deemed to be in autocommit mode */
	/* They cannot be switched out of autocommit mode */
	/* MODE ANSI databases are not in AutoCommit by default */
	/* Logged non-ANSI databases are in AutoCommit by default */
	if (imp_dbh->is_modeansi)
		imp_dbh->autocommit = False;
	else
		imp_dbh->autocommit = True;
	imp_dbh->autoreport = True;

	/* Record extra active connection and name of current connection */
	imp_drh->n_connections++;
	imp_drh->current_connection = imp_dbh->nm_connection;

	add_link(&imp_drh->head, &imp_dbh->chain);
	imp_dbh->chain.data = (void *)imp_dbh;
	new_headlink(&imp_dbh->head);

	DBIc_IMPSET_on(imp_dbh);	/* imp_dbh set up now                   */
	DBIc_ACTIVE_on(imp_dbh);	/* call disconnect before freeing       */
	return 1;
}

/* Internal implementation of BEGIN WORK */
/* Assumes correct connection is already set */
static int      dbd_ix_begin(imp_dbh_t *dbh)
{
	int rc = 1;

	EXEC SQL BEGIN WORK;
	dbd_ix_sqlcode(dbh);
	if (sqlca.sqlcode < 0)
		rc = 0;
	else
		dbh->is_txactive = True;
	return rc;
}

/* Internal implementation of COMMIT WORK */
/* Assumes correct connection is already set */
static int      dbd_ix_commit(imp_dbh_t *dbh)
{
	int rc = 1;

	EXEC SQL COMMIT WORK;
	dbd_ix_sqlcode(dbh);
	if (sqlca.sqlcode < 0)
		rc = 0;
	else if (dbh->is_modeansi == False)
		dbh->is_txactive = False;
	return rc;
}

/* Internal implementation of ROLLBACK WORK */
/* Assumes correct connection is already set */
static int      dbd_ix_rollback(imp_dbh_t *dbh)
{
	int rc = 1;

	EXEC SQL ROLLBACK WORK;
	dbd_ix_sqlcode(dbh);
	if (sqlca.sqlcode < 0)
		rc = 0;
	else if (dbh->is_modeansi == False)
		dbh->is_txactive = False;
	return rc;
}

/* External interface for BEGIN WORK */
int
dbd_db_begin(imp_dbh_t *imp_dbh)
{
	int             rc = 1;

	if (imp_dbh->is_loggeddb != 0)
	{
		if (dbd_ix_setconnection(imp_dbh) == 0)
			return(0);
		rc = dbd_ix_begin(imp_dbh);
	}
	return rc;
}

/* External interface for COMMIT WORK */
int
dbd_db_commit(imp_dbh_t *imp_dbh)
{
	int             rc = 1;

	if (imp_dbh->is_loggeddb != 0)
	{
		if (dbd_ix_setconnection(imp_dbh) == 0)
			return(0);
		if ((rc = dbd_ix_commit(imp_dbh)) != 0)
		{
			if (imp_dbh->is_modeansi == False && imp_dbh->autocommit == False)
				rc = dbd_ix_begin(imp_dbh);
		}
	}
	return rc;
}

/* External interface for ROLLBACK WORK */
int
dbd_db_rollback(imp_dbh_t *imp_dbh)
{
	int             rc = 1;

	if (imp_dbh->is_loggeddb != 0)
	{
		if (dbd_ix_setconnection(imp_dbh) == 0)
			return(0);
		if ((rc = dbd_ix_rollback(imp_dbh)) != 0)
		{
			if (imp_dbh->is_modeansi == False && imp_dbh->autocommit == False)
				rc = dbd_ix_begin(imp_dbh);
		}
	}
	return rc;
}

/* Close a connection, destroying any dependent statements */
int
dbd_db_disconnect(imp_dbh_t *imp_dbh)
{
	D_imp_drh_from_dbh;
	int junk;

	dbd_ix_debug(1, "Enter %s::dbd_db_disconnect\n", module);

	if (dbd_ix_setconnection(imp_dbh) == 0)
	{
		dbd_ix_debug(1, "dbd_db_disconnect -- %s\n", "set connection failed");
		return(0);
	}

	dbd_ix_debug(1, "%s::dbd_db_disconnect -- delete statements\n", module);
	destroy_chain(&imp_dbh->head, dbd_st_destroyer);
	dbd_ix_debug(1, "%s::dbd_db_disconnect -- statements deleted\n", module);

	/* Rollback transaction before disconnecting */
	if (imp_dbh->is_loggeddb == True && imp_dbh->is_txactive == True)
		junk = dbd_ix_rollback(imp_dbh);

#if ESQLC_VERSION >= 600
	dbd_ix_disconnect(imp_dbh->nm_connection);
#else
	if (imp_dbh->is_connected == True)
		dbd_ix_closedatabase();
#endif	/* ESQLC_VERSION >= 600 */

	dbd_ix_sqlcode(imp_dbh);
	imp_dbh->is_connected = False;

	/* We assume that disconnect will always work       */
	/* since most errors imply already disconnected.    */
	DBIc_ACTIVE_off(imp_dbh);

	/* Record loss of connection in driver block */
	imp_drh->n_connections--;
	imp_drh->current_connection = 0;
	assert(imp_drh->n_connections >= 0);

	/* We don't free imp_dbh since a reference still exists	 */
	/* The DESTROY method is the only one to 'free' memory.	 */
	dbd_ix_debug(1, "Exit %s::dbd_db_disconnect\n", module);
	return 1;
}

void
dbd_db_destroy(imp_dbh_t *imp_dbh)
{
	dbd_ix_debug(1, "%s::dbd_db_destroy()\n", module);
	if (DBIc_ACTIVE(imp_dbh))
		dbd_db_disconnect(imp_dbh);
	DBIc_IMPSET_off(imp_dbh);
}

/* Set database connection attributes */
int             dbd_db_STORE(imp_dbh_t *imp_dbh, SV *keysv, SV *valuesv)
{
	STRLEN          kl;
	char           *key = SvPV(keysv, kl);
	int             on = SvTRUE(valuesv);

	dbd_ix_debug(1, "%s::dbd_db_DESTROY()\n", module);
	if (KEY_MATCH(kl, key, "AutoCommit"))
	{
		if (imp_dbh->is_loggeddb == False)
		{
			assert(imp_dbh->autocommit == True);
			if (on == False)
				warn("Cannot unset AutoCommit for unlogged databases\n");
		}
		else
		{
			imp_dbh->autocommit = on;
			if (imp_dbh->is_modeansi == False && imp_dbh->autocommit == False)
				return dbd_db_begin(imp_dbh);
		}
	}
	else if (KEY_MATCH(kl, key, "BlobLocation"))
	{
		imp_dbh->blob_bind = blob_bindtype(valuesv);
	}
	else if (KEY_MATCH(kl, key, "AutoErrorReport"))
	{
		imp_dbh->autoreport = on;
	}
	else
	{
		return FALSE;
	}

	return TRUE;
}

SV *dbd_db_FETCH(imp_dbh_t *imp_dbh, SV *keysv)
{
	STRLEN          kl;
	char           *key = SvPV(keysv, kl);
	SV             *retsv = Nullsv;
	int i;

	dbd_ix_debug(1, "%s::dbd_db_FETCH()\n", module);

	if (KEY_MATCH(kl, key, "InformixOnLine"))
	{
		retsv = newSViv((IV)imp_dbh->is_onlinedb);
	}
	else if (KEY_MATCH(kl, key, "LoggedDatabase"))
	{
		retsv = newSViv((IV)imp_dbh->is_loggeddb);
	}
	else if (KEY_MATCH(kl, key, "InTransaction"))
	{
		retsv = newSViv((IV)imp_dbh->is_txactive);
	}
	else if (KEY_MATCH(kl, key, "ModeAnsiDatabase"))
	{
		retsv = newSViv((IV)imp_dbh->is_modeansi);
	}
	else if (KEY_MATCH(kl, key, "BlobLocation"))
	{
		retsv = newSVpv(blob_bindname(imp_dbh->blob_bind), 0);
	}
	else if (KEY_MATCH(kl, key, "AutoCommit"))
	{
		retsv = newSViv((IV)imp_dbh->autocommit);
	}
	else if (KEY_MATCH(kl, key, "AutoErrorReport"))
	{
		retsv = newSViv((IV)imp_dbh->autoreport);
	}
	else if (KEY_MATCH(kl, key, "sqlcode"))
	{
		retsv = newSViv((IV)imp_dbh->sqlca.sqlcode);
	}
	else if (KEY_MATCH(kl, key, "sqlerrm"))
	{
		retsv = newSVpv(imp_dbh->sqlca.sqlerrm, 0);
	}
	else if (KEY_MATCH(kl, key, "sqlerrp"))
	{
		retsv = newSVpv(imp_dbh->sqlca.sqlerrp, 0);
	}
	else if (KEY_MATCH(kl, key, "ConnectionName"))
	{
		retsv = newSVpv(imp_dbh->nm_connection, 0);
	}
	else if (KEY_MATCH(kl, key, "sqlerrd"))
	{
		AV             *av = newAV();
		retsv = newRV((SV *)av);
		av_extend(av, (I32)6);
		for (i = 0; i < 6; i++)
		{
			av_store(av, i, newSViv((IV)imp_dbh->sqlca.sqlerrd[i]));
		}
	}
	else if (KEY_MATCH(kl, key, "sqlwarn"))
	{
		AV             *av = newAV();
		char            warning[2];
		char           *sqlwarn = &imp_dbh->sqlca.sqlwarn.sqlwarn0;
		retsv = newRV((SV *)av);
		av_extend(av, (I32)8);
		warning[1] = '\0';
		for (i = 0; i < 8; i++)
		{
			warning[0] = *sqlwarn++;
			av_store(av, i, newSVpv(warning, 0));
		}
	}
	else
		return FALSE;

	(void)SvREFCNT_inc(retsv);	/* so sv_2mortal won't free it  */
	return sv_2mortal(retsv);
}

/* ================================================================== */
/* =================== Statement Level Operations =================== */
/* ================================================================== */

/* Initialize a statement structure, allocating names */
static void     new_statement(imp_sth)
imp_sth_t      *imp_sth;
{
	D_imp_dbh_from_sth;
	static long     cursor_num = 0;

	sprintf(imp_sth->nm_stmnt, "p_%09ld", cursor_num);
	sprintf(imp_sth->nm_cursor, "c_%09ld", cursor_num);
	sprintf(imp_sth->nm_obind, "d_%09ld", cursor_num);
	sprintf(imp_sth->nm_ibind, "b_%09ld", cursor_num);
	imp_sth->dbh = imp_dbh;
	imp_sth->st_state = Unused;
	imp_sth->st_type = 0;
	imp_sth->n_blobs = 0;
	imp_sth->n_bound = 0;
	imp_sth->n_columns = 0;
	add_link(&imp_dbh->head, &imp_sth->chain);
	imp_sth->chain.data = (void *)imp_sth;
	cursor_num++;
}

/* Close cursor */
static int
dbd_ix_close(imp_sth_t *imp_sth)
{
	EXEC SQL BEGIN DECLARE SECTION;
	char           *nm_cursor = imp_sth->nm_cursor;
	EXEC SQL END DECLARE SECTION;

	if (imp_sth->st_state == Opened || imp_sth->st_state == Finished)
	{
		EXEC SQL CLOSE :nm_cursor;
		dbd_ix_sqlcode(imp_sth->dbh);
		if (sqlca.sqlcode < 0)
		{
			return 0;
		}
		imp_sth->st_state = Declared;
	}
	else
		warn("%s:st::dbd_ix_close: CLOSE called in wrong state\n", module);
	return 1;
}

static void noop(void *data)
{
}

/* Release all database and allocated resources for statement */
static void del_statement(imp_sth_t *imp_sth)
{
	EXEC SQL BEGIN DECLARE SECTION;
	char           *name;
	int colno;
	int coltype;
	loc_t	blob;
	EXEC SQL END DECLARE SECTION;

	if (dbd_ix_setconnection(imp_sth->dbh) == 0)
		return;

	switch (imp_sth->st_state)
	{
	case Finished:
		/*FALLTHROUGH*/
	case Opened:
		name = imp_sth->nm_cursor;
		EXEC SQL CLOSE :name;
		/*FALLTHROUGH*/
	case Declared:
		name = imp_sth->nm_cursor;
		EXEC SQL FREE :name;
		/*FALLTHROUGH*/
	case Described:
	case Allocated:
		name = imp_sth->nm_obind;

		/* ESQL/C does not deallocate blob space automatically */
		/* Verified for ESQL/C 7.21.UC1 on Solaris 2.4 with Purify */
		if (imp_sth->n_blobs > 0)
		{
			for (colno = 1; colno <= imp_sth->n_columns; colno++)
			{
				EXEC SQL GET DESCRIPTOR :name VALUE :colno :coltype = TYPE;
				/* dbd_ix_sqlcode(imp_sth->dbh); */
				if (coltype == SQLBYTES || coltype == SQLTEXT)
				{
					EXEC SQL GET DESCRIPTOR :name VALUE :colno :blob = DATA;
					/* dbd_ix_sqlcode(imp_sth->dbh); */
					if (blob.loc_loctype == LOCMEMORY && blob.loc_buffer != 0)
						free(blob.loc_buffer);
				}
			}
		}
		EXEC SQL DEALLOCATE DESCRIPTOR :name;
		/*FALLTHROUGH*/
	case Prepared:
		name = imp_sth->nm_stmnt;
		EXEC SQL FREE :name;
		/*FALLTHROUGH*/
	case Unused:
		break;
	}
	imp_sth->st_state = Unused;
	delete_link(&imp_sth->chain, noop);
	DBIc_IMPSET_off(imp_sth);
}

/* Create the input descriptor for the specified number of items */
int dbd_ix_setbindnum(imp_sth_t *imp_sth, int items)
{
	EXEC SQL BEGIN DECLARE SECTION;
	long  bind_size = items;
	char           *nm_ibind = imp_sth->nm_ibind;
	EXEC SQL END DECLARE SECTION;

	dbd_ix_debug(1, "%s::dbd_ix_setbindnum entered\n", module);

	if (dbd_ix_setconnection(imp_sth->dbh) == 0)
		return 0;

	if (items > imp_sth->n_bound)
	{
		if (imp_sth->n_bound > 0)
		{
			EXEC SQL DEALLOCATE DESCRIPTOR :nm_ibind;
			dbd_ix_sqlcode(imp_sth->dbh);
			imp_sth->n_bound = 0;
			if (sqlca.sqlcode < 0)
			{
				return 0;
			}
		}
		EXEC SQL ALLOCATE DESCRIPTOR :nm_ibind WITH MAX :bind_size;
		dbd_ix_sqlcode(imp_sth->dbh);
		if (sqlca.sqlcode < 0)
		{
			return 0;
		}
		imp_sth->n_bound = items;
	}
	return 1;
}

/* Bind the value to input descriptor entry */
int dbd_ix_bindsv(imp_sth_t *imp_sth, int idx, SV *val)
{
	int rc = 1;
	STRLEN len;
	EXEC SQL BEGIN DECLARE SECTION;
	char           *nm_ibind = imp_sth->nm_ibind;
	char *string;
	long  integer;
	float numeric;
	int		type;
	int     length;
	int index = idx;
	loc_t blob;
	EXEC SQL END DECLARE SECTION;
#if ESQLC_VERSION == 500 || ESQLC_VERSION == 501
	/**
	** The hostvar struct uses 'short' for the size, so we can't get
	** maximum size character columns.  This isn't a major problem.
	** Note that the independent DECLARE SECTIONs are necessary.
	*/
	EXEC SQL BEGIN DECLARE SECTION;
	char longchar[32767];
	char shortchar[256];
	EXEC SQL END DECLARE SECTION;
#endif /* ESQLC_VERSION in {500, 501} */

	dbd_ix_debug(1, "%s::dbd_ix_bindsv entered\n", module);

	if ((rc = dbd_ix_setconnection(imp_sth->dbh)) == 0)
		return(rc);

	EXEC SQL GET DESCRIPTOR :nm_ibind VALUE :index :type = TYPE;
	if (type == SQLBYTES || type == SQLTEXT)
	{
		/* One day, this will accept SQ_UPDATE and SQ_UPDALL */
		/* There are no plans to support SQ_UPDCURR */
		blob_locate(&blob, BLOB_IN_MEMORY);
		blob.loc_buffer = SvPV(val, len);
		blob.loc_bufsize = len + 1;
		blob.loc_size = len;
		EXEC SQL SET DESCRIPTOR :nm_ibind VALUE :index DATA = :blob;
	}
	else if (!SvOK(val))
	{
		/* It's a null! */
		type = SQLCHAR;
		EXEC SQL SET DESCRIPTOR :nm_ibind VALUE :index
						TYPE = :type, DATA = "", LENGTH = 1, INDICATOR = -1;
	}
	else if (SvIOK(val))
	{
		type = SQLINT;
		integer = SvIV(val);
		EXEC SQL SET DESCRIPTOR :nm_ibind VALUE :index
						TYPE = :type, DATA = :integer;
	}
	else if (SvNOK(val))
	{
		type = SQLFLOAT;
		numeric = SvNV(val);
		EXEC SQL SET DESCRIPTOR :nm_ibind VALUE :index
						TYPE = :type, DATA = :numeric;
	}
	else
	{
		type = SQLCHAR;
		string = SvPV(val, len);
		length = len + 1;
#if ESQLC_VERSION == 500 || ESQLC_VERSION == 501
		if (length < 256)
		{
			strncpy(shortchar, string, length);
			shortchar[length] = '\0';
			EXEC SQL SET DESCRIPTOR :nm_ibind VALUE :index
						TYPE = :type, LENGTH = :length, DATA = :shortchar;
		}
		else
		{
			if (length >= sizeof(longchar))
				length = sizeof(longchar) - 1;
			strncpy(longchar, string, length);
			longchar[length] = '\0';
			EXEC SQL SET DESCRIPTOR :nm_ibind VALUE :index
						TYPE = :type, LENGTH = :length, DATA = :longchar;
		}
#else
		EXEC SQL SET DESCRIPTOR :nm_ibind VALUE :index
						TYPE = :type, LENGTH = :length, DATA = :string;
#endif /* ESQLC_VERSION in {500, 501} */
	}
	dbd_ix_sqlcode(imp_sth->dbh);
	if (sqlca.sqlcode < 0)
	{
		rc = 0;
	}
	return(rc);
}

static int count_blobs(char *descname, int ncols)
{
	EXEC SQL BEGIN DECLARE SECTION;
	char           *nm_obind = descname;
	int	colno;
	int coltype;
	EXEC SQL END DECLARE SECTION;
	int nblobs = 0;

	for (colno = 1; colno <= ncols; colno++)
	{
		EXEC SQL GET DESCRIPTOR :nm_obind VALUE :colno :coltype = TYPE;
		/* dbd_ix_sqlcode(imp_sth->dbh); */
		if (coltype == SQLBYTES || coltype == SQLTEXT)
		{
			nblobs++;
		}
	}
	return(nblobs);
}

/* Process blobs (if any) */
static void
dbd_ix_blobs(imp_sth_t *imp_sth)
{
	EXEC SQL BEGIN DECLARE SECTION;
	char           *nm_obind = imp_sth->nm_obind;
	loc_t		   blob;
	int 			colno;
	int coltype;
	EXEC SQL END DECLARE SECTION;
	int             n_columns = imp_sth->n_columns;

	dbd_ix_debug(1, "%s::dbd_ix_blobs\n", module);
	imp_sth->n_blobs = count_blobs(nm_obind, n_columns);
	if (imp_sth->n_blobs == 0)
		return;

	/*warn("dbd_ix_blobs: %d blobs\n", imp_sth->n_blobs);*/

	/* Set blob location */
	if (blob_locate(&blob, imp_sth->blob_bind) != 0)
	{
		croak("memory allocation error 3 in dbd_ix_blobs\n");
	}

	for (colno = 1; colno <= n_columns; colno++)
	{
		EXEC SQL GET DESCRIPTOR :nm_obind VALUE :colno :coltype = TYPE;
		dbd_ix_sqlcode(imp_sth->dbh);
		if (coltype == SQLBYTES || coltype == SQLTEXT)
		{
			/* Tell ESQL/C how to handle this blob */
			EXEC SQL SET DESCRIPTOR :nm_obind VALUE :colno DATA = :blob;
			dbd_ix_sqlcode(imp_sth->dbh);
		}
	}
}

/* Declare cursor for SELECT or EXECUTE PROCEDURE */
static int
dbd_ix_declare(imp_sth_t *imp_sth)
{
	EXEC SQL BEGIN DECLARE SECTION;
	char           *nm_stmnt = imp_sth->nm_stmnt;
	char           *nm_cursor = imp_sth->nm_cursor;
	EXEC SQL END DECLARE SECTION;

#ifdef SQ_EXECPROC
	assert(imp_sth->st_type == SQ_SELECT || imp_sth->st_type == SQ_EXECPROC);
#else
	assert(imp_sth->st_type == SQ_SELECT);
#endif /* SQ_EXECPROC */
	assert(imp_sth->st_state == Described);
	dbd_ix_blobs(imp_sth);

	if (imp_sth->dbh->is_modeansi == True && imp_sth->dbh->autocommit == True)
	{
		EXEC SQL DECLARE :nm_cursor CURSOR WITH HOLD FOR :nm_stmnt;
	}
	else
	{
		EXEC SQL DECLARE :nm_cursor CURSOR FOR :nm_stmnt;
	}
	dbd_ix_sqlcode(imp_sth->dbh);
	if (sqlca.sqlcode < 0)
	{
		return 0;
	}
	imp_sth->st_state = Declared;
	return 1;
}

int
dbd_st_prepare(imp_sth_t *imp_sth, char *stmt, SV *attribs)
{
	int  rc = 1;
	EXEC SQL BEGIN DECLARE SECTION;
	char           *statement = stmt;
	int             desc_count;
	char           *nm_stmnt;
	char           *nm_obind;
	char           *nm_cursor;
	EXEC SQL END DECLARE SECTION;

	dbd_ix_debug(1, "%s::dbd_st_prepare()\n", module);
	new_statement(imp_sth);

	if ((rc = dbd_ix_setconnection(imp_sth->dbh)) == 0)
		return(rc);

	nm_stmnt = imp_sth->nm_stmnt;
	nm_obind = imp_sth->nm_obind;
	nm_cursor = imp_sth->nm_cursor;

	EXEC SQL PREPARE :nm_stmnt FROM :statement;
	dbd_ix_sqlcode(imp_sth->dbh);
	if (sqlca.sqlcode < 0)
	{
		return 0;
	}
	imp_sth->st_state = Prepared;

	EXEC SQL ALLOCATE DESCRIPTOR :nm_obind WITH MAX 128;
	dbd_ix_sqlcode(imp_sth->dbh);
	if (sqlca.sqlcode < 0)
	{
		del_statement(imp_sth);
		return 0;
	}
	imp_sth->st_state = Allocated;

	EXEC SQL DESCRIBE :nm_stmnt USING SQL DESCRIPTOR :nm_obind;
	dbd_ix_sqlcode(imp_sth->dbh);
	if (sqlca.sqlcode < 0)
	{
		del_statement(imp_sth);
		return 0;
	}
	imp_sth->st_state = Described;
	imp_sth->st_type = sqlca.sqlcode;
	if (imp_sth->st_type == 0)
		imp_sth->st_type = SQ_SELECT;

	EXEC SQL GET DESCRIPTOR :nm_obind :desc_count = COUNT;
	dbd_ix_sqlcode(imp_sth->dbh);
	if (sqlca.sqlcode < 0)
	{
		del_statement(imp_sth);
		return 0;
	}

	/* Record the number of fields in the cursor for DBI and DBD::Informix  */
	DBIc_NUM_FIELDS(imp_sth) = imp_sth->n_columns = desc_count;

	/**
	** Only non-cursory statements need an output descriptor.
	** Only cursory statements need a cursor declared for them.
	** INSERT may need an input descriptor (which will appear to be the
	** output descriptor, such being the wonders of Informix).
	*/
	if (imp_sth->st_type == SQ_SELECT)
		rc = dbd_ix_declare(imp_sth);
#ifdef SQ_EXECPROC
	else if (imp_sth->st_type == SQ_EXECPROC && desc_count > 0)
		rc = dbd_ix_declare(imp_sth);
#endif	/* SQ_EXECPROC */
	else if (imp_sth->st_type == SQ_INSERT && desc_count > 0)
	{
		dbd_ix_blobs(imp_sth);
		if (imp_sth->n_blobs > 0)
		{
			/*
			** Switch the nm_obind and nm_ibind names so that when
			** dbd_ix_bindsv() is at work, it has an already populated
			** SQL descriptor to work with, that already has the blobs
			** set up correctly.
			*/
			Name tmpname;
			strcpy(tmpname, imp_sth->nm_ibind);
			strcpy(imp_sth->nm_ibind, imp_sth->nm_obind);
			strcpy(imp_sth->nm_obind, tmpname);
			imp_sth->n_bound = desc_count;
		}
		rc = 1;
	}
	else
	{
		EXEC SQL DEALLOCATE DESCRIPTOR :nm_obind;
		imp_sth->st_state = Prepared;
		rc = 1;
	}

	/* Get number of fields and space needed for field names      */
	if (DBIS->debug >= 2)
		printf("%s::dbd_st_prepare'imp_sth->n_columns: %d\n", module,
		    imp_sth->n_columns);

	if (rc != 0)
		DBIc_IMPSET_on(imp_sth);
	return rc;
}

int
dbd_st_finish(imp_sth_t *imp_sth)
{
	int rc;

	dbd_ix_debug(1, "%s::dbd_st_finish()\n", module);

	if ((rc = dbd_ix_setconnection(imp_sth->dbh)) == 0)
		return(rc);

	rc = dbd_ix_close(imp_sth);
	DBIc_ACTIVE_off(imp_sth);
	return rc;
}

/* Free up resources used by the cursor or statement */
void
dbd_st_destroy(imp_sth_t *imp_sth)
{
	dbd_ix_debug(1, "%s::dbd_st_destroy()\n", module);
	del_statement(imp_sth);
}

/* Store statement attributes */
int
dbd_st_STORE(sth, keysv, valuesv)
SV             *sth;
SV             *keysv;
SV             *valuesv;
{
	D_imp_sth(sth);
	STRLEN          kl;
	char           *key = SvPV(keysv, kl);
	dbd_ix_debug(1, "%s::dbd_st_STORE()\n", module);

	if (KEY_MATCH(kl, key, "BlobLocation"))
	{
		imp_sth->blob_bind = blob_bindtype(valuesv);
	}
	else
		return FALSE;

	/* cache value for later DBI 'quick' fetch? */
	hv_store((HV *)SvRV(sth), key, kl, &sv_yes, 0);

	return TRUE;
}

SV             *
dbd_st_FETCH(sth, keysv)
SV             *sth;
SV             *keysv;
{
	D_imp_sth(sth);
	STRLEN          kl;
	char           *key = SvPV(keysv, kl);
	SV             *retsv = NULL;
	EXEC SQL BEGIN DECLARE SECTION;
	char           *nm_obind = imp_sth->nm_obind;
	long			coltype;
	long			collength;
	long			colnull;
	char			colname[NAMESIZE];
	int             i;
	EXEC SQL END DECLARE SECTION;

	dbd_ix_debug(1, "%s::dbd_st_FETCH()\n", module);

	if (KEY_MATCH(kl, key, "NAME"))
	{
		AV             *av = newAV();
		retsv = newRV((SV *)av);
		for (i = 1; i <= imp_sth->n_columns; i++)
		{
			EXEC SQL GET DESCRIPTOR :nm_obind VALUE :i
				:colname = NAME;
			av_store(av, i - 1, newSVpv(colname, 0));
		}
	}
	else if (KEY_MATCH(kl, key, "NULLABLE"))
	{
		AV             *av = newAV();
		retsv = newRV((SV *)av);
		for (i = 1; i <= imp_sth->n_columns; i++)
		{
			EXEC SQL GET DESCRIPTOR :nm_obind VALUE :i
				:colnull = NULLABLE;
			av_store(av, i - 1, newSViv((IV)colnull));
		}
	}
	else if (KEY_MATCH(kl, key, "TYPE"))
	{
		AV             *av = newAV();
		char buffer[SQLTYPENAME_BUFSIZ];
		SV		*sv;
		retsv = newRV((SV *)av);
		for (i = 1; i <= imp_sth->n_columns; i++)
		{
			EXEC SQL GET DESCRIPTOR :nm_obind VALUE :i
				:coltype = TYPE, :collength = LENGTH;
			sv = newSVpv(sqltypename(coltype, collength, buffer), 0);
			av_store(av, i - 1, sv);
		}
	}
	else if (KEY_MATCH(kl, key, "PRECISION"))
	{
		AV             *av = newAV();
		retsv = newRV((SV *)av);
		for (i = 1; i <= imp_sth->n_columns; i++)
		{
			EXEC SQL GET DESCRIPTOR :nm_obind VALUE :i
				:collength = LENGTH;
			av_store(av, i - 1, newSViv((IV)collength));
		}
	}
	else if (KEY_MATCH(kl, key, "SCALE"))
	{
		AV             *av = newAV();
		retsv = newRV((SV *)av);
		for (i = 1; i <= imp_sth->n_columns; i++)
		{
			EXEC SQL GET DESCRIPTOR :nm_obind VALUE :i
				:collength = LENGTH;
			av_store(av, i - 1, newSViv((IV)collength));
		}
	}
	else if (KEY_MATCH(kl, key, "NUM_OF_PARAMS"))
	{
		retsv = newSViv((IV)imp_sth->n_bound);
	}
	else if (KEY_MATCH(kl, key, "NUM_OF_FIELDS"))
	{
		retsv = newSViv((IV)imp_sth->n_columns);
	}
	else if (KEY_MATCH(kl, key, "BlobLocation"))
	{
		/* Should return a string! */
		retsv = newSViv((IV)imp_sth->blob_bind);
	}
	else if (KEY_MATCH(kl, key, "CursorName"))
	{
		retsv = newSVpv(imp_sth->nm_cursor, 0);
	}
	else if (KEY_MATCH(kl, key, "sqlcode"))
	{
		retsv = newSViv((IV)imp_sth->dbh->sqlca.sqlcode);
	}
	else if (KEY_MATCH(kl, key, "sqlerrm"))
	{
		retsv = newSVpv(imp_sth->dbh->sqlca.sqlerrm, 0);
	}
	else if (KEY_MATCH(kl, key, "sqlerrp"))
	{
		retsv = newSVpv(imp_sth->dbh->sqlca.sqlerrp, 0);
	}
	else if (KEY_MATCH(kl, key, "sqlerrd"))
	{
		AV             *av = newAV();
		retsv = newRV((SV *)av);
		av_extend(av, (I32)6);
		for (i = 0; i < 6; i++)
		{
			av_store(av, i, newSViv((IV)imp_sth->dbh->sqlca.sqlerrd[i]));
		}
	}
	else if (KEY_MATCH(kl, key, "sqlwarn"))
	{
		AV             *av = newAV();
		char            warning[2];
		char           *sqlwarn = &imp_sth->dbh->sqlca.sqlwarn.sqlwarn0;
		retsv = newRV((SV *)av);
		av_extend(av, (I32)8);
		warning[1] = '\0';
		for (i = 0; i < 8; i++)
		{
			warning[0] = *sqlwarn++;
			av_store(av, i, newSVpv(warning, 0));
		}
	}
	else
	{
		return Nullsv;
	}

	/* cache for next time (via DBI quick_FETCH) */
	(void)hv_store((HV *)SvRV(sth), key, kl, retsv, 0);
	(void)SvREFCNT_inc(retsv);	/* so sv_2mortal won't free it  */

	dbd_ix_debug(1, "%s::dbd_st_FETCH exited\n", module);

	return sv_2mortal(retsv);
}

/* Convert DECIMAL to convenient string */
/* Patches problems with Informix conversion routines in pre-7.10 versions */
/* Don't forget that decimals are stored in a base-100 notation */
static char *decgen(dec_t *val, int plus)
{
	char *str;
	int	ndigits = val->dec_ndgts * 2;
	int nbefore = (val->dec_exp) * 2;
	int nafter = (ndigits - nbefore);

	if (nbefore > 14 || nbefore < -2)
	{
		/* Too large or too small for fixed point */
		str = decsci(val, ndigits, 0);
	}
	else
	{
		str = decfix(val, nafter, 0);
	}
	if (*str == ' ')
		str++;
	/* Chop trailing blanks */
	str[byleng(str, strlen(str))] = '\0';
	return str;
}

AV *
dbd_st_fetch(imp_sth_t *imp_sth)
{
	AV	*av;
	char *decstr;
	EXEC SQL BEGIN DECLARE SECTION;
	char           *nm_cursor = imp_sth->nm_cursor;
	char           *nm_obind = imp_sth->nm_obind;
	char            coldata[256];
	long			coltype;
	long			collength;
	long			colind;
	char			colname[NAMESIZE];
	int				index;
	char           *result;
	long            length;
	loc_t			blob;
	dec_t			decval;
	EXEC SQL END DECLARE SECTION;
#if ESQLC_VERSION == 500 || ESQLC_VERSION == 501
	EXEC SQL BEGIN DECLARE SECTION;
	/**
	** The hostvar struct uses 'short' for the size, so we can't get
	** maximum size character columns.  This isn't a major problem.
	** Note that the independent DECLARE SECTIONs are necessary.
	*/
	char            longchar[32767];
	EXEC SQL END DECLARE SECTION;
#endif /* ESQLC_VERSION in {500, 501} */

	dbd_ix_debug(1, "Enter %s::dbd_st_fetch()\n", module);

	if (dbd_ix_setconnection(imp_sth->dbh) == 0)
		return Nullav;

	EXEC SQL FETCH :nm_cursor USING SQL DESCRIPTOR :nm_obind;
	dbd_ix_sqlcode(imp_sth->dbh);
	if (sqlca.sqlcode != 0)
	{
		if (sqlca.sqlcode != SQLNOTFOUND)
		{
			dbd_ix_debug(1, "Exit %s::dbd_st_fetch() -- fetch failed\n", module);
		}
		else
		{
			imp_sth->st_state = Finished;
			dbd_ix_debug(1, "Exit %s::dbd_st_fetch() -- SQLNOTFOUND\n", module);
		}
		return Nullav;
	}

	av = DBIS->get_fbav(imp_sth);

	for (index = 1; index <= imp_sth->n_columns; index++)
	{
		SV *sv = AvARRAY(av)[index-1];
		EXEC SQL GET DESCRIPTOR :nm_obind VALUE :index
				:coltype = TYPE, :collength = LENGTH,
				:colind = INDICATOR, :colname = NAME;
		dbd_ix_sqlcode(imp_sth->dbh);

		if (colind != 0)
		{
			/* Data is null */
			result = coldata;
			length = 0;
			result[length] = '\0';
			(void)SvOK_off(sv);
			/*warn("NULL Data: %d <<%s>>\n", length, result);*/
		}
		else
		{
			switch (coltype)
			{
			case SQLINT:
			case SQLSERIAL:
			case SQLSMINT:
			case SQLDATE:
			case SQLDTIME:
			case SQLINTERVAL:
			case SQLVCHAR:
#ifdef SQLNVCHAR
			case SQLNVCHAR:
#endif /* SQLNVCHAR */
				/* These types will always fit into a 256 character string */
				/* NB: VARCHAR strings retain trailing blanks */
				EXEC SQL GET DESCRIPTOR :nm_obind VALUE :index
						:coldata = DATA;
				result = coldata;
				length = byleng(result, strlen(result));
				result[length] = '\0';
				/*warn("Normal Data: %d <<%s>>\n", length, result);*/
				break;

			case SQLFLOAT:
			case SQLSMFLOAT:
			case SQLDECIMAL:
			case SQLMONEY:
				EXEC SQL GET DESCRIPTOR :nm_obind VALUE :index
						:decval = DATA;
				strcpy(coldata, decgen(&decval, 0));
				result = coldata;
				length = strlen(result);
				/*warn("Decimal Data: %d <<%s>>\n", length, result);*/
				break;

			case SQLCHAR:
#ifdef SQLNCHAR
			case SQLNCHAR:
#endif /* SQLNCHAR */
				/**
				** NB: CHAR strings have trailing blanks (which are added
				** automatically by the database) removed by byleng() etc.
				*/
#if ESQLC_VERSION == 500 || ESQLC_VERSION == 501
				/**
				** There's a bug in 5.00 and 5.01 which means that GET
				** DESCRIPTOR does not work with 'char *' as the receiving
				** column.  This is fixed in 5.02.  This code works around
				** that bug by using character arrays instead of 'char *'
				** to receive the data.  This works because sizeof(array)
				** is not the same as sizeof(&array[0]), even though in
				** every other context, array decays to &array[0].
				*/
				if (collength < 256)
				{
					EXEC SQL GET DESCRIPTOR :nm_obind VALUE :index
							:coldata = DATA;
					result = coldata;
				}
				else
				{
					EXEC SQL GET DESCRIPTOR :nm_obind VALUE :index
							:longchar = DATA;
					result = longchar;
				}
#else
				if (collength < 256)
					result = coldata;
				else
				{
					result = malloc(collength+1);
					if (result == 0)
						die("%s::st::dbd_st_fetch: malloc failed\n", module);
				}
				EXEC SQL GET DESCRIPTOR :nm_obind VALUE :index
						:result = DATA;
#endif /* ESQLC_VERSION in {500, 501} */
				length = byleng(result, strlen(result));
				result[length] = '\0';
				/*warn("Character Data: %d <<%s>>\n", length, result);*/
				break;

			case SQLTEXT:
			case SQLBYTES:
				/*warn("fetch: processing blob\n");*/
				blob_locate(&blob, BLOB_IN_MEMORY);
				EXEC SQL GET DESCRIPTOR :nm_obind VALUE :index
						:blob = DATA;
				result = blob.loc_buffer;
				length = blob.loc_size;
				/* Warning - this data is not null-terminated! */
				/*warn("Blob Data: %d <<%*.*s>>\n", length, length, length, result);*/
				break;

			default:
				warn("%s::st::dbd_st_fetch: Unknown type code: %ld (treated as NULL)\n",
					module, coltype);
				length = 0;
				result = coldata;
				result[length] = '\0';
				break;
			}
			dbd_ix_sqlcode(imp_sth->dbh);
			if (sqlca.sqlcode < 0)
			{
				*result = '\0';
			}
			sv_setpvn(sv, result, length);
			if (result != coldata)
			{
#if ESQLC_VERSION == 500 || ESQLC_VERSION == 501
				if (result != longchar)
#endif /* ESQLC_VERSION in {500, 501} */
				if (coltype != SQLBYTES && coltype != SQLTEXT)
					free(result);
			}
		}
	}
	dbd_ix_debug(1, "Exit %s::dbd_st_fetch()\n", module);
	return(av);
}

int dbd_st_rows (SV *sth)
{
	dbd_ix_debug(0, "** NOT IMPLEMENTED ** %s::dbd_st_rows()\n", module);
	return 0;
}

int dbd_st_bind_ph (SV *sth, SV *param, SV *value, SV *attribs, int boolean, int len)
{
	dbd_ix_debug(0, "** NOT IMPLEMENTED ** %s::dbd_st_bind_ph()\n", module);
	return 0;
}

int dbd_st_blob_read (SV *sth, int field, long offset, long len, SV *destsv, int destoffset)
{
	dbd_ix_debug(0, "** NOT IMPLEMENTED ** %s::dbd_st_blob_read()\n", module);
	return 0;
}

static int dbd_ix_open(imp_sth_t *imp_sth)
{
	EXEC SQL BEGIN DECLARE SECTION;
	char           *nm_cursor = imp_sth->nm_cursor;
	char           *nm_ibind = imp_sth->nm_ibind;
	EXEC SQL END DECLARE SECTION;

	dbd_ix_debug(1, "%s::dbd_ix_open\n", module);
	if (imp_sth->st_state == Opened || imp_sth->st_state == Finished)
		dbd_ix_close(imp_sth);
	assert(imp_sth->st_state == Declared);
	if (imp_sth->n_bound > 0)
		EXEC SQL OPEN :nm_cursor USING SQL DESCRIPTOR :nm_ibind;
	else
		EXEC SQL OPEN :nm_cursor;
	dbd_ix_sqlcode(imp_sth->dbh);
	if (sqlca.sqlcode < 0)
	{
		return 0;
	}
	imp_sth->st_state = Opened;
	return 1;
}

static int dbd_ix_exec(imp_sth_t *imp_sth)
{
	EXEC SQL BEGIN DECLARE SECTION;
	char           *nm_stmnt = imp_sth->nm_stmnt;
	char           *nm_ibind = imp_sth->nm_ibind;
	EXEC SQL END DECLARE SECTION;
	imp_dbh_t *dbh = imp_sth->dbh;
	int rc = 1;

	dbd_ix_debug(1, "%s::dbd_ix_exec\n", module);
	if (imp_sth->n_bound > 0)
	{
		EXEC SQL EXECUTE :nm_stmnt USING SQL DESCRIPTOR :nm_ibind;
	}
	else
	{
		EXEC SQL EXECUTE :nm_stmnt;
	}
	dbd_ix_sqlcode(dbh);
	if (sqlca.sqlcode < 0)
	{
		return 0;
	}
	/**
	** Here we need to analyse what was done...
	** BEGIN WORK, COMMIT WORK, ROLLBACK WORK are important.
	** So are DATABASE, CLOSE DATABASE, CREATE DATABASE.
	** For SE, we could use START DATABASE or ROLLFORWARD DATABASE.
	** Note that although it is unlikely to happen with Perl, the DATABASE
	** operations other than CLOSE DATABASE can have a '?' place of the
	** database name, so the same statement could be executed several times
	** with different names, and the name is then available in nm_ibind.
	** On the other hand, if it is not in nm_ibind, it has to be extracted
	** from the statement string itself.
	*/
	switch (imp_sth->st_type)
	{
	case SQ_BEGWORK:
		dbh->is_txactive = True;
		break;
	case SQ_COMMIT:
		/* In a logged database with AutoCommit Off, do BEGIN WORK */
		if (dbh->is_modeansi == False && dbh->autocommit == False)
			rc = dbd_ix_begin(dbh);
		break;
	case SQ_ROLLBACK:
		/* In a logged database with AutoCommit Off, do BEGIN WORK */
		if (dbh->is_modeansi == False && dbh->autocommit == False)
			rc = dbd_ix_begin(dbh);
		break;
	case SQ_DATABASE:
		/* Analyse new database name and record it */
		break;
	case SQ_CREADB:
		/* Analyse new database name and record it */
		break;
	case SQ_STARTDB:
		/* Analyse new database name and record it */
		break;
	case SQ_RFORWARD:
		/* Analyse new database name and record it */
		break;
	case SQ_CLSDB:
		/* Record that no database is open */
		break;
	default:
		/* COMMIT WORK for MODE ANSI databases when AutoCommit is On */
		if (dbh->is_modeansi == True && dbh->autocommit == True)
			rc = dbd_ix_commit(dbh);
		break;
	}

	DBIc_IMPSET_on(imp_sth);	/* Qu'est que c'est? */
	return rc;
}

/*
** Execute the statement.
** - OPEN the cursor for a SELECT or cursory EXECUTE PROCEDURE.
** - EXECUTE the statement for anything else.
*/
int
dbd_st_execute(imp_sth_t *imp_sth)
{
	int rc;

	if ((rc = dbd_ix_setconnection(imp_sth->dbh)) == 0)
		return(rc);
	if (imp_sth->st_type == SQ_SELECT)
		rc = dbd_ix_open(imp_sth);
#ifdef SQ_EXECPROC
	else if (imp_sth->st_type == SQ_EXECPROC && imp_sth->n_columns > 0)
		rc = dbd_ix_open(imp_sth);
#endif /* SQ_EXECPROC */
	else
		rc = dbd_ix_exec(imp_sth);
	return(rc);
}

int dbd_ix_immediate(imp_dbh_t *imp_dbh, char *stmt)
{
	EXEC SQL BEGIN DECLARE SECTION;
	char           *statement = stmt;
	EXEC SQL END DECLARE SECTION;

	dbd_ix_debug(1, "%s::dbd_ix_immediate() called\n", module);
	if (dbd_ix_setconnection(imp_dbh) == 0)
		return(0);
	EXEC SQL EXECUTE IMMEDIATE :statement;
	dbd_ix_seterror(sqlca.sqlcode);
	if (sqlca.sqlcode < 0)
		return(0);
	if (imp_dbh->autocommit == True && imp_dbh->is_modeansi == True)
		dbd_ix_commit(imp_dbh);
	return(sqlca.sqlcode == 0);
}

/* -------------- End of dbdimp.ec -------------- */
