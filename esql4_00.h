/*
@(#)File:            esql4_00.h
@(#)Version:         1.5
@(#)Last changed:    96/11/26
@(#)Purpose:         Function prototypes for ESQL/C Version 4.00
@(#)Author:          J Leffler
@(#)Copyright:       (C) JLSS 1992,1993,1995,1996
@(#)Product:         :PRODUCT:
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
static const char esql4_00_h[] = "@(#)esql4_00.h	1.5 96/11/26";
#endif	/*lint */
#endif	/*MAIN_PROGRAM */

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

#include "esql4_10.h"

#ifdef __STDC__

extern int      sqgetdbs(int *ret_fcnt,
                         char **fnames,
                         int fnsize,
                         char *farea,
                         int fasize);

#else

extern int      sqgetdbs();

#endif	/* __STDC__ */

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif	/* ESQL4_00_H */
