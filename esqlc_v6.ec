/*
 * @(#)esqlc_v6.ec	25.4 96/12/02 10:19:05
 *
 * DBD::Informix for Perl Version 5 -- implementation details
 *
 * Code acceptable to ESQL/C Version 5.0x
 *
 * Copyright (c) 1996 Jonathan Leffler
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 */

/*TABSTOP=4*/

#ifndef lint
static const char sccs[] = "@(#)esqlc_v6.ec	25.4 96/12/02";
#endif

#include "Informix.h"
#include "esqlc.h"

/* ================================================================= */
/* =================== Database Level Operations =================== */
/* ================================================================= */

/*
** Use CONNECT to initiate database connection
**
** If both user and password are provided, then the USER clause is used.
** If no database is specified, a default connection will be made.
**
** Note that CONNECT statements (and DISCONNECT and SET CONNECTION)
** cannot be prepared.
*/

/* ARGSUSED */
void     dbd_ix_connect(connection, dbase, user, pass)
char           *connection;
char           *dbase;
char           *user;
char           *pass;
{
	EXEC SQL BEGIN DECLARE SECTION;
	char           *dbconn;
	char           *dbname;
	char           *dbpass;
	char           *dbuser;
	EXEC SQL END DECLARE SECTION;

	if (dbase == (char *)0)
	{
		dbd_ix_debug(0, "*** BREAKAGE *** Default connection (%s)\n",
						connection);
		EXEC SQL CONNECT TO DEFAULT
			WITH CONCURRENT TRANSACTION;
	}
	else if (user != (char *)0 && pass != (char *)0)
	{
		dbconn = connection;
		dbname = dbase;
		dbpass = pass;
		dbuser = user;
		dbd_ix_debug(2, "CONNECT with user info (%s)\n", connection);
		EXEC SQL CONNECT TO :dbname AS :dbconn
			USER :dbuser USING :dbpass
			WITH CONCURRENT TRANSACTION;
	}
	else
	{
		dbconn = connection;
		dbname = dbase;
		dbd_ix_debug(2, "CONNECT - no user info (%s)\n", connection);
		EXEC SQL CONNECT TO :dbname AS :dbconn
			WITH CONCURRENT TRANSACTION;
	}
}

void
dbd_ix_disconnect(char *connection)
{
	EXEC SQL BEGIN DECLARE SECTION;
	char           *dbconn = connection;
	EXEC SQL END DECLARE SECTION;

	dbd_ix_debug(2, "DISCONNECT (%s)\n", connection);
	EXEC SQL DISCONNECT :dbconn;
}

/* Ensure that the correct connection is current -- a no-op in version 5.0x */
int dbd_ix_setconnection(imp_sth_t *imp_sth)
{
	int rc = 1;
	D_imp_dbh_from_sth;
	D_imp_drh_from_dbh;
	EXEC SQL BEGIN DECLARE SECTION;
	char           *nm_connection = imp_dbh->nm_connection;
	EXEC SQL END DECLARE SECTION;

	if (imp_drh->current_connection != nm_connection)
	{
		EXEC SQL SET CONNECTION :nm_connection;
		imp_drh->current_connection = nm_connection;
		dbd_ix_sqlcode(imp_dbh);
		if (sqlca.sqlcode < 0)
			rc = 0;
	}
	return(rc);
}
