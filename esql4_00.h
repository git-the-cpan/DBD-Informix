/*
@(#)Purpose:         Function prototypes for ESQL/C Version 4.00
@(#)Author:          J Leffler
@(#)Copyright:       1992-93,1995-97 Jonathan Leffler (JLSS)
@(#)Copyright:       2002            IBM
@(#)Product:         Informix Database Driver for Perl Version 1.03.PC1 (2002-11-21)
*/

/*TABSTOP=4*/

/*
** Function prototypes for functions found in:
** Informix ESQL/C application-engine interface library Version 4.00.
** List of names derived from output of "strings $INFORMIXDIR/lib/esqlc"
** iec_stop() is called by WHENEVER ERROR STOP.
*/

#ifndef ESQL4_00_H
#define ESQL4_00_H

#ifdef MAIN_PROGRAM
#ifndef lint
static const char esql4_00_h[] = "@(#)$Id: esql4_00.h,v 100.1 2002/02/08 22:49:09 jleffler Exp $";
#endif	/*lint */
#endif	/*MAIN_PROGRAM */

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

#include "esql4_10.h"

extern int      sqgetdbs(int *ret_fcnt,
                         char **fnames,
                         int fnsize,
                         char *farea,
                         int fasize);

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif	/* ESQL4_00_H */
