/*
@(#)Purpose:         Verify that library is built with correct version of ESQL/C
@(#)Author:          J Leffler
@(#)Copyright:       1998 Jonathan Leffler (JLSS)
@(#)Copyright:       2002 IBM
@(#)Product:         IBM Informix Database Driver for Perl Version 2003.04 (2003-03-05)
*/

/*TABSTOP=4*/

#include "esqlutil.h"

#ifndef lint
static const char rcs[] = "@(#)$Id: esqlcver.ec,v 100.1 2002/02/08 22:49:18 jleffler Exp $";
#endif

int ESQLC_VERSION_CHECKER(void)
{
	return(ESQLC_VERSION);
}
