/*
@(#)File:            $RCSfile: decsci.h,v $
@(#)Version:         $Revision: 3.3 $
@(#)Last changed:    $Date: 2003/04/24 18:04:01 $
@(#)Purpose:         JLSS Functions to manipulate DECIMAL values
@(#)Author:          J Leffler
@(#)Copyright:       (C) JLSS 1996-99,2001-03
@(#)Product:         IBM Informix Database Driver for Perl DBI Version 2005.01 (2005-03-14)
*/

/*TABSTOP=4*/

#ifndef DECSCI_H
#define DECSCI_H

#ifdef MAIN_PROGRAM
#ifndef lint
static const char decsci_h[] = "@(#)$Id: decsci.h,v 3.3 2003/04/24 18:04:01 jleffler Exp $";
#endif	/* lint */
#endif	/* MAIN_PROGRAM */

#include <stddef.h>
#include "decimal.h"

#define DECEXPZERO	-64		/* Exponent used in zero; dec_ndgts == 0 too */
#define DECEXPMIN	-64		/* Minimum permissible exponent */
#define DECEXPMAX	+63		/* Maximum permissible exponent */
#define DECDGTMIN	0		/* Minimum digit value */
#define DECDGTMAX	99		/* Maximum digit value */
#define DECPOSPOS	+1		/* Indicates positive value */
#define DECPOSNEG	0		/* Indicates negative value */

#define DECNULL_INITIALIZER	{ 0, DECPOSNULL, 0, { 0 /* 16 zeroes */ } }
#define DECZERO_INITIALIZER	{ DECEXPZERO, DECPOSPOS, 0, { 0 /* 16 zeroes */ } }

extern int decabs(const dec_t *x, dec_t *r1);
extern int decneg(const dec_t *x, dec_t *r1);
extern int decpower(const dec_t *x, int n, dec_t *r1);
extern int decsqrt(dec_t *x, dec_t *r1);

#ifdef USE_DEPRECATED_DECSCI_FUNCTIONS
/*
** NB: the routines decfix(), decsci(), deceng() are not thread-safe
** and share common return storage.  Their use is totally deprecated.
** Use the alternatives: dec_fix(), dec_sci(), dec_eng().
*/
extern char *decfix(const dec_t *d, int ndigit, int plus);
extern char *decsci(const dec_t *d, int ndigit, int plus);
extern char *deceng(const dec_t *d, int ndigit, int plus, int cw);
#endif /* USE_DEPRECATED_DECSCI_FUNCTIONS */

extern int dec_fix(const dec_t *d, int ndigit, int plus, char *buffer, size_t buflen);
extern int dec_sci(const dec_t *d, int ndigit, int plus, char *buffer, size_t buflen);
extern int dec_eng(const dec_t *d, int ndigit, int plus, int cw, char *buffer, size_t buflen);

extern int dec_fmt(const dec_t *d, int sqllen, int fmtcode, char *buffer, size_t buflen); 
extern int decfmt(const dec_t *d, int sqllen, int fmtcode, char *buffer, size_t buflen); 

extern int dec_chk(dec_t *d, int sqllen);
extern int dec_set(dec_t *d, int sqllen);

extern int dec_is_zero(dec_t *d);
extern int dec_is_null(dec_t *d);

extern void dec_setzero(dec_t *d);
extern void dec_setnull(dec_t *d);
extern void dec_verify(dec_t *d);

/* Macro overrides for functions */
#define dec_setnull(d)	((void)((d)->dec_pos = DECPOSNULL))
#define dec_is_null(d)	((d)->dec_pos == DECPOSNULL)

#endif	/* DECSCI_H */
