/*
 * @(#)esqlc_v5.ec	25.3 96/11/22 17:50:11
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
static const char sccs[] = "@(#)esqlc_v5.ec	25.3 96/11/22";
#endif

#include "Informix.h"
#include "esqlc.h"

/* ================================================================= */
/* =================== Database Level Operations =================== */
/* ================================================================= */

/* Open database, possibly on a 'remote' host */
void
dbd_ix_opendatabase(char *dbase)
{
	EXEC SQL BEGIN DECLARE SECTION;
	char           *dbname = dbase;
	EXEC SQL END DECLARE SECTION;

	dbd_ix_debug(2, "DATABASE %s\n", dbname);
	EXEC SQL DATABASE :dbname;
}

void
dbd_ix_closedatabase(void)
{
	dbd_ix_debug(2, "CLOSE DATABASE%s\n", "");
	EXEC SQL CLOSE DATABASE;
}

/* Ensure that the correct connection is current -- a no-op in version 5.0x */
int dbd_ix_setconnection(imp_sth_t *imp_sth)
{
	int rc = 1;
	return(rc);
}
