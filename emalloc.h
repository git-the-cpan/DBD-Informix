/*
@(#)File:           $RCSfile: emalloc.h,v $
@(#)Version:        $Revision: 5.7 $
@(#)Last changed:   $Date: 2003/09/08 18:29:12 $
@(#)Purpose:        Interfaces to routines in emalloc.c
@(#)Author:         J Leffler
@(#)Copyright:      (C) JLSS 1990,1992-93,1996-97,2001,2003
@(#)Product:        IBM Informix Database Driver for Perl DBI Version 2005.01 (2005-03-14)
*/

/*TABSTOP=4*/

#ifndef EMALLOC_H
#define EMALLOC_H

#ifdef MAIN_PROGRAM
#ifndef lint
static const char emalloc_h[] = "@(#)$Id: emalloc.h,v 5.7 2003/09/08 18:29:12 jleffler Exp $";
#endif	/* lint */
#endif	/* MAIN_PROGRAM */

#include <stdlib.h>

/* -- Macro Definitions	*/

/* Make it easier to avoid using emalloc() et al */
#ifdef USE_REAL_MALLOC
#define MALLOC(n)		malloc((n))
#define CALLOC(n, s)	calloc((n), (s))
#define REALLOC(s, n)	realloc((s), (n))
#define FREE(s)			free((s))
#define STRDUP(s)		strdup((s))
#endif /* USE_REAL_MALLOC */

#ifndef MALLOC
#define MALLOC(n)		emalloc((size_t)(n))
#endif /* MALLOC */

#ifndef CALLOC
#define CALLOC(n, s)	ecalloc((size_t)(n), (size_t)(s))
#endif /* CALLOC */

#ifndef REALLOC
#define REALLOC(s, n)	erealloc((void *)(s), (size_t)(n))
#endif /* REALLOC */

#ifndef FREE
#define FREE(s)			efree((void *)(s))
#endif /* FREE */

#ifndef STRDUP
#define STRDUP(s)		estrdup((s))
#endif /* STRDUP */

#ifndef NOSTRICT
#ifdef lint
#define NOSTRICT(type, exp)	((type)((exp) ? 0 : 0))
#else
#define NOSTRICT(type, exp)	((type)(exp))
#endif
#endif /* NOSTRICT */

/* -- Declarations */

extern void     *emalloc(size_t nbytes);
extern void     *ecalloc(size_t nitems, size_t size);
extern void     *erealloc(void *space, size_t nbytes);
extern void      efree(void *space);
extern char     *estrdup(const char *str);

#endif	/* EMALLOC_H */
