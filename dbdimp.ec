/*
 * @(#)$Id: dbdimp.ec version /main/133 2000-02-08 14:52:13 $
 *
 * @(#)$Product: Informix Database Driver for Perl Version 0.97005 (2000-02-10) $ -- implementation details
 *
 * Portions Copyright 1994-95 Tim Bunce
 * Portions Copyright 1995-96 Alligator Descartes
 * Portions Copyright 1994    Bill Hailes
 * Portions Copyright 1996    Terry Nightingale
 * Portions Copyright 1996-99 Jonathan Leffler
 * Portions Copyright 2000    Informix Software Inc
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 */

/*TABSTOP=4*/

#ifndef lint
static const char rcs[] = "@(#)$Id: dbdimp.ec version /main/133 2000-02-08 14:52:13 $";
#endif

#include <stdio.h>
#include <string.h>

#define MAIN_PROGRAM	/* Embed version information for JLSS headers */
#include "Informix.h"
#include "decsci.h"
#include "esqlutil.h"

/* Beware omitting the semi-colon! */
$include "esqlinfo.h";

#define L_CURLY	'{'
#define R_CURLY	'}'

/**
 ** JL 2000-01-20: ESQL/C versions 9.2x and later use 32 characters for
 ** usernames.  Earlier versions use 8 characters.  This is safe for the
 ** immediately foreseeable future, but it would be better if B69092 were
 ** fixed so this was not necessary and the #define from esqlc.h could be
 ** used instead of this $define -- DRY (Don't Repeat Yourself)!
 */
$define SQL_USERLEN1     33;

DBISTATE_DECLARE;

static SV *ix_errnum = NULL;
static SV *ix_errstr = NULL;
static SV *ix_state = NULL;

static Sqlca zero_sqlca = { 0 };
static Link zero_link = { 0, 0, 0 };

/*
** Debugging macros.  NB: functions dbd_ix_debug() and dbd_ix_debug_l()
** are used in other source files and must therefore be actual functions.
** We may fix this one day.
*/
#define dbd_ix_debug(n, fmt, arg) \
	(fflush(stdout), (DBIS->debug >= (n)) ? (void)warn(fmt, arg) : (void)0)
#define dbd_ix_debug_l(n, fmt, arg) \
	(fflush(stdout), (DBIS->debug >= (n)) ? (void)warn(fmt, arg) : (void)0)
#define dbd_ix_debug_2(n, fmt, arg1, arg2) \
	(fflush(stdout), (DBIS->debug >= (n)) ? (void)warn(fmt, arg1, arg2) : (void)0)

/*
** SQLSTATE is only supported in version 6.00 and later.
** The DBI 0.81 spec says that the value S1000 should be returned
** when the implementation does not support SQLSTATE.
*/
#if ESQLC_VERSION < 600
static const char SQLSTATE[] = "S1000";
#endif /* ESQLC_VERSION */

/* One day, these will go!  Maybe... */
static void del_statement(imp_sth_t *imp_sth);
static int      dbd_ix_begin(imp_dbh_t *dbh);

/* ================================================================= */
/* ==================== Driver Level Operations ==================== */
/* ================================================================= */

/* Official name for DBD::Informix module */
const char     *
dbd_ix_module(void)
{
	return(DBD_IX_MODULE);
}

/* Print message with string argument if debug level set high enough */
void
(dbd_ix_debug)(int n, char *fmt, const char *arg)
{
	fflush(stdout);
	if (DBIS->debug >= n)
		warn(fmt, arg);
}

/* Print message with long argument if debug level set high enough */
void
(dbd_ix_debug_l)(int n, char *fmt, long arg)
{
	fflush(stdout);
	if (DBIS->debug >= n)
		warn(fmt, arg);
}

#ifdef DBD_IX_DEBUG_ENVIRONMENT
static void
dbd_ix_printenv(const char *s1, const char *s2)
{
	extern char **environ;
	char **envp = environ;
	char *env;

	fprintf(stderr, "ENV: %s %s - environ = 0x%08X\n", s1, s2, environ);
	while ((env = *envp++) != 0)
		fprintf(stderr, "0x%08X: %s\n", env, env);
}

#endif /* DBD_IX_DEBUG_ENVIRONMENT */

/* Print message on entry to function */
void
dbd_ix_enter(const char *function)
{
	dbd_ix_debug(1, "-->> %s()\n", function);
}

/* Print message on exit from function */
void
dbd_ix_exit(const char *function)
{
	dbd_ix_debug(1, "<<-- %s()\n", function);
}

/* Do some semi-standard initialization */
void
dbd_ix_dr_init(dbistate_t     *dbistate)
{
	DBISTATE_INIT;
	ix_errnum = GvSV(gv_fetchpv("DBD::Informix::err", 1, SVt_IV));
	ix_errstr = GvSV(gv_fetchpv("DBD::Informix::errstr", 1, SVt_PV));
	ix_state  = GvSV(gv_fetchpv("DBD::Informix::state", 1, SVt_PV));
}

/* Formally initialize the DBD::Informix driver structure */
int
dbd_ix_dr_driver(SV *drh)
{
	D_imp_drh(drh);

	imp_drh->n_connections = 0;			/* No active connections */
	imp_drh->current_connection = 0;	/* No name */
#if ESQLC_VERSION >= 600
	imp_drh->multipleconnections = True;		/* Multiple connections allowed */
#else
	imp_drh->multipleconnections = False;	/* Multiple connections forbidden */
#endif /* ESQLC_VERSION */
	dbd_ix_link_newhead(&imp_drh->head);	/* Linked list of connections */

	return 1;
}

/* Relay function for use by dbd_ix_link_delchain() */
/* Destroys a statement when a database connection is destroyed */
static void
dbd_st_destroyer(void *data)
{
	static const char function[] = DBD_IX_MODULE "::dbd_st_destroyer";
	dbd_ix_enter(function);
	del_statement((imp_sth_t *)data);
	dbd_ix_exit(function);
}

/* Delete all the statements (and other data) associated with a connection */
static void
del_connection(imp_dbh_t *imp_dbh)
{
	static const char function[] = DBD_IX_MODULE "::dbd_st_destroyer";
	dbd_ix_enter(function);
	dbd_ix_link_delchain(&imp_dbh->head, dbd_st_destroyer);
	dbd_ix_exit(function);
}

/* Relay (interface) function for use by dbd_ix_link_delchain() */
/* Destroys a database connection when a driver is destroyed */
static void
dbd_db_destroyer(void *data)
{
	static const char function[] = DBD_IX_MODULE "::dbd_db_destroyer";
	dbd_ix_enter(function);
	del_connection((imp_dbh_t *)data);
	dbd_ix_exit(function);
}

/* Disconnect all connections (cleanly) */
int
dbd_ix_dr_discon_all(SV *drh, imp_drh_t *imp_drh)
{
	static const char function[] = DBD_IX_MODULE "::dbd_ix_dr_discon_all";
	dTHR;

	dbd_ix_enter(function);
	dbd_ix_link_delchain(&imp_drh->head, dbd_db_destroyer);
	dbd_ix_exit(function);
	return(1);
}

/* Format a Informix error message (both SQL and ISAM parts) */
void
dbd_ix_seterror(ErrNum rc)
{
	char            errbuf[256];
	char            fmtbuf[256];
	char            sql_buf[256];
	char            isambuf[256];
	char            msgbuf[sizeof(sql_buf) + sizeof(isambuf)];

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
		/* Chop the trailing newline so Perl appends line number info. */
		/* Problem reported by Andrew Pimlott <pimlott@abel.math.harvard.edu> */
		assert(msgbuf[strlen(msgbuf)-1] == '\n');
		msgbuf[strlen(msgbuf)-1] = '\0';

		/* Record error number, error message, and error state */
		sv_setiv(ix_errnum, (IV)rc);
		sv_setpv(ix_errstr, msgbuf);
		sv_setpv(ix_state, SQLSTATE);
		dbd_ix_debug(1, "***ERROR***\n%s\n", msgbuf);
	}
}

/* Save the current sqlca record */
static void
dbd_ix_savesqlca(imp_dbh_t *imp_dbh)
{
	imp_dbh->ix_sqlca = sqlca;
}

/* Record (and report) and SQL error, saving SQLCA information */
static void
dbd_ix_sqlcode(imp_dbh_t *imp_dbh)
{
	/* If there is an error, record it */
	if (sqlca.sqlcode < 0)
	{
		dbd_ix_savesqlca(imp_dbh);
		dbd_ix_seterror(sqlca.sqlcode);
	}
}

/* ================================================================= */
/* =================== Database Level Operations =================== */
/* ================================================================= */

/* Initialize a connection structure, allocating names */
static void
new_connection(imp_dbh_t *imp_dbh)
{
	static long     connection_num = 0;
	sprintf(imp_dbh->nm_connection, "x_%09ld", connection_num);
	imp_dbh->is_onlinedb  = False;
	imp_dbh->is_loggeddb  = False;
	imp_dbh->is_modeansi  = False;
	imp_dbh->is_txactive  = False;
	imp_dbh->is_connected = False;
	imp_dbh->has_procs = False;
	imp_dbh->has_blobs = False;
	imp_dbh->srvr_vrsn = 0;
	imp_dbh->database = (SV *)0;
	imp_dbh->blob_bind = BLOB_DEFAULT;
	imp_dbh->drh = (imp_drh_t *)0;
	imp_dbh->ix_sqlca = zero_sqlca;
	imp_dbh->chain = zero_link;
	imp_dbh->head = zero_link;
	connection_num++;
}

static int dbd_ix_serverversion(void)
{
	EXEC SQL BEGIN DECLARE SECTION;
	string verstr[SQL_USERLEN1];
	EXEC SQL END DECLARE SECTION;
	int vernum = 0;
	Sqlca local = sqlca;

	EXEC SQL DECLARE c_serverversion CURSOR FOR
		SELECT Owner FROM "informix".Systables WHERE TabName = ' VERSION';
	if (sqlca.sqlcode == 0)
	{
		EXEC SQL OPEN c_serverversion;
		if (sqlca.sqlcode == 0)
		{
			EXEC SQL FETCH c_serverversion INTO $verstr;
			if (sqlca.sqlcode == 0)
			{
				/* Convert 7.30UC1 to 730, allowing for version 10.30, etc */
				char *dot = strchr(verstr, '.');
				if (dot != 0)
					memmove(dot, dot+1, strlen(verstr) - (dot - verstr) + 1);
				vernum = strtol(verstr, (char **)0, 10);
			}
			EXEC SQL CLOSE c_serverversion;
		}
		EXEC SQL FREE c_serverversion;
		/* In case we are in a MODE ANSI database */
		EXEC SQL ROLLBACK WORK;
	}
	sqlca = local;
	return vernum;
}

static void
dbd_ix_setdbtype(imp_dbh_t *imp_dbh)
{
	imp_dbh->is_onlinedb = DBD_IX_BOOLEAN(sqlca.sqlwarn.sqlwarn3 == 'W');
	imp_dbh->is_modeansi = DBD_IX_BOOLEAN(sqlca.sqlwarn.sqlwarn2 == 'W');
	imp_dbh->is_loggeddb = DBD_IX_BOOLEAN(sqlca.sqlwarn.sqlwarn1 == 'W');
	/* SE 5.00 and later has stored procedures */
	/* In general, OnLine 5.00 and later has stored procedures */
	imp_dbh->has_procs = True;
	/* SE does not have blobs. */
	/* In general, OnLine 4.00 and later has blobs */
	imp_dbh->has_blobs = imp_dbh->is_onlinedb;

	imp_dbh->srvr_vrsn = dbd_ix_serverversion();
	if (imp_dbh->srvr_vrsn >= 800 && imp_dbh->srvr_vrsn < 830)
	{
		/* XPS 8.0x, 8.1x and 8.2x do not support stored procedures or blobs */
		imp_dbh->has_procs = False;
		imp_dbh->has_blobs = False;
	}
}

int
dbd_ix_db_login(SV *dbh, imp_dbh_t *imp_dbh, char *name, char *user, char *pass)
{
	static const char function[] = DBD_IX_MODULE "::dbd_ix_db_login";
	dTHR;
	D_imp_drh_from_dbh;
	Boolean conn_ok;

	dbd_ix_enter(function);
	new_connection(imp_dbh);
	if (name != 0 && *name == '\0')
		name = 0;
	if (name != 0 && strcmp(name, DEFAULT_DATABASE) == 0)
		name = 0;

#ifdef DBD_IX_DEBUG_ENVIRONMENT
	dbd_ix_printenv("pre-connect", function);
#endif /* DBD_IX_DEBUG_ENVIRONMENT */

#if ESQLC_VERSION >= 600
	if (user != 0 && *user == '\0')
		user = 0;
	if (pass != 0 && *pass == '\0')
		pass = 0;
	/* 6.00 and later versions of Informix-ESQL/C support CONNECT */
	conn_ok = dbd_ix_connect(imp_dbh->nm_connection, name, user, pass);
#else
	/* Pre-6.00 versions of Informix-ESQL/C do not support CONNECT */
	/* Use DATABASE statement */
	conn_ok = dbd_ix_opendatabase(name);
#endif	/* ESQLC_VERSION >= 600 */

#ifdef DBD_IX_DEBUG_ENVIRONMENT
	dbd_ix_printenv("post-connect", function);
#endif /* DBD_IX_DEBUG_ENVIRONMENT */

	if (sqlca.sqlcode < 0)
	{
		/* Failure of some sort */
		dbd_ix_seterror(sqlca.sqlcode);
		dbd_ix_debug(1, "Exit %s (**ERROR-1**)\n", function);
		dbd_ix_exit(function);
		return 0;
	}

	/* Examine sqlca to see what sort of database we are hooked up to */
	dbd_ix_savesqlca(imp_dbh);
	if (name != 0)
		imp_dbh->database = newSVpv(name, 0);
	dbd_ix_setdbtype(imp_dbh);
	imp_dbh->is_connected = conn_ok;

	/* Record the driver handle */
	imp_dbh->drh = imp_drh;

	/* Record extra active connection and name of current connection */
	imp_drh->n_connections++;
	imp_drh->current_connection = imp_dbh->nm_connection;

	dbd_ix_link_add(&imp_drh->head, &imp_dbh->chain);
	imp_dbh->chain.data = (void *)imp_dbh;
	dbd_ix_link_newhead(&imp_dbh->head);

	/**
	** Unlogged databases are in AutoCommit mode at all times and cannot be
	** switched out of AutoCommit mode.  Ideally, an attempt to connect to
	** one with AutoCommit Off would cause a failure with error -256
	** 'Transaction not available'.  However, since the default attribute
	** is only set after the connection itself is complete, it is not
	** possible.  You can only give the warning.  To comply with the DBI
	** 0.85 standard, all databases, including MODE ANSI databases, run
	** with AutoCommit On by default.  However, this can be overridden by
	** the user as required.
	*/
	if (imp_dbh->is_loggeddb == False && DBI_AutoCommit(imp_dbh) == False)
	{
		/* Simulate connection failure */
		dbd_ix_db_disconnect(dbh, imp_dbh);
		sqlca.sqlcode = -256;
		dbd_ix_seterror(sqlca.sqlcode);
		dbd_ix_debug(1, "Exit %s (**ERROR-2**)\n", function);
		dbd_ix_exit(function);
		return 0;
	}

	DBIc_IMPSET_on(imp_dbh);	/* imp_dbh set up now                   */
	DBIc_ACTIVE_on(imp_dbh);	/* call disconnect before freeing       */

	/* Start a transaction if the database is Logged */
	/* but not MODE ANSI and if AutoCommit is Off */
	if (imp_dbh->is_loggeddb == True && imp_dbh->is_modeansi == False)
	{
		if (DBI_AutoCommit(imp_dbh) == False)
		{
			if (dbd_ix_begin(imp_dbh) == 0)
			{
				dbd_ix_db_disconnect(dbh, imp_dbh);
				dbd_ix_debug(1, "Exit %s (**ERROR-3**)\n", function);
				dbd_ix_exit(function);
				return 0;
			}
		}
	}

	dbd_ix_exit(function);
	return 1;
}

/* Ensure that the correct connection is current */
static int
dbd_db_setconnection(imp_dbh_t *imp_dbh)
{
	int rc = 1;
	D_imp_drh_from_dbh;

	/* If this connection isn't connected, return with failure */
	/* Primarily a concern when destroying connections */
	if (imp_dbh->is_connected == False)
		return(0);

	if (imp_drh->current_connection != imp_dbh->nm_connection)
	{
		dbd_ix_setconnection(imp_dbh->nm_connection);
		imp_drh->current_connection = imp_dbh->nm_connection;
		if (sqlca.sqlcode < 0)
			rc = 0;
	}
	return(rc);
}

/* Internal implementation of BEGIN WORK */
/* Assumes correct connection is already set */
static int
dbd_ix_begin(imp_dbh_t *dbh)
{
	int rc = 1;

	EXEC SQL BEGIN WORK;
	dbd_ix_sqlcode(dbh);
	if (sqlca.sqlcode < 0)
		rc = 0;
	else
	{
		dbd_ix_debug(3, "%s: BEGIN WORK\n", dbd_ix_module());
		dbh->is_txactive = True;
	}
	return rc;
}

/* Internal implementation of COMMIT WORK */
/* Assumes correct connection is already set */
static int
dbd_ix_commit(imp_dbh_t *dbh)
{
	int rc = 1;

	EXEC SQL COMMIT WORK;
	dbd_ix_sqlcode(dbh);
	if (sqlca.sqlcode < 0)
		rc = 0;
	else
	{
		dbd_ix_debug(3, "%s: COMMIT WORK\n", dbd_ix_module());
		dbh->is_txactive = False;
	}
	return rc;
}

/* Internal implementation of ROLLBACK WORK */
/* Assumes correct connection is already set */
static int
dbd_ix_rollback(imp_dbh_t *dbh)
{
	int rc = 1;

	EXEC SQL ROLLBACK WORK;
	dbd_ix_sqlcode(dbh);
	if (sqlca.sqlcode < 0)
		rc = 0;
	else
	{
		dbd_ix_debug(3, "%s: ROLLBACK WORK\n", dbd_ix_module());
		dbh->is_txactive = False;
	}
	return rc;
}

/* External interface for BEGIN WORK */
int
dbd_ix_db_begin(imp_dbh_t *imp_dbh)
{
	int             rc = 1;

	if (imp_dbh->is_loggeddb != 0)
	{
		if (dbd_db_setconnection(imp_dbh) == 0)
		{
			dbd_ix_savesqlca(imp_dbh);
			return(0);
		}
		rc = dbd_ix_begin(imp_dbh);
	}
	return rc;
}

/* External interface for COMMIT WORK */
int
dbd_ix_db_commit(SV *dbh, imp_dbh_t *imp_dbh)
{
	int             rc = 1;

	if (imp_dbh->is_loggeddb != 0)
	{
		if (dbd_db_setconnection(imp_dbh) == 0)
		{
			dbd_ix_savesqlca(imp_dbh);
			return(0);
		}
		if ((rc = dbd_ix_commit(imp_dbh)) != 0)
		{
			if (imp_dbh->is_modeansi == False &&
				DBI_AutoCommit(imp_dbh) == False)
				rc = dbd_ix_begin(imp_dbh);
		}
	}
	return rc;
}

/* External interface for ROLLBACK WORK */
int
dbd_ix_db_rollback(SV *dbh, imp_dbh_t *imp_dbh)
{
	int             rc = 1;

	if (imp_dbh->is_loggeddb != 0)
	{
		if (dbd_db_setconnection(imp_dbh) == 0)
		{
			dbd_ix_savesqlca(imp_dbh);
			return(0);
		}
		if ((rc = dbd_ix_rollback(imp_dbh)) != 0)
		{
			if (imp_dbh->is_modeansi == False &&
				DBI_AutoCommit(imp_dbh) == False)
				rc = dbd_ix_begin(imp_dbh);
		}
	}
	return rc;
}

/* Do nothing -- for use by cleanup code */
static void
noop(void *data)
{
}

/* Preset AutoCommit value */
int
dbd_ix_db_preset(imp_dbh_t *imp_dbh, SV *dbattr)
{
	static const char function[] = DBD_IX_MODULE "::dbd_ix_db_preset";
	static const char ac[] = "AutoCommit";
	U32 ac_len = sizeof(ac) - 1;
	I32 is_store = 0;

	dbd_ix_enter(function);
	if (SvROK(dbattr) && SvTYPE(SvRV(dbattr)) == SVt_PVHV)
	{
		/* const_cast<char *>(ac) */
		SV **svpp;
		svpp = hv_fetch((HV *)SvRV(dbattr), (char *)ac, ac_len, is_store);
		if (svpp != NULL)
		{
			dbd_ix_debug_l(1, "AutoCommit set to %ld\n", SvTRUE(*svpp));
			DBIc_set(imp_dbh, DBIcf_AutoCommit, SvTRUE(*svpp));
		}
	}
	else
	{
		printf("SvROK = %ld, SvTYPE = %ld\n", SvROK(dbattr),
			SvTYPE(SvRV(dbattr)));
	}
	dbd_ix_exit(function);
	return 1;
}

/* Close a connection, destroying any dependent statements */
int
dbd_ix_db_disconnect(SV *dbh, imp_dbh_t *imp_dbh)
{
	static const char function[] = DBD_IX_MODULE "::dbd_ix_db_disconnect";
	dTHR;
	D_imp_drh_from_dbh;
	int junk;

	dbd_ix_enter(function);

	if (dbd_db_setconnection(imp_dbh) == 0)
	{
		dbd_ix_savesqlca(imp_dbh);
		dbd_ix_debug(1, "%s -- set connection failed", function);
		dbd_ix_exit(function);
		return(0);
	}

	dbd_ix_debug(1, "%s -- delete statements\n", function);
	dbd_ix_link_delchain(&imp_dbh->head, dbd_st_destroyer);
	dbd_ix_debug(1, "%s -- statements deleted\n", function);

	/* Rollback transaction before disconnecting */
	if (imp_dbh->is_loggeddb == True && imp_dbh->is_txactive == True)
		junk = dbd_ix_rollback(imp_dbh);

#if ESQLC_VERSION >= 600
	dbd_ix_disconnect(imp_dbh->nm_connection);
#else
	if (imp_dbh->is_connected == True)
	{
		char *dbname = (imp_dbh->database) ? SvPV(imp_dbh->database, na) : "";
		dbd_ix_closedatabase(dbname);
	}
#endif	/* ESQLC_VERSION >= 600 */
	SvREFCNT_dec(imp_dbh->database);

	dbd_ix_sqlcode(imp_dbh);
	imp_dbh->is_connected = False;

	/* We assume that disconnect will always work       */
	/* since most errors imply already disconnected.    */
	DBIc_ACTIVE_off(imp_dbh);

	/* Record loss of connection in driver block */
	imp_drh->n_connections--;
	imp_drh->current_connection = 0;
	assert(imp_drh->n_connections >= 0);
	dbd_ix_link_delete(&imp_dbh->chain, noop);

	/* We don't free imp_dbh since a reference still exists	 */
	/* The DESTROY method is the only one to 'free' memory.	 */
	dbd_ix_exit(function);
	return 1;
}

void
dbd_ix_db_destroy(SV *dbh, imp_dbh_t *imp_dbh)
{
	static const char function[] = DBD_IX_MODULE "::dbd_ix_db_destroy";
	dbd_ix_enter(function);
	if (DBIc_is(imp_dbh, DBIcf_ACTIVE))
		dbd_ix_db_disconnect(dbh, imp_dbh);
	DBIc_off(imp_dbh, DBIcf_IMPSET);
	dbd_ix_exit(function);
}

/* ================================================================== */
/* =================== Statement Level Operations =================== */
/* ================================================================== */

/* Initialize a statement structure, allocating names */
static void
new_statement(imp_dbh_t *imp_dbh, imp_sth_t *imp_sth)
{
	static long     cursor_num = 0;

	sprintf(imp_sth->nm_stmnt, "p_%09ld", cursor_num);
	sprintf(imp_sth->nm_cursor, "c_%09ld", cursor_num);
	sprintf(imp_sth->nm_obind, "d_%09ld", cursor_num);
	sprintf(imp_sth->nm_ibind, "b_%09ld", cursor_num);
	imp_sth->dbh = imp_dbh;
	imp_sth->st_state = Unused;
	imp_sth->st_type = 0;
	imp_sth->st_text = 0;
	imp_sth->n_blobs = 0;
	imp_sth->n_bound = 0;
	imp_sth->n_rows = 0;
	imp_sth->n_columns = 0;
	imp_sth->is_holdcursor = False;
	imp_sth->is_scrollcursor = False;
	dbd_ix_link_add(&imp_dbh->head, &imp_sth->chain);
	imp_sth->chain.data = (void *)imp_sth;
	cursor_num++;
	/* Cleanup required for statement chain in imp_dbh */
	DBIc_on(imp_sth, DBIcf_IMPSET);
}

/* Close cursor */
static int
dbd_ix_close(imp_sth_t *imp_sth)
{
	EXEC SQL BEGIN DECLARE SECTION;
	char           *nm_cursor = imp_sth->nm_cursor;
	EXEC SQL END DECLARE SECTION;

	if (imp_sth->st_state == Opened || imp_sth->st_state == Finished ||
		imp_sth->st_state == NoMoreData)
	{
		EXEC SQL CLOSE :nm_cursor;
		dbd_ix_sqlcode(imp_sth->dbh);
		if (sqlca.sqlcode < 0)
		{
			return 0;
		}
		if (imp_sth->st_state != NoMoreData)
		imp_sth->st_state = Declared;
	}
	else
		warn("%s:st::dbd_ix_close: CLOSE called in wrong state\n", dbd_ix_module());
	return 1;
}

/* Release all database and allocated resources for statement */
static void
del_statement(imp_sth_t *imp_sth)
{
	EXEC SQL BEGIN DECLARE SECTION;
	char           *name;
	EXEC SQL END DECLARE SECTION;

	dbd_ix_debug_l(3, "-->> del_statement() 0x%08X\n", (long)imp_sth);

	if (dbd_db_setconnection(imp_sth->dbh) == 0)
	{
		dbd_ix_savesqlca(imp_sth->dbh);
		return;
	}

	switch (imp_sth->st_state)
	{
	case Finished:
		/* FALLTHROUGH */

	case NoMoreData:
		/* FALLTHROUGH */

	case Opened:
		dbd_ix_debug(3, "del_statement() %s\n", "CLOSE cursor");
		name = imp_sth->nm_cursor;
		EXEC SQL CLOSE :name;
		/* FALLTHROUGH */

	case Declared:
		dbd_ix_debug(3, "del_statement() %s\n", "FREE cursor");
		name = imp_sth->nm_cursor;
		EXEC SQL FREE :name;
		/* FALLTHROUGH */

	case Described:
	case Allocated:
		name = imp_sth->nm_obind;

		/* ESQL/C does not (always) deallocate blob space automatically */
		/* Verified unfixed for ESQL/C 6.00.UE1 on Solaris 2.4 */
		/* Verified unfixed for ESQL/C 7.21.UC1 on Solaris 2.4 with Purify */
		/* Verified unfixed for ESQL/C 7.23.UC1 on Solaris 2.4 */
		/* Verified *fixed* in 7.24.UC1 on Solaris 2.5.1 (bad frees reported) */
		/* Verified as a bad fix on Windows 95/NT by Harald Ums (no version) */
#if ESQLC_VERSION < 724
#define DBD_IX_RELEASE_BLOBS
#endif
#ifdef WIN32
#undef DBD_IX_RELEASE_BLOBS
#endif /* WIN32 */

#ifdef DBD_IX_RELEASE_BLOBS
		if (imp_sth->n_blobs > 0)
		{
			EXEC SQL BEGIN DECLARE SECTION;
			int             colno;
			int             coltype;
			loc_t           blob;
			EXEC SQL END DECLARE SECTION;

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
#endif /* DBD_IX_RELEASE_BLOBS */

		dbd_ix_debug(3, "del_statement() %s\n", "DEALLOCATE descriptor");
		EXEC SQL DEALLOCATE DESCRIPTOR :name;
		/* FALLTHROUGH */

	case Prepared:
		dbd_ix_debug(3, "del_statement() %s\n", "FREE statement");
		name = imp_sth->nm_stmnt;
		EXEC SQL FREE :name;
		/* FALLTHROUGH */

	case Unused:
		break;
	}
	if (imp_sth->st_text != 0)
		SvREFCNT_dec(imp_sth->st_text);
	imp_sth->st_state = Unused;
	dbd_ix_link_delete(&imp_sth->chain, noop);
	DBIc_off(imp_sth, DBIcf_IMPSET);
	dbd_ix_debug_l(3, "<<-- del_statement() 0x%08X\n", (long)imp_sth);
}

/* Create the input descriptor for the specified number of items */
static int
dbd_ix_setbindnum(imp_sth_t *imp_sth, int items)
{
	static const char function[] = DBD_IX_MODULE "::dbd_ix_setbindnum";
	EXEC SQL BEGIN DECLARE SECTION;
	int  bind_size = items;
	char           *nm_ibind = imp_sth->nm_ibind;
	EXEC SQL END DECLARE SECTION;

	dbd_ix_enter(function);

	if (dbd_db_setconnection(imp_sth->dbh) == 0)
	{
		dbd_ix_exit(function);
		return 0;
	}

	if (items > imp_sth->n_bound)
	{
		if (imp_sth->n_bound > 0)
		{
			EXEC SQL DEALLOCATE DESCRIPTOR :nm_ibind;
			dbd_ix_sqlcode(imp_sth->dbh);
			imp_sth->n_bound = 0;
			if (sqlca.sqlcode < 0)
			{
				dbd_ix_exit(function);
				return 0;
			}
		}
		EXEC SQL ALLOCATE DESCRIPTOR :nm_ibind WITH MAX :bind_size;
		dbd_ix_sqlcode(imp_sth->dbh);
		if (sqlca.sqlcode < 0)
		{
			dbd_ix_exit(function);
			return 0;
		}
		imp_sth->n_bound = items;
	}
	dbd_ix_exit(function);
	return 1;
}

/* Bind the value to input descriptor entry */
static int
dbd_ix_bindsv(imp_sth_t *imp_sth, int idx, SV *val)
{
	static const char function[] = DBD_IX_MODULE "::dbd_ix_bindsv";
	int rc = 1;
	STRLEN len;
	EXEC SQL BEGIN DECLARE SECTION;
	char           *nm_ibind = imp_sth->nm_ibind;
	char *string;
	long  intvar;
	double          numeric;
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

	dbd_ix_enter(function);

	if ((rc = dbd_db_setconnection(imp_sth->dbh)) == 0)
	{
		dbd_ix_savesqlca(imp_sth->dbh);
		dbd_ix_exit(function);
		return(rc);
	}

	EXEC SQL GET DESCRIPTOR :nm_ibind VALUE :index :type = TYPE;

	if (type == SQLBYTES || type == SQLTEXT)
	{
		blob_locate(&blob, BLOB_IN_MEMORY);
		if (!SvOK(val))
		{
			dbd_ix_debug(2, "%s -- null blob\n", function);
			blob.loc_indicator = -1;
			blob.loc_buffer = 0;
			blob.loc_bufsize = 0;
			blob.loc_size = 0;
		}
		else
		{
			dbd_ix_debug(2, "%s -- blob\n", function);
			/* One day, this will accept SQ_UPDATE and SQ_UPDALL */
			/* There are no plans to support SQ_UPDCURR */
			blob.loc_buffer = SvPV(val, len);
			blob.loc_bufsize = len + 1;
			blob.loc_size = len;
		}
		EXEC SQL SET DESCRIPTOR :nm_ibind VALUE :index DATA = :blob;
	}
	else if (!SvOK(val))
	{
		/* It's a null! */
		dbd_ix_debug(2, "%s -- null\n", function);
		type = SQLCHAR;
#if ESQLC_VERSION >= 600
		EXEC SQL SET DESCRIPTOR :nm_ibind VALUE :index
						TYPE = :type, LENGTH = 0, INDICATOR = -1;
#else
		/**
		** There appears to be a bug in ESQL/C 5.0x (for x in 0..6) such
		** that the SET DESCRIPTOR code core dumps when asked to process a
		** NULL.  We use a cheat, pure and simple, to get around this bug.
		** We use the internal representation for a SMALLINT NULL (-32768)
		** as the value to be inserted.  It shouldn't work (arguably
		** another bug), but since it does, we'll exploit it.  Ugh!  JL
		** 97-05-20
		*/
		{
#define SMINTNULL -32768	/* Internal representation of SMALLINT NULL */
		EXEC SQL BEGIN DECLARE SECTION;
			short           ival = SMINTNULL;
		EXEC SQL END DECLARE SECTION;
		type = SQLSMINT;
		EXEC SQL SET DESCRIPTOR :nm_ibind VALUE :index
						TYPE = :type, DATA = :ival;
		}
#endif
	}
	else if (SvIOKp(val))
	{
		dbd_ix_debug(2, "%s -- integer\n", function);
		type = SQLINT;
		intvar = SvIV(val);
		EXEC SQL SET DESCRIPTOR :nm_ibind VALUE :index
						TYPE = :type, DATA = :intvar;
	}
	else if (SvNOKp(val))
	{
		dbd_ix_debug(2, "%s -- numeric\n", function);
		type = SQLFLOAT;
		numeric = SvNV(val);
		EXEC SQL SET DESCRIPTOR :nm_ibind VALUE :index
						TYPE = :type, DATA = :numeric;
	}
	else
	{
		dbd_ix_debug(2, "%s -- string\n", function);
		type = SQLCHAR;
		string = SvPV(val, len);
		length = len + 1;
#if ESQLC_VERSION == 500 || ESQLC_VERSION == 501
		if (length < sizeof(shortchar))
		{
			strncpy(shortchar, string, length);
			shortchar[length] = '\0';
			EXEC SQL SET DESCRIPTOR :nm_ibind VALUE :index
			                TYPE = :type, LENGTH = :length,
			                DATA = :shortchar;
		}
		else
		{
			if (length >= sizeof(longchar))
				length = sizeof(longchar) - 1;
			strncpy(longchar, string, length);
			longchar[length] = '\0';
			EXEC SQL SET DESCRIPTOR :nm_ibind VALUE :index
			                TYPE = :type, LENGTH = :length,
			                DATA = :longchar;
		}
#else
		if (length == 1)
		{
			/**
			** Even if you insert "" as a literal into a VARCHAR(), you get
			** a blank returned.  If you manage to insert a zero length
			** string via a variable into a VARCHAR, then you get a NULL
			** output string.  This is arguably a bug, but oh well!
			*/
			string = " ";
			length = 2;
		}
		EXEC SQL SET DESCRIPTOR :nm_ibind VALUE :index
		                TYPE = :type, LENGTH = :length,
		                DATA = :string;
#endif /* ESQLC_VERSION in {500, 501} */
	}
	dbd_ix_sqlcode(imp_sth->dbh);
	if (sqlca.sqlcode < 0)
	{
		rc = 0;
	}
	dbd_ix_exit(function);
	return(rc);
}

static int
count_blobs(char *descname, int ncols)
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
	static const char function[] = DBD_IX_MODULE "::dbd_ix_blobs";
	EXEC SQL BEGIN DECLARE SECTION;
	char           *nm_obind = imp_sth->nm_obind;
	loc_t		   blob;
	int 			colno;
	int coltype;
	EXEC SQL END DECLARE SECTION;
	int             n_columns = imp_sth->n_columns;

	dbd_ix_enter(function);
	imp_sth->n_blobs = count_blobs(nm_obind, n_columns);
	if (imp_sth->n_blobs == 0)
	{
		dbd_ix_exit(function);
		return;
	}

	/* warn("dbd_ix_blobs: %d blobs\n", imp_sth->n_blobs); */

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
	dbd_ix_exit(function);
}

/* set the cast types for udts. returns number of udt columns */
static int
dbd_ix_udts(imp_sth_t *imp_sth)
{
	static const char function[] = DBD_IX_MODULE "::dbd_ix_udts";
	int nudts = 0;
    EXEC SQL BEGIN DECLARE SECTION;
    char *nm_obind = imp_sth->nm_obind;
    int coltype;
	int colno;
    EXEC SQL END DECLARE SECTION;

    dbd_ix_enter(function);
#if ESQLC_VERSION > 900
    for (colno = 1; colno <= imp_sth->n_columns; colno++)
	{ 
		EXEC SQL GET DESCRIPTOR :nm_obind VALUE :colno :coltype = TYPE;
        dbd_ix_sqlcode(imp_sth->dbh);
        if (ISCOMPLEXTYPE(coltype) || ISUDTTYPE(coltype) 
            || ISDISTINCTTYPE(coltype))
		{
            /**
			** MYK 2000-01-19 (ESQL/C 9.30).
			** For the reasons unknown SQLCHAR is the only one that
			** works.  Also, the manuals say LENGTH=0 sets to the actual
			** value length.  In fact it just causes FETCH to fail.
			*/
            coltype = SQLCHAR;
            EXEC SQL SET DESCRIPTOR :nm_obind VALUE :colno TYPE = :coltype, 
                LENGTH = 256;
            dbd_ix_sqlcode(imp_sth->dbh);
            nudts++;
        }
    } 
#endif /* ESQLC_VERSION > 900 */
    dbd_ix_exit(function);
    return nudts;
}

/* Declare cursor for SELECT or EXECUTE PROCEDURE */
static int
dbd_ix_declare(imp_sth_t *imp_sth)
{
	static const char function[] = DBD_IX_MODULE "::dbd_ix_declare";
	EXEC SQL BEGIN DECLARE SECTION;
	char           *nm_stmnt = imp_sth->nm_stmnt;
	char           *nm_cursor = imp_sth->nm_cursor;
	EXEC SQL END DECLARE SECTION;

	dbd_ix_enter(function);
#ifdef SQ_EXECPROC
	assert(imp_sth->st_type == SQ_SELECT || imp_sth->st_type == SQ_EXECPROC);
#else
	assert(imp_sth->st_type == SQ_SELECT);
#endif /* SQ_EXECPROC */
	assert(imp_sth->st_state == Described);
	dbd_ix_blobs(imp_sth);
    dbd_ix_udts( imp_sth );

	/* Bill R.  Hold Cursor -- Not necessarly correct... */
	if (imp_sth->dbh->is_modeansi == True &&
				DBI_AutoCommit(imp_sth->dbh) == True)
	{
		/* XPS 8.11 does not support hold cursors (Robert Wyrick <rob@wyrick.org>) */
		/* Note that the ESQL/C does support hold cursors. */
		/* The issue is whether the server does. */
		/* Assume 8.00 through 8.29 does not do so either.  8.30 may support them. */
		if (imp_sth->dbh->srvr_vrsn >= 800 && imp_sth->dbh->srvr_vrsn < 830)
			imp_sth->is_holdcursor = False;
		else
			imp_sth->is_holdcursor = True;
	}
#define print_tf(a) (a == True ? "True" : "False")
	dbd_ix_debug(3,"is_holdcursor = %s",print_tf(imp_sth->is_holdcursor));
	dbd_ix_debug(3,"is_scrollcursor = %s",print_tf(imp_sth->is_scrollcursor));
#undef print_tf

	if (imp_sth->is_scrollcursor == True)
	{
		if (imp_sth->is_holdcursor == True)
		{
			EXEC SQL DECLARE :nm_cursor SCROLL CURSOR WITH HOLD FOR :nm_stmnt;
		}
		else
		{
			EXEC SQL DECLARE :nm_cursor SCROLL CURSOR FOR :nm_stmnt;
		}
	} else /* Scroll Cursor */
	{
		if (imp_sth->is_holdcursor == True)
		{
		EXEC SQL DECLARE :nm_cursor CURSOR WITH HOLD FOR :nm_stmnt;
	}
	else
	{
		EXEC SQL DECLARE :nm_cursor CURSOR FOR :nm_stmnt;
	}
	}
	dbd_ix_sqlcode(imp_sth->dbh);
	if (sqlca.sqlcode < 0)
	{
	    dbd_ix_exit(function);
		return 0;
	}
	imp_sth->st_state = Declared;
	dbd_ix_exit(function);
	return 1;
}

/*
** dbd_ix_preparse() -- based on dbd_preparse() in DBD::ODBC 0.15
**
** Count the placeholders (?) parameters in the statement.
**
** The main-stream version also edits the string (in situ because the
** output will never be longer than the input) and recognizes both :9 (9 =
** digit string) positional parameters and :a (a = alphanumeric identifier)
** named parameters and converts them to ?.  However, this Informix version
** does not handle these non-standard extensions because the :a notation
** causes problems with Informix's FROM dbase:table notation, and the :9
** notation causes problems with DATETIME and INTERVAL literals!
**
** The code handles single-quoted literals and double-quoted delimited
** identifiers and ANSI SQL "--.*\n" comments and Informix "{.*}" comments.
** Note that it does nothing with "#.*\n" Perl/Shell comments.  Also note
** that it does not handle ODBC-style extensions.  The shorthand notation
** for these is identical to an Informix {} comment; longhand notation
** looks like "--*(details*)--" without the quotes.
*/

static int
dbd_ix_preparse(char *statement)
{
	char            end_quote = '\0';
	char           *src;
	char           *dst;
	int             idx = 0;
	int             style = 0;
	int             laststyle = 0;
	char            ch;

	dbd_ix_debug(4, "-->>dbd_ix_preparse(): <<%s>>\n", statement);
	src = statement;
	dst = statement;
	while ((ch = *src++) != '\0')
	{
		if (ch == end_quote)
			end_quote = '\0';
		else if (end_quote != '\0')
		{
			*dst++ = ch;
			continue;
		}
		else if (ch == '\'' || ch == '\"')
			end_quote = ch;
		else if (ch == L_CURLY)
			end_quote = R_CURLY;
		else if (ch == '-' && *src == '-')
		{
			end_quote = '\n';
		}
		if (ch == '?')
		{
			/* X/Open standard	 */
			*dst++ = '?';
			idx++;
			style = 3;
		}
		else
		{
			/* Perhaps ':=' PL/SQL construct or dbase:table in Informix */
			/* Or it could be :2 or :22 as part of a DATETIME/INTERVAL */
			*dst++ = ch;
			continue;
		}
		if (laststyle && style != laststyle)
			croak("Can't mix placeholder styles (%d/%d)", style, laststyle);
		laststyle = style;
	}
	if (end_quote != '\0')
	{
		switch (end_quote)
		{
		case '\'':
			warn("Incomplete single-quoted string\n");
			break;
		case '\"':
			warn("Incomplete double-quoted string (delimited identifier)\n");
			break;
		case R_CURLY:
			warn("Incomplete bracketed {...} comment\n");
			break;
		case '\n':
			warn("Incomplete double-dash comment\n");
			break;
		default:
			assert(0);
			break;
		}
	}
	*dst = '\0';
	dbd_ix_debug(4, "<<--dbd_ix_preparse(): <<%s>>\n", statement);
	return(idx);
}

static Boolean
dbd_ix_st_attrib(SV *attribs, const char *attr)
{
	Boolean rc = False;

	/* Modularized version of Bill Rothanburg <brothanb@fll-ro.dhl.com> code */
	/* To determine the setting of Hold and Scroll Cursor Attributes */
	if (attribs != NULL)
	{
		SV				**svpp;
		U32				len;

		len = strlen(attr);
		svpp = hv_fetch((HV *) SvRV(attribs), (char *)attr, len, 0);
		if (svpp != NULL)
		{
			rc = DBD_IX_BOOLEAN(SvTRUE(*svpp));
			dbd_ix_debug_2(1, "%s set to %ld\n", attr, (long)rc);
		}
	}
	return(rc);
}

/*
** Count the number of described items in the given statement.
**
** JL 2000-02-08: This is a ridiculous way to have to do things, but it
** works with ESQL/C 9.30.UC1, and there doesn't seem to be a way to
** find out how big a descriptor to allocate without trying and failing!
**
** Note that there is a chance that the free(u) will cause the Sqlda
** structure to be double-released in some early 5.0x versions of
** ESQL/C.  However, precise information about which versions are
** afflicted is not available, so we press ahead...
**
** NB: if we ever switch from SQL DESCRIPTORs to Sqlda structures, then
** this kludge becomes unnecessary, of course.  The only reason for
** retaining SQL DESCRIPTORs at the moment is the NULLABLE attribute --
** the Sqlda structure does not give this information.
*/
static int
count_descriptors(char *stmt)
{
	Sqlda	*u;
	int		 n = 256;
	EXEC SQL BEGIN DECLARE SECTION;
	char *nm_stmt = stmt;
	EXEC SQL END DECLARE SECTION;

	EXEC SQL DESCRIBE :nm_stmt INTO u;
	if (sqlca.sqlcode >= 0)
	{
		n = u->sqld;
		free(u);
	}
	dbd_ix_debug_l(1, "number of described fields %ld\n", (long)n);
	return(n);
}

int
dbd_ix_st_prepare(SV *sth, imp_sth_t *imp_sth, char *stmt, SV *attribs)
{
	static const char function[] = DBD_IX_MODULE "::dbd_ix_st_prepare";
	D_imp_dbh_from_sth;
	int  rc = 1;
	static const char ix_hc[] = "ix_CursorWithHold";
	static const char ix_sc[] = "ix_ScrollCursor";
	EXEC SQL BEGIN DECLARE SECTION;
	char           *statement = stmt;
	int             desc_count;
	char           *nm_stmnt;
	char           *nm_obind;
	char           *nm_cursor;
	EXEC SQL END DECLARE SECTION;

	dbd_ix_enter(function);

	if (stmt == 0 || *stmt == '\0')
	{
		/* No valid statement text */
		/* -402: Address of a host variable is NULL. */
		dbd_ix_seterror(-402);
		dbd_ix_savesqlca(imp_dbh);
		dbd_ix_exit(function);
		return(0);
	}

	if ((rc = dbd_db_setconnection(imp_dbh)) == 0)
	{
		dbd_ix_savesqlca(imp_dbh);
		dbd_ix_exit(function);
		return(rc);
	}

	new_statement(imp_dbh, imp_sth);
	nm_stmnt = imp_sth->nm_stmnt;
	nm_obind = imp_sth->nm_obind;
	nm_cursor = imp_sth->nm_cursor;
	imp_sth->st_text = newSVpv(stmt, 0);

	/* Bill R. Code to allow the setting of Hold and Scroll Cursor Attribs */
	if (attribs == NULL)
		dbd_ix_debug(4, "%s - no attribs set", function);
	else
	{
		imp_sth->is_holdcursor = dbd_ix_st_attrib(attribs, ix_hc);
		imp_sth->is_scrollcursor = dbd_ix_st_attrib(attribs, ix_sc);
	}

	/* Record the number of input parameters in the statement */
	DBIc_NUM_PARAMS(imp_sth) = dbd_ix_preparse(statement);

	/* Allocate space for that many parameters */
	if (dbd_ix_setbindnum(imp_sth, DBIc_NUM_PARAMS(imp_sth)) == 0)
	{
		del_statement(imp_sth);
		dbd_ix_exit(function);
		return 0;
	}

	dbd_ix_debug(4, "dbd_ix_st_prepare -- <<%s>>\n", statement);
	EXEC SQL PREPARE :nm_stmnt FROM :statement;
	dbd_ix_savesqlca(imp_dbh);
	dbd_ix_sqlcode(imp_dbh);
	if (sqlca.sqlcode < 0)
	{
		del_statement(imp_sth);
		dbd_ix_exit(function);
		return 0;
	}
	imp_sth->st_state = Prepared;

	desc_count = count_descriptors(nm_stmnt);
	/* SQL DESCRIPTORS must have WITH MAX of at least one (-470) */
	if (desc_count == 0)
		desc_count = 1;
	EXEC SQL ALLOCATE DESCRIPTOR :nm_obind WITH MAX :desc_count;
	dbd_ix_sqlcode(imp_dbh);
	if (sqlca.sqlcode < 0)
	{
		del_statement(imp_sth);
		dbd_ix_exit(function);
		return 0;
	}
	imp_sth->st_state = Allocated;

	EXEC SQL DESCRIBE :nm_stmnt USING SQL DESCRIPTOR :nm_obind;
	dbd_ix_sqlcode(imp_dbh);
	if (sqlca.sqlcode < 0)
	{
		del_statement(imp_sth);
		dbd_ix_exit(function);
		return 0;
	}
	imp_sth->st_state = Described;
	imp_sth->st_type = sqlca.sqlcode;
	if (imp_sth->st_type == 0)
		imp_sth->st_type = SQ_SELECT;

	EXEC SQL GET DESCRIPTOR :nm_obind :desc_count = COUNT;
	dbd_ix_sqlcode(imp_dbh);
	if (sqlca.sqlcode < 0)
	{
		del_statement(imp_sth);
		dbd_ix_exit(function);
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
        int nudts = dbd_ix_udts( imp_sth );

		dbd_ix_blobs(imp_sth);
		if (imp_sth->n_blobs > 0 || nudts > 0)
		{
			/**
			** Switch the nm_obind and nm_ibind names so that when
			** dbd_ix_bindsv() is at work, it has an already populated SQL
			** descriptor to work with, that already has the blobs set up
			** correctly.
			*/
			Name tmpname;
			strcpy(tmpname, imp_sth->nm_ibind);
			strcpy(imp_sth->nm_ibind, imp_sth->nm_obind);
			strcpy(imp_sth->nm_obind, tmpname);
			imp_sth->n_bound = desc_count;
		}
		rc = 1;
	}
	else if (imp_sth->st_type == SQ_UPDATE && desc_count > 0)
	{
		/**
		** 7.30 and later servers support describe for UPDATE too! 
		** However, it requires the server to be configured to do it. 
		** See Notes/updating.blobs for more information. 
		** The once-only test is not 100% reliable.  You could have
		** multiple connections to multiple database servers, and the
		** first one which supports blob update will trigger the message.
		** Subsequent updates of blobs on other servers might still fail
		** because those servers do not have the correct setup.
		*/
		static int count = 0;
		if (count == 0)
		{
			count++;
			dbd_ix_debug(2, "*** %s -- UPDATE of BLOBS is possible\n", dbd_ix_module());
		}
		dbd_ix_debug(0, "*** %s -- blob update not fully implemented!!!\n", dbd_ix_module());
#if 0
		dbd_ix_blobs(imp_sth);
		if (imp_sth->n_blobs > 0)
		{
			/**
			** Switch the nm_obind and nm_ibind names so that when
			** dbd_ix_bindsv() is at work, it has an already populated SQL
			** descriptor to work with, that already has the blobs set up
			** correctly.
			*/
			Name            tmpname;
			strcpy(tmpname, imp_sth->nm_ibind);
			strcpy(imp_sth->nm_ibind, imp_sth->nm_obind);
			strcpy(imp_sth->nm_obind, tmpname);
			imp_sth->n_bound = desc_count;
		}
#endif /* 0 */
		rc = 1;
	}

	else
	{
		EXEC SQL DEALLOCATE DESCRIPTOR :nm_obind;
		imp_sth->st_state = Prepared;
		rc = 1;
	}

	dbd_ix_debug_2(2, "%s'imp_sth->n_columns: %d\n", function, imp_sth->n_columns);

	dbd_ix_exit(function);
	return rc;
}

/* CLOSE cursor */
int
dbd_ix_st_finish(SV *sth, imp_sth_t *imp_sth)
{
	static const char function[] = DBD_IX_MODULE "::dbd_ix_st_finish";
	dTHR;
	int rc;

	dbd_ix_enter(function);

	if ((rc = dbd_db_setconnection(imp_sth->dbh)) == 0)
	{
		dbd_ix_savesqlca(imp_sth->dbh);
	}
	else
	{
		rc = dbd_ix_close(imp_sth);
		DBIc_ACTIVE_off(imp_sth);
	}

	dbd_ix_exit(function);
	return rc;
}

/* Free up resources used by the cursor or statement */
void
dbd_ix_st_destroy(SV *sth, imp_sth_t *imp_sth)
{
	static const char function[] = DBD_IX_MODULE "::dbd_ix_st_destroy";
	dbd_ix_enter(function);
	del_statement(imp_sth);
	dbd_ix_exit(function);
}

/* Convert DECIMAL to convenient string */
/* Patches problems with Informix conversion routines in pre-7.10 versions */
/* Don't forget that decimals are stored in a base-100 notation */
static char    *
decgen(dec_t * val, int plus)
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

/*
** Fetch a single row of data.
**
** Note the use of 'varchar' variables.  Given the sample code:
**
** #include <stdio.h>
** int main(int argc, char **argv)
** {
**     EXEC SQL BEGIN DECLARE SECTION;
**     char    cc[30];
**     varchar vc[30];
**     EXEC SQL END DECLARE SECTION;
**     EXEC SQL WHENEVER ERROR STOP;
**     EXEC SQL DATABASE Apt;
**     EXEC SQL CREATE TEMP TABLE Test(Col01 CHAR(20), Col02 VARCHAR(20));
**     EXEC SQL INSERT INTO Test VALUES("ABCDEFGHIJ     ", "ABCDEFGHIJ     ");
**     EXEC SQL SELECT Col01, Col01 INTO :cc, :vc FROM Test;
**     printf("Col01: cc = <<%s>>\n", cc);
**     printf("Col01: vc = <<%s>>\n", vc);
**     EXEC SQL SELECT Col02, Col02 INTO :cc, :vc FROM TestTable;
**     printf("Col02: cc = <<%s>>\n", cc);
**     printf("Col02: vc = <<%s>>\n", vc);
**     return(0);
** }
**
** The output looks like:
**		Col01: cc = <<ABCDEFGHIJ                   >>
**		Col01: vc = <<ABCDEFGHIJ          >>
**		Col02: cc = <<ABCDEFGHIJ                   >>
**		Col02: vc = <<ABCDEFGHIJ     >>
** Note that the data returned into 'cc' is blank padded to the length of
** the host variable, not the length of the database column, whereas 'vc'
** is blank-padded to the length of the database column for a CHAR column,
** and to the length of the inserted data in a VARCHAR column.
*/
AV *
dbd_ix_st_fetch(SV *sth, imp_sth_t *imp_sth)
{
	static const char function[] = DBD_IX_MODULE "::dbd_ix_st_fetch";
	AV	*av;
	EXEC SQL BEGIN DECLARE SECTION;
	char           *nm_cursor = imp_sth->nm_cursor;
	char           *nm_obind = imp_sth->nm_obind;
	varchar         coldata[256];
	long			coltype;
	long			collength;
	long			colind;
	char            colname[SQL_COLNAMELEN];
	int				index;
	char           *result;
	long            length;
	loc_t			blob;
	dec_t			decval;
$ifdef IUS_DATA_TYPES;
	long            extypeid;
#ifdef SQLLVARCHAR
	lvarchar       *lvar = 0;
#endif
$endif; -- IUS_DATA_TYPES
	EXEC SQL END DECLARE SECTION;
#if ESQLC_VERSION == 500 || ESQLC_VERSION == 501
	EXEC SQL BEGIN DECLARE SECTION;
	/**
	** The hostvar struct uses 'short' for the size, so we can't get
	** maximum size character columns.  This isn't a major problem.
	** Note that the independent DECLARE SECTIONs are necessary.
	*/
	varchar         longchar[32767];
	EXEC SQL END DECLARE SECTION;
#endif /* ESQLC_VERSION in {500, 501} */

	dbd_ix_enter(function);

	if (dbd_db_setconnection(imp_sth->dbh) == 0)
	{
		dbd_ix_savesqlca(imp_sth->dbh);
		dbd_ix_exit(function);
		return Nullav;
	}

	if (imp_sth->st_state == NoMoreData)
	{
		/* Simulate SQLNOTFOUND on a closed cursor */
		dbd_ix_debug(1, "%s: Simulate SQLNOTFOUND\n", function);
		sqlca.sqlcode = SQLNOTFOUND;
		dbd_ix_savesqlca(imp_sth->dbh);
		dbd_ix_sqlcode(imp_sth->dbh);
		dbd_ix_exit(function);
		return Nullav;
	}

	dbd_ix_blobs(imp_sth); /* Fix -451 errors; Rich Jones <rich@annexia.org> */

	EXEC SQL FETCH :nm_cursor USING SQL DESCRIPTOR :nm_obind;
	dbd_ix_savesqlca(imp_sth->dbh);
	dbd_ix_sqlcode(imp_sth->dbh);
	if (sqlca.sqlcode != 0)
	{
		if (sqlca.sqlcode != SQLNOTFOUND)
		{
			dbd_ix_debug(1, "Exit %s -- fetch failed\n", function);
		}
		else
		{
			imp_sth->st_state = NoMoreData;
			/* Implicitly CLOSE cursor on fetch failing */
			dbd_ix_close(imp_sth);
			dbd_ix_debug(1, "Exit %s -- SQLNOTFOUND\n", function);
		}
		dbd_ix_exit(function);
		return Nullav;
	}

	imp_sth->n_rows++;

	av = DBIS->get_fbav(imp_sth);

	for (index = 1; index <= imp_sth->n_columns; index++)
	{
		SV             *sv = AvARRAY(av)[index - 1];
		EXEC SQL GET DESCRIPTOR :nm_obind VALUE :index
				:coltype = TYPE, :collength = LENGTH,
				:colind = INDICATOR, :colname = NAME;
		dbd_ix_sqlcode(imp_sth->dbh);

		/* JL:2000-01-19: What was wrong with 'if (colind != 0)'? */
		if (-1 == colind)
		{
			/* Data is null */
			result = coldata;
			length = 0;
			result[length] = '\0';
			(void)SvOK_off(sv);
			/* warn("NULL Data: %d <<%s>>\n", length, result); */
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
#ifdef SQLBOOL
			case SQLBOOL:
#endif	/* SQLBOOL */
#ifdef SQLSERIAL8
			case SQLSERIAL8:
#endif /* SQLSERIAL8 */
#ifdef SQLINT8
			case SQLINT8:
#endif /* SQLINT8 */
				/* These types will always fit into a 256 character string */
				EXEC SQL GET DESCRIPTOR :nm_obind VALUE :index
						:coldata = DATA;
				result = coldata;
				length = byleng(result, strlen(result));
				result[length] = '\0';
				/* warn("Normal Data: %d <<%s>>\n", length, result); */
				break;

			case SQLFLOAT:
			case SQLSMFLOAT:
			case SQLDECIMAL:
			case SQLMONEY:
				/*
				** Default formatting (in some versions of ESQL/C)
				** assumes 2 decimal places -- wrong!
				*/
				EXEC SQL GET DESCRIPTOR: nm_obind VALUE:index
						:decval = DATA;
				strcpy(coldata, decgen(&decval, 0));
				result = coldata;
				length = strlen(result);
				/* warn("Decimal Data: %d <<%s>>\n", length, result); */
				break;

$ifdef IUS_DATA_TYPES;
#ifdef SQLUDTFIXED
			case SQLUDTFIXED:
				{
					EXEC SQL BEGIN DECLARE SECTION;
					fixed binary ifx_lo_t bclob;
					EXEC SQL END DECLARE SECTION;
					char            cb = 'C';
					int             error = 0;

					EXEC SQL GET DESCRIPTOR :nm_obind VALUE :index
										:extypeid = EXTYPEID;

					result = NULL;

					switch (extypeid)
					{
					case XID_BLOB:
						cb = 'B';
						/* FALLTHROUGH */
					case XID_CLOB:
						{
							int             LO_fd;
							ifx_lo_stat_t  *LO_stat;
							ifx_int8_t      size;

							EXEC SQL GET DESCRIPTOR :nm_obind VALUE :index
												:bclob = DATA;
							LO_fd = ifx_lo_open(&bclob, LO_RDONLY, &error);
							if (LO_fd == -1)
							{
								croak("Error opening %cLOB: %d", cb, error);
							}
							if (ifx_lo_stat(LO_fd, &LO_stat) < 0)
							{
								croak("Error getting %cLOB stat", cb);
							}
							if (ifx_lo_stat_size(LO_stat, &size) != 0)
							{
								croak("Error getting %cLOB size", cb);
							}
							if (ifx_int8tolong(&size, &length) != 0)
							{
								croak("Error converting %cbLOB size to length", cb);
							}
							if (ifx_lo_close(LO_fd) != 0)
							{
								croak("Error closing %cLOB", cb);
							}
							if (ifx_lo_to_buffer(&bclob, length, &result, &error) < 0)
							{
								croak("Error copying from %cLOB", cb);
							}
							break;
						}
					default:
						warn("IUS extended type (%d) is not yet supported", extypeid);
					}
					break;
				}
#endif

#ifdef SQLLVARCHAR
			case SQLLVARCHAR:
				if (ifx_var_flag(&lvar, 1) < 0)
				{
					warn("Cannot set automatic memory for lvarchar");
                    break;
				}
				EXEC SQL GET DESCRIPTOR :nm_obind VALUE :index
									:lvar = DATA;
				result = (char *)ifx_var_getdata(&lvar);
				if (result == 0)
				{
					warn("Null pointer for lvarchar");
				}
				if ((length = ifx_var_getlen(&lvar)) < 0)
				{
					warn("Length of lvarchar < 0");
				}
				/**
				** Empirical evidence on Solaris 2.6 with ClientSDK
				** 2.10.UC1 (ESQL/C 9.16.UC1) shows that the LVARCHAR
				** variable is supplied with 2 NULs '\0' at the end, and
				** both are counted in the length.  The test below corrects
				** for this; the assertion reassures me.  I don't know
				** whether this is really the way it should be according to
				** the specs; the manuals do not cover such fine details.
				*/
				if (length > 0)
				{
					assert(length >= 2 && result[length] == '\0' && result[length-1] == '\0');
					length -= 2;
				}
				break;
#endif	/* SQLLVARCHAR */

$endif; -- IUS_DATATYPES
               
			case SQLVCHAR:
#ifdef SQLNVCHAR
			case SQLNVCHAR:
#endif /* SQLNVCHAR */
				/* These types will always fit into a 256 character string */
				/* NB: VARCHAR strings always retain trailing blanks */
				EXEC SQL GET DESCRIPTOR :nm_obind VALUE :index
						:coldata = DATA;
				result = coldata;
				length = strlen(result);
				/* warn("VARCHAR Data: %d <<%s>>\n", length, result); */
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
										:coldata = DATA;
					result = longchar;
				}
#else
				if (collength < 256)
					result = coldata;
				else
				{
					/* Placate bloody-minded MSVC and C++ compilers */
					result = (char *)malloc(collength + 1);
					if (result == 0)
						die("%s::st::dbd_ix_st_fetch: malloc failed\n", dbd_ix_module());
				}
				EXEC SQL GET DESCRIPTOR :nm_obind VALUE :index
						:result = DATA;
#endif /* ESQLC_VERSION in {500, 501} */
				/* Conditionally chop trailing blanks */
				length = strlen(result);
				if (DBIc_is(imp_sth, DBIcf_ChopBlanks))
					length = byleng(result, length);
				result[length] = '\0';
				/* warn("Character Data: %d <<%s>>\n", length, result); */
				break;

			case SQLTEXT:
			case SQLBYTES:
				/* warn("fetch: processing blob\n"); */
				blob_locate(&blob, BLOB_IN_MEMORY);
				EXEC SQL GET DESCRIPTOR :nm_obind VALUE :index
						:blob = DATA;
				result = blob.loc_buffer;
				length = blob.loc_size;
				/* Warning - this data is not null-terminated! */
				/* warn("Blob Data: %d <<%*.*s>>\n", length, length, length,
				   result); */
				/* Data has been passed to Perl; mark it as such! */
				blob.loc_buffer = 0;
				blob_release(&blob, 0);	/* 0 => do not delete files */
				break;

			default:
				warn("%s - Unknown type code: %ld\n"
					  "(This type is probably IUS-specific and is not supported yet.)\n"
				      "coltype = %ld, collength = %ld, colind = %ld, colname = %s\n"
						"-- value treated as NULL!\n",
					  function, coltype, coltype, collength, colind, colname);
				length = 0;
				result = coldata;
				result[length] = '\0';
				break;
			}

			if (sqlca.sqlcode < 0)
			{
				dbd_ix_sqlcode(imp_sth->dbh);
				*result = '\0';
			}

			sv_setpvn(sv, result, length);
			if (result != coldata)
			{
#if ESQLC_VERSION == 500 || ESQLC_VERSION == 501
				if (result != longchar)
#endif /* ESQLC_VERSION in {500, 501} */
					switch (coltype)
					{
$ifdef IUS_DATA_TYPES;
#ifdef SQLLVARCHAR
					case SQLLVARCHAR:
						if (ifx_var_dealloc(&lvar) < 0)
						{
							warn("Having problems freeing lvarchar");
						}
						break;
#endif	/* defined... */
$endif; -- IUS_DATATYPES
					case SQLBYTES:
					case SQLTEXT:
						break;
					default:
					free(result);
						break;
					}
			}
		}
	}
	dbd_ix_exit(function);
	return(av);
}

static int
dbd_ix_open(imp_sth_t *imp_sth)
{
	static const char function[] = DBD_IX_MODULE "::dbd_ix_open";
	EXEC SQL BEGIN DECLARE SECTION;
	char           *nm_cursor = imp_sth->nm_cursor;
	char           *nm_ibind = imp_sth->nm_ibind;
	EXEC SQL END DECLARE SECTION;

	dbd_ix_enter(function);
	assert(imp_sth->st_state == Declared || imp_sth->st_state == Opened ||
			imp_sth->st_state == Finished || imp_sth->st_state == NoMoreData);
	if (imp_sth->st_state == Opened || imp_sth->st_state == Finished)
		dbd_ix_close(imp_sth);
	assert(imp_sth->st_state == Declared);
	if (imp_sth->n_bound > 0)
		EXEC SQL OPEN :nm_cursor USING SQL DESCRIPTOR :nm_ibind;
	else
		EXEC SQL OPEN :nm_cursor;
	dbd_ix_sqlcode(imp_sth->dbh);
	dbd_ix_savesqlca(imp_sth->dbh);
	if (sqlca.sqlcode < 0)
	{
		dbd_ix_exit(function);
		return 0;
	}
	imp_sth->st_state = Opened;
	if (imp_sth->dbh->is_modeansi == True)
		imp_sth->dbh->is_txactive = True;
	imp_sth->n_rows = 0;
	dbd_ix_exit(function);
	return 1;
}

/* Parse statement for name of database -- what a pain! */
static void
dbd_ix_setdbname(const char *kw1, const char *kw2, imp_sth_t *sth)
{
	static const char function[] = DBD_IX_MODULE "::dbd_ix_setdbname";
	/**
	** Scan through statement string, skipping comments ('{}' and '--\n'
	** style), seeking (case-insensitively) the text of kw1 as the first
	** word in the statement, and kw2 (if not null) as the second word in
	** the statement.  The required database name is the third word in the
	** statement.  Pain!  Oh the pain!  Why can't I have the database name
	** returned to me by Informix?  About the only mercy is that we know
	** that there is a major problem if the keywords are not found.
	** OK: we created sqltoken() to handle this!
	*/
	/* Where's the statement text? */
	char *tok = SvPV(sth->st_text, na);
	char *end = tok;

	dbd_ix_enter(function);
	tok = sqltoken(end, &end);
	/* Should be same as kw1 -- give or take case */
	if (DBIS->debug >= 6)
		warn("%s: %s = <<%*.*s>>\n", function, kw1, end - tok, end - tok, tok);
	/* What's the Perl case-insensitive string comparison routine called? */
	if (kw2 != 0)
	{
		tok = sqltoken(end, &end);
		if (DBIS->debug >= 6)
			warn("%s: %s = <<%*.*s>>\n", function, kw2, end - tok, end - tok, tok);
		/* Should be same as kw2 -- give or take case */
	}
	tok = sqltoken(end, &end);
	if (DBIS->debug >= 6)
		warn("%s: dbn = <<%*.*s>>\n", function, end - tok, end - tok, tok);
	/* Should be the database name! */
	/* Must handle this correctly! */
	if (sth->dbh->database != 0)
		SvREFCNT_dec(sth->dbh->database);
	sth->dbh->database = newSVpv(tok, end - tok);
	if (DBIS->debug >= 4)
		warn("new database name <<%s>>\n", SvPV(sth->dbh->database, na));
	dbd_ix_exit(function);
}

static int
dbd_ix_exec(imp_sth_t *imp_sth)
{
	static const char function[] = DBD_IX_MODULE "::dbd_ix_exec";
	EXEC SQL BEGIN DECLARE SECTION;
	char           *nm_stmnt = imp_sth->nm_stmnt;
	char           *nm_ibind = imp_sth->nm_ibind;
	EXEC SQL END DECLARE SECTION;
	imp_dbh_t *dbh = imp_sth->dbh;
	int rc = 1;
	Boolean exec_stmt = True;

	dbd_ix_enter(function);

	if (imp_sth->st_type == SQ_BEGWORK)
	{
		/* BEGIN WORK in a logged non-ANSI database with AutoCommit Off */
		/* will fail because we're already in a transaction. */
		/* Pretend it succeeded. */
		if (dbh->is_loggeddb == True && dbh->is_modeansi == False)
		{
			if (DBI_AutoCommit(dbh) == False)
			{
				exec_stmt = False;
				sqlca.sqlcode = 0;
			}
		}
	}

	if (exec_stmt == True)
	{
		if (imp_sth->n_bound > 0)
		{
			EXEC SQL EXECUTE :nm_stmnt USING SQL DESCRIPTOR :nm_ibind;
		}
		else
		{
			EXEC SQL EXECUTE :nm_stmnt;
		}
	}

	dbd_ix_sqlcode(dbh);
	dbd_ix_savesqlca(dbh);
	if (sqlca.sqlcode < 0)
	{
		dbd_ix_exit(function);
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
	imp_sth->n_rows = sqlca.sqlerrd[2];
	switch (imp_sth->st_type)
	{
	case SQ_BEGWORK:
		dbd_ix_debug(3, "%s: BEGIN WORK\n", dbd_ix_module());
		dbh->is_txactive = True;
		assert(dbh->is_loggeddb == True);
		/* Even BEGIN WORK has to be committed if AutoCommit is On */
		if (DBI_AutoCommit(dbh) == True)
			rc = dbd_ix_commit(dbh);
		break;
	case SQ_COMMIT:
		dbd_ix_debug(3, "%s: COMMIT WORK\n", dbd_ix_module());
		dbh->is_txactive = False;
		assert(dbh->is_loggeddb == True);
		/* In a logged database with AutoCommit Off, do BEGIN WORK */
		if (dbh->is_modeansi == False && DBI_AutoCommit(dbh) == False)
			rc = dbd_ix_begin(dbh);
		break;
	case SQ_ROLLBACK:
		dbd_ix_debug(3, "%s: ROLLBACK WORK\n", dbd_ix_module());
		dbh->is_txactive = False;
		assert(dbh->is_loggeddb == True);
		/* In a logged database with AutoCommit Off, do BEGIN WORK */
		if (dbh->is_modeansi == False && DBI_AutoCommit(dbh) == False)
			rc = dbd_ix_begin(dbh);
		break;
	case SQ_DATABASE:
		dbh->is_txactive = False;
		dbd_ix_setdbtype(dbh);
		dbd_ix_setdbname("DATABASE", 0, imp_sth);
		break;
	case SQ_CREADB:
		dbh->is_txactive = False;
		dbd_ix_setdbtype(dbh);
		dbd_ix_setdbname("CREATE", "DATABASE", imp_sth);
		break;
	case SQ_STARTDB:
		dbh->is_txactive = False;
		dbd_ix_setdbtype(dbh);
		dbd_ix_setdbname("START", "DATABASE", imp_sth);
		break;
	case SQ_RFORWARD:
		dbh->is_txactive = False;
		dbd_ix_setdbtype(dbh);
		dbd_ix_setdbname("ROLLFORWARD", "DATABASE", imp_sth);
		break;
	case SQ_CLSDB:
		/**
		** CLOSE DATABASE -- no transactions, no autocommit, etc.
		** With 6.00 upwards, the connection to the server still exists
		** With 5.00, if the database was remote, then the connection
		** is broken by close database; otherwise, it remains.  Assume
		** it still exists until further notice...
		*/
		dbh->is_txactive = False;
		dbh->is_modeansi = False;
		dbh->is_onlinedb = False;
		dbh->is_loggeddb = False;
		DBIc_set(dbh, DBIcf_AutoCommit, False);
		SvREFCNT_dec(dbh->database);
		dbh->database = 0;
		break;
	default:
		if (dbh->is_modeansi)
			dbh->is_txactive = True;
		/* COMMIT WORK for MODE ANSI databases when AutoCommit is On */
		if (dbh->is_modeansi == True && DBI_AutoCommit(dbh) == True)
			rc = dbd_ix_commit(dbh);
		break;
	}

	DBIc_on(imp_sth, DBIcf_IMPSET);	/* Qu'est que c'est? */
	dbd_ix_exit(function);
	return rc;
}

/*
** Execute the statement.
** - OPEN the cursor for a SELECT or cursory EXECUTE PROCEDURE.
** - EXECUTE the statement for anything else.
** Remember that dbd_st_execute() must return:
**      -2 or smaller   => error
**      -1              => unknown number of rows affected
**       0 or greater   => known number of rows affected
** DBD::Informix will not return -1, though there's at least half an
** argument for returning -1 after dbd_ix_open() is called.
*/
int
dbd_ix_st_execute(SV *sth, imp_sth_t *imp_sth)
{
	static const char function[] = DBD_IX_MODULE "::dbd_ix_st_execute";
	dTHR;
	int rv;
	int rc;

	dbd_ix_enter(function);
	if ((rc = dbd_db_setconnection(imp_sth->dbh)) == 0)
	{
		dbd_ix_savesqlca(imp_sth->dbh);
		assert(sqlca.sqlcode < 0);
		dbd_ix_exit(function);
		return(sqlca.sqlcode);
	}

	if (imp_sth->st_type == SQ_SELECT)
		rc = dbd_ix_open(imp_sth);
#ifdef SQ_EXECPROC
	else if (imp_sth->st_type == SQ_EXECPROC && imp_sth->n_columns > 0)
		rc = dbd_ix_open(imp_sth);
#endif /* SQ_EXECPROC */
	else
		rc = dbd_ix_exec(imp_sth);

	/* Map returned values from dbd_ix_exec and dbd_ix_open */
	if (rc == 0)
	{
		/* Statement failed -- return the error code */
		assert(sqlca.sqlcode < 0);
		rv = sqlca.sqlcode;
	}
	else
	{
		/**
		** Statement succeeded.  Don't forget about MODE ANSI database and
		** an UPDATE which does not alter any rows returning SQLNOTFOUND.
		** MODE ANSI problem found by Chuck.Collins@zool.Airtouch.com
		*/
		rv = sqlca.sqlerrd[2];
		assert((sqlca.sqlcode == 0 || sqlca.sqlcode == SQLNOTFOUND) && rv >= 0);
	}

	dbd_ix_exit(function);
	return(rv);
}

int
dbd_ix_st_rows(SV *sth, imp_sth_t *imp_sth)
{
	return(imp_sth->n_rows);
}

/* Called extensively by execute method when it is given parameters! */
int
dbd_ix_st_bind_ph(SV *sth, imp_sth_t *imp_sth, SV *param, SV *value,
	IV sql_type, SV *attribs, int is_inout, IV maxlen)
{
	static const char function[] = DBD_IX_MODULE "::st::dbd_ix_st_bind_ph";
	int rc;

	dbd_ix_enter(function);
	if (is_inout)
		croak("%s() - inout parameters not implemented\n", function);
	rc = dbd_ix_bindsv(imp_sth, SvIV(param), value);
	dbd_ix_exit(function);
	return(rc);
}

int
dbd_ix_st_blob_read(SV *sth, imp_sth_t *imp_sth, int field, long offset,
					long len, SV *destrv, long destoffset)
{
	croak("%s::st::dbd_ix_st_blob_read() - not implemented\n", dbd_ix_module());
	return -1;
}

/* -------------- End of $RCSfile: dbdimp.ec,v $ -------------- */
