/*
@(#)File:            $RCSfile: esqlcver.ec,v $
@(#)Version:         $Revision: 1.1 $
@(#)Last changed:    $Date: 1998/11/05 17:49:05 $
@(#)Purpose:         Verify that library is built with correct version of ESQL/C
@(#)Author:          J Leffler
@(#)Copyright:       (C) JLSS 1998
@(#)Product:         IBM Informix Database Driver for Perl Version 1.00.PC2 (2002-02-01)
*/

/*TABSTOP=4*/

#include "esqlutil.h"

#ifndef lint
static const char rcs[] = "@(#)$Id: esqlcver.ec version /main/1 1998-11-05 17:49:05 $";
#endif

int ESQLC_VERSION_CHECKER(void)
{
	return(ESQLC_VERSION);
}
