/*
@(#)File:            $RCSfile: esql4_00.h,v $
@(#)Version:         $Revision: 1.7 $
@(#)Last changed:    $Date: 1997/06/02 16:24:26 $
@(#)Purpose:         Function prototypes for ESQL/C Version 4.00
@(#)Author:          J Leffler
@(#)Copyright:       (C) JLSS 1992-93,1995-97
@(#)Product:         DBD::Informix Version 0.97002 (2000-01-24)
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
static const char esql4_00_h[] = "@(#)$Id: esql4_00.h version /main/7 1997-06-02 16:24:26 $";
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
