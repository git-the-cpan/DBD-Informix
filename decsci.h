/*
@(#)File:            $RCSfile: decsci.h,v $
@(#)Version:         $Revision: 1.5 $
@(#)Last changed:    $Date: 1998/04/09 21:24:00 $
@(#)Purpose:         JLSS Functions to manipulate DECIMAL values
@(#)Author:          J Leffler
@(#)Copyright:       (C) JLSS 1996-98
@(#)Product:         $Product: DBD::Informix Version 0.62 (1999-09-19) $
*/

/*TABSTOP=4*/

#ifndef DECSCI_H
#define DECSCI_H

#ifdef MAIN_PROGRAM
#ifndef lint
static const char decsci_h[] = "@(#)$Id: decsci.h,v 1.5 1998/04/09 21:24:00 jleffler Exp $";
#endif	/* lint */
#endif	/* MAIN_PROGRAM */

#include "decimal.h"

extern int decabs(const dec_t *x, dec_t *r1);
extern int decneg(const dec_t *x, dec_t *r1);
extern int decpower(const dec_t *x, int n, dec_t *r1);
extern int decsqrt(dec_t *x, dec_t *r1);

/* NB: these routines are not thread-safe and share common return storage */
extern char *decfix(const dec_t *d, int ndigit, int plus);
extern char *decsci(const dec_t *d, int ndigit, int plus);
extern char *deceng(const dec_t *d, int ndigit, int plus, int cw);

#endif	/* DECSCI_H */
