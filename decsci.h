/*
@(#)File:            $RCSfile: decsci.h,v $
@(#)Version:         $Revision: 1.6 $
@(#)Last changed:    $Date: 1999/05/16 04:53:33 $
@(#)Purpose:         JLSS Functions to manipulate DECIMAL values
@(#)Author:          J Leffler
@(#)Copyright:       (C) JLSS 1996-99
@(#)Product:         Informix Database Driver for Perl Version 0.97003 (2000-02-07)
*/

/*TABSTOP=4*/

#ifndef DECSCI_H
#define DECSCI_H

#ifdef MAIN_PROGRAM
#ifndef lint
static const char decsci_h[] = "@(#)$Id: decsci.h version /main/6 1999-05-16 04:53:33 $";
#endif	/* lint */
#endif	/* MAIN_PROGRAM */

#include <stddef.h>
#include "decimal.h"

extern int decabs(const dec_t *x, dec_t *r1);
extern int decneg(const dec_t *x, dec_t *r1);
extern int decpower(const dec_t *x, int n, dec_t *r1);
extern int decsqrt(dec_t *x, dec_t *r1);

/* NB: these routines are not thread-safe and share common return storage */
extern char *decfix(const dec_t *d, int ndigit, int plus);
extern char *decsci(const dec_t *d, int ndigit, int plus);
extern char *deceng(const dec_t *d, int ndigit, int plus, int cw);

extern int decfmt(const dec_t *d, int sqllen, int fmtcode, char *buffer, size_t buflen); 
extern int decchk(dec_t *d, int sqllen);
extern int decset(dec_t *d, int sqllen);

#endif	/* DECSCI_H */
