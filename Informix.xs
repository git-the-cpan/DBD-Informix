/*
 * @(#)Informix.xs	53.1 97/03/06 19:28:48
 *
 * Portions Copyright (c) 1994,1995 Tim Bunce
 * Portions Copyright (c) 1995,1996 Alligator Descartes
 * Portions Copyright (c) 1996,1997 Jonathan Leffler
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 */

#include "Informix.h"

/* --- Variables --- */

DBISTATE_DECLARE;

/* Assume string concatenation is available */
#ifndef lint
static const char sccs[] = "@(#)Informix.xs	53.1 97/03/06";
static const char esqlc_ver[] = "@(#)" ESQLC_VERSION_STRING;
#endif

MODULE = DBD::Informix	PACKAGE = DBD::Informix

REQUIRE:    1.929
PROTOTYPES: ENABLE

BOOT:
	items = 0;	/* avoid 'unused variable' warning */
	DBISTATE_INIT;
	/* XXX this interface will change: */
	DBI_IMP_SIZE("DBD::Informix::dr::imp_data_size", sizeof(imp_drh_t));
	DBI_IMP_SIZE("DBD::Informix::db::imp_data_size", sizeof(imp_dbh_t));
	DBI_IMP_SIZE("DBD::Informix::st::imp_data_size", sizeof(imp_sth_t));
	dbd_dr_init(DBIS);

void
errstr(h)
	SV *	h
	CODE:
	/* called from DBI::var TIESCALAR code for $DBI::errstr	*/
	D_imp_xxh(h);
	ST(0) = sv_mortalcopy(DBIc_ERRSTR(imp_xxh));

MODULE = DBD::Informix	PACKAGE = DBD::Informix::dr

# Initialize the DBD::Informix driver data structure
void
driver_init(drh)
	SV *        drh
	CODE:
	ST(0) = dbd_dr_driver(drh) ? &sv_yes : &sv_no;

# Disconnect all current connections for this driver
# The conditional code is a legacy -- it is neither clear what it means
# nor why it is necessary.
void
disconnect_all(drh)
	SV *        drh
	CODE:
	if (!dirty && !SvTRUE(perl_get_sv("DBI::PERL_ENDING", 0)))
	{
		D_imp_drh(drh);
		ST(0) = dbd_dr_disconnectall(imp_drh) ? &sv_yes : &sv_no;
	}
	else
	{
		/* perl_destruct with perl_destruct_level and $SIG{__WARN__} set	*/
		/* to a code ref core dumps when sv_2cv triggers warn loop.		*/
		if (perl_destruct_level)
			perl_destruct_level = 0;
		XST_mIV(0, 1);
	}

# Utility function to list available databases
void
_ListDBs( drh )
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

# Connect to the named database with username and password 
void
connect(dbh, dbname, uid, pwd)
	SV   *dbh
	char *dbname
	char *uid
	char *pwd
	CODE:
	D_imp_dbh(dbh);
	ST(0) = dbd_db_connect(imp_dbh, dbname, uid, pwd) ? &sv_yes : &sv_no;

# Begin work (analogue of commit and rollback, below)
# Cannot be called using "$dbh->begin", unlike commit and rollback
void
begin(dbh)
	SV *        dbh
	CODE:
	D_imp_dbh(dbh);
	ST(0) = dbd_db_begin(imp_dbh) ? &sv_yes : &sv_no;

# Commit work
void
commit(dbh)
	SV *        dbh
	CODE:
	D_imp_dbh(dbh);
	ST(0) = dbd_db_commit(imp_dbh) ? &sv_yes : &sv_no;

# Rollback work
void
rollback(dbh)
	SV *        dbh
	CODE:
	D_imp_dbh(dbh);
	ST(0) = dbd_db_rollback(imp_dbh) ? &sv_yes : &sv_no;

# Store a connection attribute.
# Are the keys always strings?  I think so...  So we could use
# 'char *keysv'.  The caching and DBIS->set_attr() calls should be
# handled in the main DBI code.
void
STORE(dbh, keysv, valuesv)
	SV *        dbh
	SV *        keysv
	SV *        valuesv
	CODE:
	D_imp_dbh(dbh);
	ST(0) = &sv_yes;
	if (dbd_db_STORE_attrib(imp_dbh, keysv, valuesv))
	{
		/* This caching should be handled by the DBI switch, somehow */
		/* Cache for next time (via DBI quick_FETCH) */
		STRLEN          kl;
		char           *key = SvPV(keysv, kl);
		hv_store((HV *)SvRV(dbh), key, kl, &sv_yes, 0);
	}
	else if (!DBIS->set_attr(dbh, keysv, valuesv))
		ST(0) = &sv_no;

# Fetch a connection attribute.
# Are the keys always strings?  I think so...  So we could use
# 'char *keysv'.  The caching and DBIS->set_attr() calls should be
# handled in the main DBI code.
void
FETCH(dbh, keysv)
	SV *        dbh
	SV *        keysv
	CODE:
	D_imp_dbh(dbh);
	SV *valuesv = dbd_db_FETCH_attrib(imp_dbh, keysv);
	if (!valuesv)
		valuesv = DBIS->get_attr(dbh, keysv);
	ST(0) = valuesv;    /* dbd_db_FETCH_attrib did sv_2mortal  */

# Disconnect from whichever database it is connected to.
void
disconnect(dbh)
	SV *        dbh
	CODE:
	D_imp_dbh(dbh);
	if (!DBIc_ACTIVE(imp_dbh))
	{
		XSRETURN_YES;
	}
	ST(0) = dbd_db_disconnect(imp_dbh) ? &sv_yes : &sv_no;

# Execute immediate for a statement without parameter attributes
void
immediate(dbh, stmt)
	SV	*dbh
	char *stmt
	CODE:
	D_imp_dbh(dbh);
	ST(0) = dbd_db_immediate(imp_dbh, stmt) ? &sv_yes : &sv_no;

# Destroy the database handle
# The conditional code is a legacy -- it is neither clear what it means
# nor why it is necessary.
void
DESTROY(dbh)
	SV *        dbh
	PPCODE:
	D_imp_dbh(dbh);
	ST(0) = &sv_yes;
	if (!DBIc_IMPSET(imp_dbh))
	{        /* was never fully set up       */
		if (DBIc_WARN(imp_dbh) && !dirty && dbis->debug >= 2)
			 warn("Database handle %s DESTROY ignored - never set up",
				SvPV(dbh, na));
	}
	else
	{
		if (DBIc_ACTIVE(imp_dbh))
		{
			if (DBIc_WARN(imp_dbh) && !dirty)
				 warn("Database handle destroyed without explicit disconnect");
			dbd_db_disconnect(imp_dbh);
		}
		dbd_db_destroy(imp_dbh);
	}

MODULE = DBD::Informix    PACKAGE = DBD::Informix::st

# Prepare a statement, returning the new statement handle
void
prepare(sth, statement, attribs=Nullsv)
	SV *        sth
	char *      statement
	SV *	attribs
	CODE:
	# This code block needs to be present as the default argument for
	# attribs introduces some code, making the declaration concealed in
	# D_imp_sth(sth) invalid.
	{
	D_imp_sth(sth);
	DBD_ATTRIBS_CHECK("prepare", sth, attribs);
	ST(0) = dbd_st_prepare(imp_sth, statement, attribs) ? &sv_yes : &sv_no;
	}

# Some sort of count of the number of rows, exact semantics undefined.
void
rows(sth)
	SV *        sth
	CODE:
	croak("DBD::Informix::rows is not implemented\n");

# Some parameter binding, exact semantics undefined
void
bind_param(sth, param, value, attribs=Nullsv)
	SV *	sth
	SV *	param
	SV *	value
	SV *	attribs
	CODE:
	croak("DBD::Informix::bind_param_inout is not implemented\n");

# More parameter binding, exact semantics undefined
void
bind_param_inout(sth, param, value_ref, maxlen, attribs=Nullsv)
	SV *	sth
	SV *	param
	SV *	value_ref
	IV 		maxlen
	SV *	attribs
	CODE:
	croak("DBD::Informix::bind_param_inout is not implemented\n");

# Execute a statement or open a cursor, possibly with bound values
void
execute(sth, ...)
	SV *        sth
	CODE:
	D_imp_sth(sth);
	int retval;

	if (items > 1)
	{
		if (dbd_ix_setbindnum(imp_sth, items - 1))
		{
			int i;
			int error = 0;
			for(i = 1; i < items; i++)
			{
				if (!dbd_ix_bindsv(imp_sth, i, ST(i)))
						++error;
			}
			if (error)
			{
				XSRETURN_UNDEF;	/* dbd_ix_bindsv() already registered error	*/
			}
		}
	}

	retval = dbd_st_execute(imp_sth);
	if (retval < 0)
		XST_mUNDEF(0);		/* error        		*/
	else if (retval == 0)
		XST_mPV(0, "0E0");	/* true but zero		*/
	else
		XST_mIV(0, retval);	/* typically 1 or rowcount	*/

# Return a row as a reference to an array
void
fetch(sth)
	SV *	sth
	CODE:
	D_imp_sth(sth);
	AV *av = dbd_st_fetch(imp_sth);
	ST(0) = (av) ? sv_2mortal(newRV((SV *)av)) : &sv_undef;

# Return a row as an array
# Is this really the best way to do this?
void
fetchrow(sth)
	SV *	sth
	PPCODE:
	D_imp_sth(sth);
	AV *av;
	if (DBIc_COMPAT(imp_sth) && GIMME == G_SCALAR)
	{
		XSRETURN_IV(DBIc_NUM_FIELDS(imp_sth));
	}
	else
	{
		av = dbd_st_fetch(imp_sth);
		if (av)
		{
			int num_fields = AvFILL(av)+1;
			int i;
			EXTEND(sp, num_fields);
			for(i = 0; i < num_fields; ++i)
			{
				PUSHs(AvARRAY(av)[i]);
			}
		}
	}

void
blob_read(sth, field, offset, len, destrv=Nullsv, destoffset=0)
	SV *        sth
	int field
	long        offset
	long        len
	SV *	destrv
	long	destoffset
	CODE:
	croak("DBD::Informix::blob_read is not implemented\n");

# Store a statement attribute
# Are the keys always strings?  I think so...  So we could use
# 'char *keysv'.  The caching and DBIS->set_attr() calls should be
# handled in the main DBI code.
void
STORE(sth, keysv, valuesv)
	SV *	sth
	SV *        keysv
	SV *        valuesv
	CODE:
	D_imp_sth(sth);
	ST(0) = &sv_yes;
	if (!dbd_st_STORE_attrib(imp_sth, keysv, valuesv))
		if (!DBIS->set_attr(sth, keysv, valuesv))
			ST(0) = &sv_no;

# Fetch a statement attribute
# Are the keys always strings?  I think so...  So we could use
# 'char *keysv'.  The caching and DBIS->set_attr() calls should be
# handled in the main DBI code.
void
FETCH(sth, keysv)
	SV *        sth
	SV *        keysv
	CODE:
	D_imp_sth(sth);
	SV *valuesv = dbd_st_FETCH_attrib(imp_sth, keysv);
	if (!valuesv)
		valuesv = DBIS->get_attr(sth, keysv);
	ST(0) = valuesv;    /* dbd_st_FETCH_attrib did sv_2mortal  */

# Finish a statement (CLOSE a cursor; free allocated resources)
void
finish(sth)
	SV *        sth
	CODE:
	D_imp_sth(sth);
	D_imp_dbh_from_sth;
	if (!DBIc_ACTIVE(imp_dbh))
	{
		/* Either an explicit disconnect() or global destruction        */
		/* has disconnected us from the database. Finish is meaningless */
		XSRETURN_YES;
	}
	if (!DBIc_ACTIVE(imp_sth))
	{
		/* No active statement to finish        */
		XSRETURN_YES;
	}
	ST(0) = dbd_st_finish(imp_sth) ? &sv_yes : &sv_no;

# Destroy a statement...
void
DESTROY(sth)
	SV *        sth
	PPCODE:
	D_imp_sth(sth);
	ST(0) = &sv_yes;
	if (!DBIc_IMPSET(imp_sth))
	{        /* was never fully set up       */
		if (DBIc_WARN(imp_sth) && !dirty && dbis->debug >= 2)
			warn("Statement handle %s DESTROY ignored - never set up",
				SvPV(sth, na));
	}
	else
	{
		if (DBIc_ACTIVE(imp_sth))
			dbd_st_finish(imp_sth);
		dbd_st_destroy(imp_sth);
	}

# end of Informix.xs
