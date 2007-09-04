/*
@(#)File:           $RCSfile: decsci.h,v $
@(#)Version:        $Revision: 3.9 $
@(#)Last changed:   $Date: 2005/08/30 21:35:20 $
@(#)Purpose:        JLSS Functions to manipulate DECIMAL values
@(#)Author:         J Leffler
@(#)Copyright:      (C) JLSS 1996-99,2001-03,2005
@(#)Product:        IBM Informix Database Driver for Perl DBI Version 2007.0904 (2007-09-04)
*/

/*TABSTOP=4*/

#ifndef DECSCI_H
#define DECSCI_H

#ifdef MAIN_PROGRAM
#ifndef lint
static const char decsci_h[] = "@(#)$Id: decsci.h,v 3.9 2005/08/30 21:35:20 jleffler Exp $";
#endif	/* lint */
#endif	/* MAIN_PROGRAM */

#include <stddef.h>
#include "decimal.h"
#include "ifmxdec.h"

#define DECEXPZERO	-64		/* Exponent used in zero; dec_ndgts == 0 too */
#define DECEXPMIN	-64		/* Minimum permissible exponent */
#define DECEXPMAX	+63		/* Maximum permissible exponent */
#define DECDGTMIN	0		/* Minimum digit value */
#define DECDGTMAX	99		/* Maximum digit value */
#define DECPOSPOS	+1		/* Indicates positive value */
#define DECPOSNEG	0		/* Indicates negative value */

#define DECNULL_INITIALIZER	{ 0, DECPOSNULL, 0, { 0 /* 16 zeroes */ } }
#define DECZERO_INITIALIZER	{ DECEXPZERO, DECPOSPOS, 0, { 0 /* 16 zeroes */ } }

extern int decabs(const ifx_dec_t *x, ifx_dec_t *r1);
extern int decneg(const ifx_dec_t *x, ifx_dec_t *r1);
extern int decpower(const ifx_dec_t *x, int n, ifx_dec_t *r1);
extern int decsqrt(const ifx_dec_t *x, ifx_dec_t *r1);

extern void dec_normalize(ifx_dec_t *dp);		/* Normalize a decimal value */

#ifdef USE_DEPRECATED_DECSCI_FUNCTIONS
/*
** NB: the routines decfix(), decsci(), deceng() are not thread-safe
** and share common return storage.  Their use is totally deprecated.
** Use the alternatives: dec_fix(), dec_sci(), dec_eng().
*/
extern char *decfix(const ifx_dec_t *d, int ndigit, int plus);
extern char *decsci(const ifx_dec_t *d, int ndigit, int plus);
extern char *deceng(const ifx_dec_t *d, int ndigit, int plus, int cw);
#endif /* USE_DEPRECATED_DECSCI_FUNCTIONS */

extern int dec_fix(const ifx_dec_t *d, int ndigit, int plus, char *buffer, size_t buflen);
extern int dec_sci(const ifx_dec_t *d, int ndigit, int plus, char *buffer, size_t buflen);
extern int dec_eng(const ifx_dec_t *d, int ndigit, int plus, int cw, char *buffer, size_t buflen);

extern int dec_fmt(const ifx_dec_t *d, int sqllen, int fmtcode, char *buffer, size_t buflen); 

/* Deprecated variant of dec_fmt() */
extern int decfmt(const ifx_dec_t *d, int sqllen, int fmtcode, char *buffer, size_t buflen); 

extern int dec_chk(const ifx_dec_t *d, int sqllen);
extern int dec_set(ifx_dec_t *d, int sqllen);

extern void dec_verify(const ifx_dec_t *d);

extern int dec_mod(const ifx_dec_t *dividend, const ifx_dec_t *divisor, ifx_dec_t *result);

#endif	/* DECSCI_H */
