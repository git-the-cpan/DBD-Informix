/*
@(#)File:            $RCSfile: esql7_20.h,v $
@(#)Version:         $Revision: 1.3 $
@(#)Last changed:    $Date: 1999/08/31 12:43:43 $
@(#)Purpose:         Function prototypes for ESQL/C Versions 7.20..7.22
@(#)Author:          J Leffler
@(#)Copyright:       (C) JLSS 1997
@(#)Product:         $Product: DBD::Informix Version 0.97.PC1 (2000-01-18) $
*/

/*TABSTOP=4*/

#ifndef ESQL7_20_H
#define ESQL7_20_H

#ifdef MAIN_PROGRAM
#ifndef lint
static const char esql7_20_h[] = "@(#)$Id: esql7_20.h,v 1.3 1999/08/31 12:43:43 jleffler Exp $";
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
/* Placing this here is not ideal, but usually causes no trouble */
struct hostvar_struct;
extern void  iec_hostbind(struct hostvar_struct *, int, int, int, int, char *);
extern void  iec_ibind(int, char *, int, int, char *, int);
extern void  iec_obind(int, char *, int, int, char *, int);
extern void *iec_alloc_isqlda(int);
extern void *iec_alloc_osqlda(int);

#endif	/* ESQL7_20_H */
