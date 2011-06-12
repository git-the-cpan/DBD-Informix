/*
@(#)File:           $RCSfile: kludge.c,v $
@(#)Version:        $Revision: 1.8 $
@(#)Last changed:   $Date: 2005/10/10 07:41:26 $
@(#)Purpose:        Library support for KLUDGE macro
@(#)Author:         J Leffler
@(#)Copyright:      (C) JLSS 1995,1997-98,2003,2005
@(#)Product:        IBM Informix Database Driver for Perl DBI Version 2011.0612 (2011-06-12)
*/

/*TABSTOP=4*/

#ifdef KLUDGE_VERBOSE
#include <stdio.h>
#else
#include <string.h>
#endif /* KLUDGE_VERBOSE */

#include "kludge.h"

static const char rcs[] = "@(#)$Id: kludge.c,v 1.8 2005/10/10 07:41:26 jleffler Exp $";

/* Report on kludges used at run-time */
void kludge_use(const char *str)
{
#ifdef KLUDGE_VERBOSE
	/* Condition is vacuous, but prevents rcs from being optimized away */
	if (rcs != 0)
		fprintf(stderr, "%s\n", str);
#else
	if (rcs == (char *)0)
		(void)strcmp(str, rcs);
#endif /* KLUDGE_VERBOSE */
}
