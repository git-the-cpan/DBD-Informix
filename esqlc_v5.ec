/*
 * @(#)esqlc_v5.ec	51.1 97/02/26 12:03:40
 *
 * DBD::Informix for Perl Version 5 -- implementation details
 *
 * Code acceptable to ESQL/C Version 5.0x
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
static const char sccs[] = "@(#)esqlc_v5.ec	51.1 97/02/26";
#endif

/* ================================================================= */
/* =================== Database Level Operations =================== */
/* ================================================================= */

/* Open database, possibly on a 'remote' host */
Boolean
dbd_ix_opendatabase(char *dbase)
{
	EXEC SQL BEGIN DECLARE SECTION;
	char           *dbname = dbase;
	EXEC SQL END DECLARE SECTION;
	Boolean         conn_ok = False;

	if (dbase == (char *)0 || *dbase == '\0' ||
		strcmp(dbase, DEFAULT_DATABASE) == 0)
	{
		dbd_ix_debug(1, "ESQL/C 5.0x 'implicit' DATABASE - %s\n", "no-op");
		conn_ok = True;
	}
	else
	{
		dbd_ix_debug(1, "DATABASE %s\n", dbname);
		EXEC SQL DATABASE :dbname;
		if (sqlca.sqlcode == 0)
			conn_ok = True;
	}
	return(conn_ok);
}

void
dbd_ix_closedatabase(void)
{
	dbd_ix_debug(1, "CLOSE DATABASE%s\n", "");
	EXEC SQL CLOSE DATABASE;
}

/* Ensure that the correct connection is current -- a no-op in version 5.0x */
int dbd_ix_setconnection(imp_dbh_t *imp_dbh)
{
	int rc = 1;
	dbd_ix_debug(1, "SET CONNECTION - %s\n", "no-op");
	return(rc);
}
