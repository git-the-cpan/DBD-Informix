/*
@(#)File:            $RCSfile: esql7_20.h,v $
@(#)Version:         $Revision: 1.2 $
@(#)Last changed:    $Date: 1997/06/02 16:24:26 $
@(#)Purpose:         Function prototypes for ESQL/C Versions 7.20..7.22
@(#)Author:          J Leffler
@(#)Copyright:       (C) JLSS 1997
@(#)Product:         $Product: DBD::Informix Version 0.61_02 (1998-12-14) $
*/

/*TABSTOP=4*/

#ifndef ESQL7_20_H
#define ESQL7_20_H

#ifdef MAIN_PROGRAM
#ifndef lint
static const char esql7_20_h[] = "@(#)$Id: esql7_20.h,v 1.2 1997/06/02 16:24:26 johnl Exp $";
#endif	/* lint */
#endif	/* MAIN_PROGRAM */

/*
** The 7.2x ESQL/C compiler can generate calls to the following functions
** but sqlhdr.h does not define prototypes for these functions.  Although
** byfill() is declared in esqllib.h, this is not normally needed by 7.x
** ESQL/C compilations (though if byfill() is missing, there is room to
** think that other functions may be missing too).
*/
extern void  byfill(char *to, int len, char ch);
extern void  iec_dclcur(char *, char **, int, int, int);
extern void  iec_free(char *);
extern void  iec_hostbind(struct hostvar_struct *, int, int, int, int, char *);
extern void  iec_ibind(int, char *, int, int, char *, int);
extern void  iec_obind(int, char *, int, int, char *, int);
extern void *iec_alloc_isqlda(int);
extern void *iec_alloc_osqlda(int);

#endif	/* ESQL7_20_H */
