/*
 * @(#)esqlc_v6.ec	53.2 97/03/06 17:17:55
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
#include "esqlperl.h"

#ifndef lint
static const char sccs[] = "@(#)esqlc_v6.ec	53.2 97/03/06";
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

	if (dbase == (char *)0 || *dbase == '\0')
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

void dbd_ix_disconnect(char *connection)
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
void dbd_ix_setconnection(char *conn)
{
	EXEC SQL BEGIN DECLARE SECTION;
	char           *nm_connection = conn;
	EXEC SQL END DECLARE SECTION;

	dbd_ix_debug(1, "SET CONNECTION %s\n", nm_connection);
	EXEC SQL SET CONNECTION :nm_connection;
}
