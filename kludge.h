/*
@(#)File:            $RCSfile: kludge.h,v $
@(#)Version:         $Revision: 1.5 $
@(#)Last changed:    $Date: 1999/08/20 20:36:29 $
@(#)Purpose:         Provide support for KLUDGE macro
@(#)Author:          J Leffler
@(#)Copyright:       (C) JLSS 1995,1997-99
@(#)Product:         $Product: DBD::Informix Version 0.62 (1999-09-19) $
*/

/*TABSTOP=4*/

#ifndef KLUDGE_H
#define KLUDGE_H

#ifdef MAIN_PROGRAM
#ifndef lint
static const char kludge_h[] = "@(#)$Id: kludge.h,v 1.5 1999/08/20 20:36:29 jleffler Exp $";
#endif	/* lint */
#endif	/* MAIN_PROGRAM */

/*
 * The KLUDGE macro is enabled by default.
 * It can be disabled by specifying -DKLUDGE_DISABLE
 */

#ifdef KLUDGE_DISABLE

#define KLUDGE(x)	((void)0)

#else

/*
 * The Solaris C compiler without either -O or -g removes unreferenced
 * strings, which defeats the purpose of the KLUDGE macro.  With such
 * compilers, use -DKLUDGE_FORCE to force the variable to be used.
 */

#ifdef lint
#define KLUDGE_FORCE
#endif /* lint */

/*
** The GNU C Compiler will complain about unused variables if told to
** do so.  Setting KLUDGE_FORCE ensures that it doesn't complain about
** any kludges.  On the other hand, it is better to leave kludges
** visible during the compilation, so don't set KLUDGE_FORCE if
** __GNUC__ is defined.
*/

/*
 * Example use: KLUDGE("Fix macro to accept arguments with commas");
 * Note that the argument is now a string.  An alternative (and
 * previously used) design is to have the argument as a non-string:
 *              KLUDGE(Fix macro to accept arguments with commas);
 * This allows it to work with traditional compilers but runs foul of
 * the absence of string concatenation, and you have to avoid commas
 * in the reason string, etc.
 */

#define KLUDGE_DEC	static const char kludge[]

extern void kludge_use(const char *str);
#define KLUDGE(x)	{ KLUDGE_DEC = "@(#)KLUDGE: " x; KLUDGE_USE(kludge); }

#ifdef KLUDGE_FORCE
#define KLUDGE_USE(x)	kludge_use(x)
#else
#define KLUDGE_USE(x)	((void)0)
#endif /* KLUDGE_FORCE */

#endif /* KLUDGE_DISABLE */

#endif /* KLUDGE_H */
