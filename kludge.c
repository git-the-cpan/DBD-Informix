/*
@(#)File:            $RCSfile: kludge.c,v $
@(#)Version:         $Revision: 1.5 $
@(#)Last changed:    $Date: 2003/03/07 18:59:46 $
@(#)Purpose:         Library support for KLUDGE macro
@(#)Author:          J Leffler
@(#)Copyright:       (C) JLSS 1995,1997-98,2003
@(#)Product:         IBM Informix Database Driver for Perl DBI Version 2005.01 (2005-03-14)
*/

/*TABSTOP=4*/

#include <string.h>
#include "kludge.h"

#ifndef lint
static const char rcs[] = "@(#)$Id: kludge.c,v 1.5 2003/03/07 18:59:46 jleffler Exp $";
#endif

void kludge_use(const char *str)
{
	if (rcs == (char *)0)
		(void)strcmp(rcs, str);
}
