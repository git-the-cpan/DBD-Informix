/*
@(#)Purpose:         JLSS Functions to manipulate DECIMAL values
@(#)Author:          J Leffler
@(#)Copyright:       1996-99 Jonathan Leffler (JLSS)
@(#)Copyright:       2002    IBM
@(#)Product:         IBM Informix Database Driver for Perl Version 2003.03.0401 (2003-03-04)
*/

/*TABSTOP=4*/

#ifndef DECSCI_H
#define DECSCI_H

#ifdef MAIN_PROGRAM
#ifndef lint
static const char decsci_h[] = "@(#)$Id: decsci.h,v 100.2 2002/12/06 22:18:25 jleffler Exp $";
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
