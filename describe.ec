/*
@(#)File:           $RCSfile: describe.ec,v $
@(#)Version:        $Revision: 2005.1 $
@(#)Last changed:   $Date: 2005/01/12 19:48:44 $
@(#)Purpose:        Allocate space for SQLDA structure
@(#)Author:         J Leffler
@(#)Copyright:      (C) JLSS 1992-93,1995-2001,2003-05
@(#)Product:        IBM Informix Database Driver for Perl DBI Version 2005.01 (2005-03-14)
*/

/*TABSTOP=4*/
/*LINTLIBRARY*/

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif /* HAVE_CONFIG_H */

#include <fcntl.h>
#include <stdlib.h>
#include "emalloc.h"
#include "esqlc.h"
#include "describe.h"
#include "esqlutil.h"
#include "ixblob.h"

#ifdef ESQLC_IUSTYPES
#define jtypmsize(a, b)	rtypmsize(a, b)
#define jtypalign(a, b)	rtypalign(a, b)
#endif /* ESQLC_IUSTYPES */

#ifndef lint
static const char rcs[] = "@(#)$Id: describe.ec,v 2005.1 2005/01/12 19:48:44 jleffler Exp $";
#endif

/*
** Where necessary, convert an SQL* type to a C*TYPE type.
*/
static int      jtypctype(int stype)
{
	int             rtype;

	switch (stype)
	{
	case SQLCHAR:
#ifdef SQLNCHAR
	case SQLNCHAR:
#endif /* SQLNCHAR */
		rtype = CCHARTYPE;
		ESQLC_VERSION_CHECKER();
		break;

	case SQLVCHAR:
#ifdef SQLNVCHAR
	case SQLNVCHAR:
#endif /* SQLNCHAR */
		rtype = CVCHARTYPE;
		break;

#ifdef ESQLC_IUSTYPES
	case SQLSET:
	case SQLMULTISET:
	case SQLLIST:
	case SQLLVARCHAR:
		rtype = CLVCHARPTRTYPE;
		break;
#endif /* ESQLC_IUSTYPES */

	default:
		rtype = stype;
		break;
	}
	return(rtype);
}

static int      jtypcsize(int sqltyp, int sqllen)
{
	int             rlen;

	switch (sqltyp)
	{
	case SQLCHAR:
#ifdef SQLNCHAR
	case SQLNCHAR:
#endif /* SQLNCHAR */
		rlen = sqllen + 1;
		break;

	case SQLVCHAR:
#ifdef SQLNVCHAR
	case SQLNVCHAR:
#endif /* SQLNCHAR */
		rlen = VCMAX(sqllen) + 1;
		/* SELECT '' ... returns VARCHAR(0) (even in SE) */
		/* Need at least 2 bytes allocated to avoid error -1235 */
		if (rlen == 1)
			rlen = 2;
		break;

	default:
		rlen = sqllen;
		break;
	}
	return(rlen);
}

/*
** JL 2003-04-07: What we 'really need' is a set of functions defined
** for each data type which do various important things.  For example,
** blobs (and LVARCHARPTR) data needs to be initialized properly - there
** needs to be an initialization routine - and a free routine, and a
** size routine, and an alignment routine, and ...  And there needs to
** be an array of pointers to such routines, such that we can index into
** the array and invoke them with appropriate parameters and get the
** required result.  In the interim, you get nasty initializations and
** screw-ball cases like the tests below.
*/

/*
** Calculate and store the offsets of data in an SQLDA structure.
** Return the total amount of memory needed.
** This code assumes that pointers and longs are compatible.
** It also assumes that the Sqlda structure only contains SQLxxx types.
**
** KLUDGE: There are bugs in both rtypmsize and rtypalign in Versions
** 4.00 & 4.10 which require long and tedious code to circumvent them.
** rtypmsize fibs about the size of SQLDTIME and SQLINTERVAL
** (returning sizeof(dec_t) instead of sizeof(dtime_t) and
** sizeof(intrvl_t)), and doesn't recognise CDTIMETYPE, CINVTYPE,
** SQLBYTES, SQLTEXT, and CLOCATORTYPE at all, returning size 0.
** rtypalign fibs about the alignment requirements of CDTIMETYPE,
** CINVTYPE, SQLBYTES, SQLTEXT, and CLOCATORTYPE, saying they can be
** byte-aligned when they cannot necessarily be byte-aligned.
**
** These bugs have all been fixed in Version 5.00.
**
** Additionally, in Version 4.00 and 4.10, if the type in the SQLDA
** structure is left as SQLCHAR or SQLVCHAR and the length field is
** not modified, then the string types are truncated.  This is a pain
** since the size allocated allows for a terminating null.  The
** routines jtypcsize and jtypctype have been invented to allow for
** these anomalies.
*/
static size_t sql_descsize(Sqlda *desc)
{
	Sqlva          *col;
	size_t          offset;
	int             i;
	size_t          size;

	offset = 0;
	for (col = desc->sqlvar, i = 0; i < desc->sqld; col++, i++)
	{
/*fprintf(stderr, "B%d: type = %d, len = %d\n", i, col->sqltype, col->sqllen);*/
		size = jtypmsize(col->sqltype, col->sqllen);
		offset = jtypalign(offset, col->sqltype);
		col->sqldata = (char *)offset;
		col->sqllen  = jtypcsize(col->sqltype, col->sqllen);
		col->sqltype = jtypctype(col->sqltype);
		offset += size; 
/*fprintf(stderr, "A%d: type = %d, len = %d, size = %d\n", i, col->sqltype, col->sqllen, size);*/ 
	}
	/* Make overall size compatible with a C short so that an  */
	/* array of indicator variables can be allocated after it. */
	offset = jtypalign(offset, SQLSMINT);
	return(offset);
}

/*
** Allocate the memory for the data described by an SQLDA structure.
** Includes an array of indicator variables.
** This code assumes that pointers and size_t's are compatible.
** NB: By default, MALLOC() expands to emalloc(), which in turn checks
** that the memory really was allocated.  The check on the allocation
** is, therefore, normally redundant.  However, we also have to allow
** for the possibility that MALLOC() is redefined as malloc().
*/
void           *sql_describe(Sqlda *desc)
{
	Sqlva          *col;
	void		   *space;
	char           *buffer;
	short          *indarray;
	size_t          size;
	size_t          offset;
	size_t          i;
	size_t          n;

	/* Step 1 -- calculate memory required */
	size = sql_descsize(desc);

	/* Step 2 -- allocate memory */
	space = MALLOC(size + desc->sqld * sizeof(ixInt2));
	if (space != 0)
	{
		buffer = (char *)space;	/*=C++=*/
		indarray = (short *)(buffer + size);

		/* Step 3 -- fix up pointers and indicators and initialize */
		offset = (long)buffer;
		col = desc->sqlvar;
		n = desc->sqld;
		for (i = 0; i < n; i++, col++)
		{
			col->sqldata += offset;
			if (col->sqltype == CLOCATORTYPE ||
				col->sqltype == SQLTEXT ||
				col->sqltype == SQLBYTES)
				blob_locate((Blob *)col->sqldata, BLOB_DEFAULT);
#ifdef ESQLC_IUSTYPES
			else if (col->sqltype == CLVCHARPTRTYPE)
			{
				void *data = 0;
				ifx_var_flag(&data, 1);
				col->sqldata = (char *)data;	/*=C++=*/
			}
#endif /* ESQLC_IUSTYPES */
			col->sqlind = indarray++;
			*col->sqlind = 0;
		}
	}

	return(space);
}

/* sql_release() -- release the space allocated by sql_describe() */
void sql_release(Sqlda *desc, void *buffer, int del_blob_file)
{
	size_t i;
	size_t n;
	Sqlva          *col;

	n = desc->sqld;
	for (i = 0, col = desc->sqlvar; i < n; i++, col++)
	{
		if (col->sqltype == CLOCATORTYPE ||
			col->sqltype == SQLTEXT ||
			col->sqltype == SQLBYTES)
			blob_release((Blob *)col->sqldata, del_blob_file);
#ifdef ESQLC_IUSTYPES
		else if (col->sqltype == CLVCHARPTRTYPE)
			ifx_var_dealloc((void **)col->sqldata);
#endif /* ESQLC_IUSTYPES */
	}
	free(buffer);
}
