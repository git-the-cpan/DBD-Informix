/*
@(#)File:            $RCSfile: esqlcver.ec,v $
@(#)Version:         $Revision: 1.1 $
@(#)Last changed:    $Date: 1998/11/05 17:49:05 $
@(#)Purpose:         Verify that library is built with correct version of ESQL/C
@(#)Author:          J Leffler
@(#)Copyright:       (C) JLSS 1998
@(#)Product:         $Product: DBD::Informix Version 0.95b2 (1999-12-30) $
*/

/*TABSTOP=4*/

#include "esqlutil.h"

#ifndef lint
static const char rcs[] = "@(#)$Id: esqlcver.ec,v 1.1 1998/11/05 17:49:05 jleffler Exp $";
#endif

int ESQLC_VERSION_CHECKER(void)
{
	return(ESQLC_VERSION);
}
