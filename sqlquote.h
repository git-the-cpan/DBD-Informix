/*
@(#)File:            $RCSfile: sqlquote.h,v $
@(#)Version:         $Revision: 2004.1 $
@(#)Last changed:    $Date: 2004/12/24 18:34:15 $
@(#)Purpose:         Convert between SQL quoted string and unquoted string
@(#)Author:          J Leffler
@(#)Copyright:       (C) JLSS 2004
@(#)Product:         IBM Informix Database Driver for Perl DBI Version 2005.01 (2005-03-14)
*/

/*TABSTOP=4*/

#ifndef SQLQUOTE_H
#define SQLQUOTE_H

#ifdef MAIN_PROGRAM
#ifndef lint
static const char sqlquote_h[] = "@(#)$Id: sqlquote.h,v 2004.1 2004/12/24 18:34:15 jleffler Exp $";
#endif	/* lint */
#endif	/* MAIN_PROGRAM */

#include <stddef.h>	/* size_t */

/*
** sql_unquote_string() - convert SQL quote enclosed string to unquoted value.
*/
extern int sql_unquote_string(char *dst, size_t dstlen, const char *src);

/*
** sql_quote_string() - convert string value to SQL quoted string value.
** Worst case scenario is N occurrences of quote in src and that
** requires 2*N+3 characters for output.
*/
extern int sql_quote_string(char *dst, size_t dstlen, const char *src, char quote);

#endif	/* SQLQUOTE_H */
