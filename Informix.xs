/*
 * @(#)$Id: Informix.xs,v 57.1 1997/07/30 03:18:03 johnl Exp $ 
 *
 * Portions Copyright (c) 1994,1995 Tim Bunce
 * Portions Copyright (c) 1995,1996 Alligator Descartes
 * Portions Copyright (c) 1996,1997 Jonathan Leffler
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 */

/*TABSTOP=4*/

#include "Informix.h"

DBISTATE_DECLARE;

/* Assume string concatenation is available */
#ifndef lint
static const char rcs[] =
	"@(#)$Id: Informix.xs,v 57.1 1997/07/30 03:18:03 johnl Exp $";
static const char esqlc_ver[] =
	"@(#)" ESQLC_VERSION_STRING;
#endif

MODULE = DBD::Informix	PACKAGE = DBD::Informix

INCLUDE: Informix.xsi

MODULE = DBD::Informix	PACKAGE = DBD::Informix::dr

# Initialize the DBD::Informix driver data structure
void
driver_init(drh)
	SV *        drh
	CODE:
	ST(0) = dbd_ix_dr_driver(drh) ? &sv_yes : &sv_no;

# Fetch a driver attribute.  The keys are always strings.
# For some reason, not a part of the DBI standard
void
FETCH(drh, keysv)
	SV *        drh
	SV *        keysv
	CODE:
	D_imp_drh(drh);
	SV *valuesv = dbd_ix_dr_FETCH_attrib(imp_drh, keysv);
	if (!valuesv)
		valuesv = DBIS->get_attr(drh, keysv);
	ST(0) = valuesv;    /* dbd_dr_FETCH_attrib did sv_2mortal  */

# Utility function to list available databases
void
data_sources(drh)
	SV *drh
	PPCODE:
# Note that a database name could consist of up to 18 characters in OnLine,
# plus the name of the server (no limit defined, assume 18 again), plus the
# at sign and the NUL at the end.
#define MAXDBS 100
#define MAXDBSSIZE	(18+18+2)
#define FASIZE (MAXDBS * MAXDBSSIZE)
	int sqlcode;
	int ndbs;
	int i;
	char *dbsname[MAXDBS + 1];
	char dbsarea[FASIZE];
	sqlcode = sqgetdbs(&ndbs, dbsname, MAXDBS, dbsarea, FASIZE);
	if (sqlcode != 0)
	{
		dbd_ix_seterror(sqlcode);
	}
	else
	{
		for (i = 0; i < ndbs; ++i)
		{
			# Let Perl calculate the length of the name
			XPUSHs(sv_2mortal((SV*)newSVpv(dbsname[i], 0)));
		}
	}

MODULE = DBD::Informix    PACKAGE = DBD::Informix::db

void
preset(dbh, dbattr)
	SV *        dbh
	SV *        dbattr
	CODE:
	{
	D_imp_dbh(dbh);
	ST(0) = dbd_ix_db_preset(imp_dbh, dbattr) ? &sv_yes : &sv_no;
	}

MODULE = DBD::Informix    PACKAGE = DBD::Informix::st

# end of Informix.xs
