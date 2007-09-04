/*
@(#)File:           $RCSfile: jtypes.c,v $
@(#)Version:        $Revision: 2007.2 $
@(#)Last changed:   $Date: 2007/08/26 15:50:47 $
@(#)Purpose:        Substitute for RTYPALIGN and RTYPMSIZE
@(#)Author:         J Leffler
@(#)Copyright:      (C) JLSS 1995,1997-98,2001,2003,2005,2007
@(#)Product:        IBM Informix Database Driver for Perl DBI Version 2007.0903 (2007-09-03)
*/

/*TABSTOP=4*/

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif /* HAVE_CONFIG_H */

/* DO_NOT_USE_STDERR_H is primarily for Perl + DBI + DBD::Informix */

#include <stdio.h>
#ifndef DO_NOT_USE_STDERR_H
#include "stderr.h"
#endif /* DO_NOT_USE_STDERR_H */
#include "esqlc.h"
#include "esqlutil.h"

#ifndef lint
static const char rcs[] = "@(#)$Id: jtypes.c,v 2007.2 2007/08/26 15:50:47 jleffler Exp $";
#endif

/* Return memory size for type */
int             jtypmsize(int type, int len)
{
	int    size;

	switch (type)
	{

#ifdef SQLLVARCHAR
	case SQLLVARCHAR:
	case SQLSET:
	case SQLMULTISET:
	case SQLLIST:
	case SQLROW:
	case CLVCHARPTRTYPE:
		size = sizeof(void *);
		break;
#endif /* SQLLVARCHAR */

#ifdef SQLNCHAR
	case SQLNCHAR:
#endif	/* SQLNCHAR */
	case CFIXCHARTYPE:
	case SQLCHAR:
	case CCHARTYPE:
	case CSTRINGTYPE:
		size = len + 1;
		break;

#ifdef SQLNVCHAR
	case SQLNVCHAR:
#endif	/* SQLNVCHAR */
	case SQLVCHAR:
	case CVCHARTYPE:
		size = VCMAX(len) + 1;
		break;

	case SQLSMINT:
	case CSHORTTYPE:
		size = sizeof(ixInt2);
		break;

	case SQLDATE:
	case SQLINT:
	case SQLSERIAL:
	case CLONGTYPE:
	case CDATETYPE:
		size = sizeof(ixInt4);
		break;

	case SQLSMFLOAT:
	case CFLOATTYPE:
		size = sizeof(float);
		break;

	case SQLFLOAT:
	case CDOUBLETYPE:
		size = sizeof(double);
		break;

	case SQLMONEY:
	case SQLDECIMAL:
	case CDECIMALTYPE:
	case CMONEYTYPE:
		size = sizeof(Decimal);
		break;

	case CINTTYPE:
		size = sizeof(ixMint);
		break;

	case SQLDTIME:
	case CDTIMETYPE:
		size = sizeof(Datetime);
		break;

	case SQLINTERVAL:
	case CINVTYPE:
		size = sizeof(Interval);
		break;

	case SQLBYTES:
	case SQLTEXT:
	case CLOCATORTYPE:
	case CFILETYPE:
		size = sizeof(Blob);
		break;

	default:
#ifndef DO_NOT_USE_STDERR_H
		err_remark("jtypsize: unknown type number %d (assume zero size)\n", type);
#endif	/* DO_NOT_USE_STDERR_H */
		size = 0;
		break;
	}
	return(size);
}

/* Return get proper byte alignment for various types */
int             jtypalign(int offset, int type)
{
	int             align;
	struct
	{
		char            ic;
		ixInt2          i2;
	}               i;
	struct
	{
		char            ic;
		ixMint          i2;
	}               mi;
	struct
	{
		char            lc;
		ixInt4          l2;
	}               l;
	struct
	{
		char            fc;
		float           f2;
	}               f;
	struct
	{
		char            dc;
		double          d2;
	}               d;
	struct
	{
		char            nc;
		Decimal         n2;
	}               n;
	struct
	{
		char            dtc;
		Datetime        dt2;
	}               dt;
	struct
	{
		char            inc;
		Interval        in2;
	}               in;
	struct
	{
		char            blc;
		Blob            bl2;
	}               bl;
	struct
	{
		char             lvc;
		void            *lv2;
	}               lv;

	switch (type)
	{
	case SQLSMINT:
	case CSHORTTYPE:
		align = ((char *)&i.i2) - &i.ic;
		break;

	case CINTTYPE:
		align = ((char *)&mi.i2) - &mi.ic;
		break;

	case SQLINT:
	case SQLSERIAL:
	case SQLDATE:
	case CLONGTYPE:
	case CDATETYPE:
		align = ((char *)&l.l2) - &l.lc;
		break;

	case SQLSMFLOAT:
	case CFLOATTYPE:
		align = ((char *)&f.f2) - &f.fc;
		break;

	case SQLFLOAT:
	case CDOUBLETYPE:
		align = ((char *)&d.d2) - &d.dc;
		break;

	case SQLDTIME:
	case CDTIMETYPE:
		align = ((char *)&dt.dt2) - &dt.dtc;
		break;

	case SQLINTERVAL:
	case CINVTYPE:
		align = ((char *)&in.in2) - &in.inc;
		break;

	case SQLMONEY:
	case SQLDECIMAL:
	case CDECIMALTYPE:
	case CMONEYTYPE:
		align = ((char *)&n.n2) - &n.nc;
		break;

	case CLOCATORTYPE:
	case SQLBYTES:
	case SQLTEXT:
	case CFILETYPE:
		align = ((char *)&bl.bl2) - &bl.blc;
		break;

#ifdef SQLLVARCHAR
	case SQLLVARCHAR:
	case SQLSET:
	case SQLMULTISET:
	case SQLLIST:
	case SQLROW:
	case CLVCHARPTRTYPE:
		align = ((char *)&lv.lv2) - &lv.lvc;
		break;
#endif /* SQLLVARCHAR */

	case CCHARTYPE:
	case CFIXCHARTYPE:
	case CSTRINGTYPE:
	case SQLCHAR:
	case CVCHARTYPE:
	case SQLVCHAR:
#ifdef SQLNCHAR
	case SQLNCHAR:
#endif	/* SQLNCHAR */
#ifdef SQLNVCHAR
	case SQLNVCHAR:
#endif	/* SQLNVCHAR */
		align = 1;
		break;

	default:
#ifndef DO_NOT_USE_STDERR_H
		err_remark("jtypalign: unknown type number %d (assume 'double' alignment)\n", type);
#endif	/* DO_NOT_USE_STDERR_H */
		align = ((char *)&d.d2) - &d.dc;
		break;
	}

	--align;
	return((offset + align) & ~align);
}
