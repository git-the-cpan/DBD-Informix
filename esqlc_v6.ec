/*
 * @(#)esqlc_v6.ec	51.1 97/02/26 12:03:41
 *
 * DBD::Informix for Perl Version 5 -- implementation details
 *
 * Code acceptable to ESQL/C Version 6.0x and later
 *
 * Copyright (c) 1996,1997 Jonathan Leffler
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 */

/*TABSTOP=4*/

#include <string.h>
#include "Informix.h"

#ifndef lint
static const char sccs[] = "@(#)esqlc_v6.ec	51.1 97/02/26";
#endif

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

Boolean dbd_ix_connect(char *connection, char *dbase, char *user, char *pass)
{
	EXEC SQL BEGIN DECLARE SECTION;
	char           *dbconn;
	char           *dbname;
	char           *dbpass;
	char           *dbuser;
	EXEC SQL END DECLARE SECTION;
	Boolean         conn_ok = False;

	if (dbase == (char *)0 || *dbase == '\0' ||
		strcmp(dbase, DEFAULT_DATABASE) == 0)
	{
		/* Not frequently used, but valid */
		/* Reset connection name to empty string, and connect to default */
		/* Typically used to create database on default server */
		/* Nasty interface, overwriting connection name! */
		*connection = '\0';
		dbd_ix_debug(1, "CONNECT TO DEFAULT%s\n", connection);
		EXEC SQL CONNECT TO DEFAULT
			WITH CONCURRENT TRANSACTION;
	}
	else if (user != (char *)0 && pass != (char *)0)
	{
		dbconn = connection;
		dbname = dbase;
		dbpass = pass;
		dbuser = user;
		dbd_ix_debug(1, "CONNECT with user info (%s)\n", connection);
		EXEC SQL CONNECT TO :dbname AS :dbconn
			USER :dbuser USING :dbpass
			WITH CONCURRENT TRANSACTION;
	}
	else
	{
		dbconn = connection;
		dbname = dbase;
		dbd_ix_debug(1, "CONNECT - no user info (%s)\n", connection);
		EXEC SQL CONNECT TO :dbname AS :dbconn
			WITH CONCURRENT TRANSACTION;
	}
	if (sqlca.sqlcode == 0)
		conn_ok = True;
	return(conn_ok);
}

void
dbd_ix_disconnect(char *connection)
{
	EXEC SQL BEGIN DECLARE SECTION;
	char           *dbconn = connection;
	EXEC SQL END DECLARE SECTION;

	if (*connection != '\0')
	{
		dbd_ix_debug(1, "DISCONNECT (%s)\n", connection);
		EXEC SQL DISCONNECT :dbconn;
	}
	else
	{
		dbd_ix_debug(1, "DISCONNECT DEFAULT%s\n", connection);
		EXEC SQL DISCONNECT DEFAULT;
	}
}

/* Ensure that the correct connection is current -- a no-op in version 5.0x */
int dbd_ix_setconnection(imp_dbh_t *imp_dbh)
{
	int rc = 1;
	D_imp_drh_from_dbh;
	EXEC SQL BEGIN DECLARE SECTION;
	char           *nm_connection = imp_dbh->nm_connection;
	EXEC SQL END DECLARE SECTION;

	/* If this connection isn't connected, return with failure */
	/* Primarily a concern when destroying connections */
	if (imp_dbh->is_connected == False)
		return(0);

	if (imp_drh->current_connection != nm_connection)
	{
		dbd_ix_debug(1, "SET CONNECTION %s\n", nm_connection);
		EXEC SQL SET CONNECTION :nm_connection;
		imp_drh->current_connection = nm_connection;
		dbd_ix_sqlcode(imp_dbh);
		if (sqlca.sqlcode < 0)
			rc = 0;
	}
	return(rc);
}
