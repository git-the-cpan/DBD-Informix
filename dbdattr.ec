/*
 * @(#)dbdattr.ec	54.6 97/05/14 17:24:06
 *
 * DBD::Informix for Perl Version 5 -- attribute handling
 *
 * Copyright (c) 1997 Jonathan Leffler
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 */

/*TABSTOP=4*/

#ifndef lint
static const char sccs[] = "@(#)dbdattr.ec	54.6 97/05/14";
#endif

#include <stdio.h>
#include <string.h>

#include "Informix.h"

/*
** Check whether key defined by key length (kl) and key value (kv)
** matches keyword (kw), which should be a character literal ("KeyWord")!
*/
#define KEY_MATCH(kl, kv, kw) ((kl) == (sizeof(kw) - 1) && strEQ((kv), (kw)))

static const char esql_prodname[] = ESQLC_VERSION_STRING;
static const int  esql_prodvrsn   = ESQLC_VERSION;

/* Deprecated constructs are flagged unconditionally in the 0.54 release */
/* Old-style attributes won't work in the 0.55 release. */
static Boolean deprecation = True;

/* Print message deprecating old feature and indicating new */
static void dbd_ix_deprecate(const char *old)
{
	warn("%s - deprecated attribute name %s <<DO NOT USE>>\n",
		 dbd_ix_module(), old);
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
	default:
		value = "Default";
		break;
	}
	return(value);
}

SV *dbd_dr_FETCH_attrib(imp_drh_t *imp_drh, SV *keysv)
{
	STRLEN          kl;
	char           *key = SvPV(keysv, kl);
	SV             *retsv = Nullsv;

	dbd_ix_debug(1, "%s::dbd_dr_FETCH_attrib()\n", dbd_ix_module());

	if (KEY_MATCH(kl, key, "ix_MultipleConnections"))
	{
		retsv = newSViv((IV)imp_drh->multipleconnections);
	}
	else if (KEY_MATCH(kl, key, "ix_ActiveConnections"))
	{
		retsv = newSViv((IV)imp_drh->n_connections);
	}
	else if (KEY_MATCH(kl, key, "ix_CurrentConnection"))
	{
		char *conn = (char *)imp_drh->current_connection;	/* const_cast<char*> */
		if (conn == 0)
			conn = "<<no current connection>>";
		retsv = newSVpv(conn, 0);
	}
	else if (KEY_MATCH(kl, key, "ix_ProductVersion"))
	{
		retsv = newSViv((IV)esql_prodvrsn);
	}
	else if (KEY_MATCH(kl, key, "ix_ProductName"))
	{
		retsv = newSVpv((char *)esql_prodname, 0);	/* const_cast<char *> */
	}

	/* Deprecated */
	else if (KEY_MATCH(kl, key, "MultipleConnections"))
	{
		dbd_ix_deprecate("{MultipleConnections}");
		retsv = newSViv((IV)imp_drh->multipleconnections);
	}
	else if (KEY_MATCH(kl, key, "ActiveConnections"))
	{
		dbd_ix_deprecate("{ActiveConnections}");
		retsv = newSViv((IV)imp_drh->n_connections);
	}
	else if (KEY_MATCH(kl, key, "CurrentConnection"))
	{
		char *conn = (char *)imp_drh->current_connection;	/* const_cast<char*> */
		if (conn == 0)
			conn = "<<no current connection>>";
		dbd_ix_deprecate("{CurrentConnection}");
		retsv = newSVpv(conn, 0);
	}
	else if (KEY_MATCH(kl, key, "ProductVersion"))
	{
		dbd_ix_deprecate("{ProductVersion}");
		retsv = newSViv((IV)esql_prodvrsn);
	}
	else if (KEY_MATCH(kl, key, "ProductName"))
	{
		dbd_ix_deprecate("{ProductName}");
		retsv = newSVpv((char *)esql_prodname, 0);	/* const_cast<char *> */
	}

	else
		return FALSE;

	return sv_2mortal(retsv);
}

/* Set database connection attributes */
int dbd_db_STORE_attrib(imp_dbh_t *imp_dbh, SV *keysv, SV *valuesv)
{
	STRLEN          kl;
	char           *key = SvPV(keysv, kl);
	int             on = SvTRUE(valuesv);
	int             retval = True;

	dbd_ix_debug(1, "Enter %s::dbd_db_STORE_attrib()\n", dbd_ix_module());
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
				retval = dbd_db_begin(imp_dbh);
		}
	}
	else if (KEY_MATCH(kl, key, "ChopBlanks"))
	{
		if (on == False)
			DBIc_ChopBlanks_off(imp_dbh);
		else
			DBIc_ChopBlanks_on(imp_dbh);
	}
	else if (KEY_MATCH(kl, key, "BlobLocation"))
	{
		dbd_ix_deprecate("{BlobLocation}");
		imp_dbh->blob_bind = blob_bindtype(valuesv);
	}
	else if (KEY_MATCH(kl, key, "ix_BlobLocation"))
	{
		imp_dbh->blob_bind = blob_bindtype(valuesv);
	}
	else if (KEY_MATCH(kl, key, "AutoErrorReport"))
	{
		dbd_ix_deprecate("{AutoErrorReport}");
		imp_dbh->autoreport = on;
	}
	else if (KEY_MATCH(kl, key, "ix_AutoErrorReport"))
	{
		imp_dbh->autoreport = on;
	}
	else if (KEY_MATCH(kl, key, "ix_Deprecated"))
	{
		dbd_ix_deprecate("{ix_Deprecated}");
		deprecation = on;
	}
	else
	{
		retval = FALSE;
	}

	dbd_ix_debug(1, "Exit %s::dbd_db_STORE_attrib()\n", dbd_ix_module());
	return retval;
}

/* Convert sqlca.sqlerrd into an AV */
static SV *newSqlerrd(const Sqlca *psqlca)
{
	int i;
	AV *av = newAV();
	SV *retsv = newRV((SV *)av);
	av_extend(av, (I32)6);
	for (i = 0; i < 6; i++)
	{
		av_store(av, i, newSViv((IV)psqlca->sqlerrd[i]));
	}
	return(retsv);
}

/* Convert sqlca.sqlwarn into an AV */
static SV *newSqlwarn(const Sqlca *psqlca)
{
	int i;
	AV             *av = newAV();
	char            warning[2];
	const char     *sqlwarn = &psqlca->sqlwarn.sqlwarn0;
	SV *retsv = newRV((SV *)av);
	av_extend(av, (I32)8);
	warning[1] = '\0';
	for (i = 0; i < 8; i++)
	{
		warning[0] = *sqlwarn++;
		av_store(av, i, newSVpv(warning, 0));
	}
	return(retsv);
}

static SV *dbd_ix_getsqlca(imp_dbh_t *imp_dbh, STRLEN kl, char *key)
{
	SV *retsv = NULL;

	/* Preferred versions */
	if (KEY_MATCH(kl, key, "ix_sqlcode"))
	{
		retsv = newSViv((IV)imp_dbh->sqlca.sqlcode);
	}
	else if (KEY_MATCH(kl, key, "ix_sqlerrm"))
	{
		retsv = newSVpv(imp_dbh->sqlca.sqlerrm, 0);
	}
	else if (KEY_MATCH(kl, key, "ix_sqlerrp"))
	{
		retsv = newSVpv(imp_dbh->sqlca.sqlerrp, 0);
	}
	else if (KEY_MATCH(kl, key, "ix_sqlerrd"))
	{
		retsv = newSqlerrd(&imp_dbh->sqlca);
	}
	else if (KEY_MATCH(kl, key, "ix_sqlwarn"))
	{
		retsv = newSqlwarn(&imp_dbh->sqlca);
	}

	/* Deprecated versions */
	else if (KEY_MATCH(kl, key, "sqlcode"))
	{
		dbd_ix_deprecate("{sqlcode}");
		retsv = newSViv((IV)imp_dbh->sqlca.sqlcode);
	}
	else if (KEY_MATCH(kl, key, "sqlerrm"))
	{
		dbd_ix_deprecate("{sqlerrm}");
		retsv = newSVpv(imp_dbh->sqlca.sqlerrm, 0);
	}
	else if (KEY_MATCH(kl, key, "sqlerrp"))
	{
		dbd_ix_deprecate("{sqlerrp}");
		retsv = newSVpv(imp_dbh->sqlca.sqlerrp, 0);
	}
	else if (KEY_MATCH(kl, key, "sqlerrd"))
	{
		dbd_ix_deprecate("{sqlerrd}");
		retsv = newSqlerrd(&imp_dbh->sqlca);
	}
	else if (KEY_MATCH(kl, key, "sqlwarn"))
	{
		dbd_ix_deprecate("{sqlwarn}");
		retsv = newSqlwarn(&imp_dbh->sqlca);
	}

	return(retsv);
}

SV *dbd_db_FETCH_attrib(imp_dbh_t *imp_dbh, SV *keysv)
{
	STRLEN          kl;
	char           *key = SvPV(keysv, kl);
	SV             *retsv = Nullsv;

	dbd_ix_debug(1, "%s::dbd_db_FETCH_attrib()\n", dbd_ix_module());

	if (KEY_MATCH(kl, key, "AutoCommit"))
	{
		retsv = newSViv((IV)imp_dbh->autocommit);
	}
	else if (KEY_MATCH(kl, key, "ChopBlanks"))
	{
		retsv = newSViv((IV)(DBIc_ChopBlanks(imp_dbh) != 0));
	}
	else if (KEY_MATCH(kl, key, "ix_Deprecated"))
	{
		dbd_ix_deprecate("{ix_Deprecated}");
		retsv = newSViv((IV)deprecation);
	}
	else if (KEY_MATCH(kl, key, "ix_InformixOnLine"))
	{
		retsv = newSViv((IV)imp_dbh->is_onlinedb);
	}
	else if (KEY_MATCH(kl, key, "ix_LoggedDatabase"))
	{
		retsv = newSViv((IV)imp_dbh->is_loggeddb);
	}
	else if (KEY_MATCH(kl, key, "ix_InTransaction"))
	{
		retsv = newSViv((IV)imp_dbh->is_txactive);
	}
	else if (KEY_MATCH(kl, key, "ix_ModeAnsiDatabase"))
	{
		retsv = newSViv((IV)imp_dbh->is_modeansi);
	}
	else if (KEY_MATCH(kl, key, "ix_BlobLocation"))
	{
		retsv = newSVpv(blob_bindname(imp_dbh->blob_bind), 0);
	}
	else if (KEY_MATCH(kl, key, "ix_AutoErrorReport"))
	{
		retsv = newSViv((IV)imp_dbh->autoreport);
	}
	else if (KEY_MATCH(kl, key, "ix_ConnectionName"))
	{
		retsv = newSVpv(imp_dbh->nm_connection, 0);
	}
	else if ((retsv = dbd_ix_getsqlca(imp_dbh, kl, key)) != NULL)
	{
		/* Nothing to do */
	}

	/* Deprecated versions */
	else if (KEY_MATCH(kl, key, "Deprecated"))
	{
		dbd_ix_deprecate("{Deprecated}");
		retsv = newSViv((IV)deprecation);
	}
	else if (KEY_MATCH(kl, key, "InformixOnLine"))
	{
		dbd_ix_deprecate("{InformixOnLine}");
		retsv = newSViv((IV)imp_dbh->is_onlinedb);
	}
	else if (KEY_MATCH(kl, key, "LoggedDatabase"))
	{
		dbd_ix_deprecate("{LoggedDatabase}");
		retsv = newSViv((IV)imp_dbh->is_loggeddb);
	}
	else if (KEY_MATCH(kl, key, "InTransaction"))
	{
		dbd_ix_deprecate("{InTransaction}");
		retsv = newSViv((IV)imp_dbh->is_txactive);
	}
	else if (KEY_MATCH(kl, key, "ModeAnsiDatabase"))
	{
		dbd_ix_deprecate("{ModeAnsiDatabase}");
		retsv = newSViv((IV)imp_dbh->is_modeansi);
	}
	else if (KEY_MATCH(kl, key, "BlobLocation"))
	{
		dbd_ix_deprecate("{BlobLocation}");
		retsv = newSVpv(blob_bindname(imp_dbh->blob_bind), 0);
	}
	else if (KEY_MATCH(kl, key, "AutoErrorReport"))
	{
		dbd_ix_deprecate("{AutoErrorReport}");
		retsv = newSViv((IV)imp_dbh->autoreport);
	}
	else if (KEY_MATCH(kl, key, "ConnectionName"))
	{
		dbd_ix_deprecate("{ConnectionName}");
		retsv = newSVpv(imp_dbh->nm_connection, 0);
	}

	else
		return FALSE;

	return sv_2mortal(retsv);
}

/* Store statement attributes */
int dbd_st_STORE_attrib(imp_sth_t *sth, SV *keysv, SV *valuesv)
{
	STRLEN          kl;
	char           *key = SvPV(keysv, kl);
	dbd_ix_debug(1, "Enter %s::dbd_st_STORE_attrib()\n", dbd_ix_module());

	if (KEY_MATCH(kl, key, "BlobLocation"))
	{
		dbd_ix_deprecate("{BlobLocation}");
		sth->blob_bind = blob_bindtype(valuesv);
	}
	else if (KEY_MATCH(kl, key, "ix_BlobLocation"))
	{
		sth->blob_bind = blob_bindtype(valuesv);
	}
	else
		return FALSE;

	dbd_ix_debug(1, "Exit %s::dbd_st_STORE_attrib()\n", dbd_ix_module());
	return TRUE;
}

SV *dbd_st_FETCH_attrib(imp_sth_t *sth, SV *keysv)
{
	STRLEN          kl;
	char           *key = SvPV(keysv, kl);
	SV             *retsv = NULL;
	EXEC SQL BEGIN DECLARE SECTION;
	char           *nm_obind = sth->nm_obind;
	long			coltype;
	long			collength;
	long			colnull;
	char			colname[NAMESIZE];
	int             i;
	EXEC SQL END DECLARE SECTION;

	dbd_ix_debug(1, "Enter %s::dbd_st_FETCH_attrib()\n", dbd_ix_module());

	/* Standard attributes */
	if (KEY_MATCH(kl, key, "NAME"))
	{
		AV             *av = newAV();
		retsv = newRV((SV *)av);
		for (i = 1; i <= sth->n_columns; i++)
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
		for (i = 1; i <= sth->n_columns; i++)
		{
			EXEC SQL GET DESCRIPTOR :nm_obind VALUE :i
				:colnull = NULLABLE;
			av_store(av, i - 1, newSViv((IV)colnull));
		}
	}
	else if (KEY_MATCH(kl, key, "TYPE"))
	{
		/* Returns ODBC (CLI) type numbers. */
		AV             *av = newAV();
		retsv = newRV((SV *)av);
		for (i = 1; i <= sth->n_columns; i++)
		{
			SV		*sv;
			EXEC SQL GET DESCRIPTOR :nm_obind VALUE :i
				:coltype = TYPE, :collength = LENGTH;
			sv = newSViv(map_type_ifmx_to_odbc(coltype, collength));
			av_store(av, i - 1, sv);
		}
	}
	else if (KEY_MATCH(kl, key, "PRECISION"))
	{
		/* Should return CLI precision numbers. */
		AV             *av = newAV();
		retsv = newRV((SV *)av);
		for (i = 1; i <= sth->n_columns; i++)
		{
			SV		*sv;
			EXEC SQL GET DESCRIPTOR :nm_obind VALUE :i
				:coltype = TYPE, :collength = LENGTH;
			sv = newSViv(map_prec_ifmx_to_odbc(coltype, collength));
			av_store(av, i - 1, sv);
		}
	}
	else if (KEY_MATCH(kl, key, "SCALE"))
	{
		/* Should return CLI scale numbers. */
		AV             *av = newAV();
		retsv = newRV((SV *)av);
		for (i = 1; i <= sth->n_columns; i++)
		{
			SV		*sv;
			EXEC SQL GET DESCRIPTOR :nm_obind VALUE :i
				:coltype = TYPE, :collength = LENGTH;
			sv = newSViv(map_scale_ifmx_to_odbc(coltype, collength));
			av_store(av, i - 1, sv);
		}
	}
	else if (KEY_MATCH(kl, key, "NUM_OF_PARAMS"))
	{
		retsv = newSViv((IV)sth->n_bound);
	}
	else if (KEY_MATCH(kl, key, "NUM_OF_FIELDS"))
	{
		retsv = newSViv((IV)sth->n_columns);
	}
	else if (KEY_MATCH(kl, key, "CursorName"))
	{
		retsv = newSVpv(sth->nm_cursor, 0);
	}

	/* Informix specific attributes */
	else if (KEY_MATCH(kl, key, "ix_NativeTypeNames"))
	{
		AV             *av = newAV();
		char buffer[SQLTYPENAME_BUFSIZ];
		SV		*sv;
		retsv = newRV((SV *)av);
		for (i = 1; i <= sth->n_columns; i++)
		{
			EXEC SQL GET DESCRIPTOR :nm_obind VALUE :i
				:coltype = TYPE, :collength = LENGTH;
			sv = newSVpv(sqltypename(coltype, collength, buffer), 0);
			av_store(av, i - 1, sv);
		}
	}
	else if (KEY_MATCH(kl, key, "NativeTypeNames"))
	{
		AV             *av = newAV();
		char buffer[SQLTYPENAME_BUFSIZ];
		SV		*sv;
		dbd_ix_deprecate("{NativeTypeNames}");
		retsv = newRV((SV *)av);
		for (i = 1; i <= sth->n_columns; i++)
		{
			EXEC SQL GET DESCRIPTOR :nm_obind VALUE :i
				:coltype = TYPE, :collength = LENGTH;
			sv = newSVpv(sqltypename(coltype, collength, buffer), 0);
			av_store(av, i - 1, sv);
		}
	}
	else if (KEY_MATCH(kl, key, "ix_Fetchable"))
	{
		Boolean rv = ((sth->st_type == SQ_SELECT) ||
						(sth->st_type == SQ_EXECPROC && sth->n_columns > 0));
		retsv = newSViv((IV)rv);
	}
	else if (KEY_MATCH(kl, key, "ix_BlobLocation"))
	{
		retsv = newSVpv(blob_bindname(sth->dbh->blob_bind), 0);
	}
	else if (KEY_MATCH(kl, key, "BlobLocation"))
	{
		dbd_ix_deprecate("{BlobLocation}");
		retsv = newSVpv(blob_bindname(sth->dbh->blob_bind), 0);
	}
	else if ((retsv = dbd_ix_getsqlca(sth->dbh, kl, key)) != NULL)
	{
		/* Nothing specific to do */
	}
	else if (KEY_MATCH(kl, key, "ix_ColType"))
	{
		AV             *av = newAV();
		retsv = newRV((SV *)av);
		for (i = 1; i <= sth->n_columns; i++)
		{
			EXEC SQL GET DESCRIPTOR :nm_obind VALUE :i
				:coltype = TYPE;
			av_store(av, i - 1, newSViv((IV)coltype));
		}
	}
	else if (KEY_MATCH(kl, key, "ix_ColLength"))
	{
		AV             *av = newAV();
		retsv = newRV((SV *)av);
		for (i = 1; i <= sth->n_columns; i++)
		{
			EXEC SQL GET DESCRIPTOR :nm_obind VALUE :i
				:collength = LENGTH;
			av_store(av, i - 1, newSViv((IV)collength));
		}
	}
	else
	{
		return Nullsv;
	}

	dbd_ix_debug(1, "Exit %s::dbd_st_FETCH_attrib\n", dbd_ix_module());

	return sv_2mortal(retsv);
}

