/*
@(#)File:            $RCSfile: esqlutil.h,v $
@(#)Version:         $Revision: 2.1 $
@(#)Last changed:    $Date: 1998/11/05 18:39:10 $
@(#)Purpose:         ESQL/C Utility Functions
@(#)Author:          J Leffler
@(#)Copyright:       (C) JLSS 1995-98
@(#)Product:         $Product: DBD::Informix Version 0.61_02 (1998-12-14) $
*/

/*TABSTOP=4*/

#ifndef ESQLUTIL_H
#define ESQLUTIL_H

#ifdef MAIN_PROGRAM
#ifndef lint
static const char esqlutil_h[] = "@(#)$Id: esqlutil.h,v 2.1 1998/11/05 18:39:10 jleffler Exp $";
#endif	/* lint */
#endif	/* MAIN_PROGRAM */

#include <stdio.h>
#include "esqlc.h"

/* Code which depends on ESQL/C version should embed a call to ESQL_VERSION_CHECKER() */
#define ESQLC_PASTE2(x, y)	x ## y
#define ESQLC_PASTE(x, y)	ESQLC_PASTE2(x, y)
#define ESQLC_VERSION_CHECKER	ESQLC_PASTE(esqlc_version_, ESQLC_VERSION)
extern int ESQLC_VERSION_CHECKER(void);

/*
** The sqltype() routine is deprecated because it is not thread safe.
** It is a simple call onto sqltypename() routine with a static buffer.
** The sqltypename() routine assumes is has a buffer of at least
** SQLTYPENAME_BUFSIZ bytes in which too work.
** For both routines, the return address is the start of the buffer.
** The sqltypemode() function returns the old formatting mode and sets
** a new formatting mode for sqltypename().
** If the mode is set to 1, then sqltypename() produces an abbreviated
** type format for DATETIME and INTERVAL types when the start and end
** components are the same.  For example:
** INTERVAL HOUR(6) TO HOUR <==> INTERVAL HOUR(6).
** By default, or if the mode is set to anything other than 1,
** it uses the standard Informix type name with repeated component.
**
*/

#define SQLTYPENAME_BUFSIZ sizeof("DISTINCT INTERVAL MINUTE(2) TO FRACTION(5)")
extern char *sqltypename(int coltype, int collen, char *buffer);
extern char *iustypename(int coltype, int collen, int xtd_id, char *buffer, size_t buflen);
extern const char *sqltype(int coltype, int collen);	/* Deprecated! */
extern int sqltypemode(int mode);

/*
** The dump_xyz routines are a systematic way of dumping the
** information in the Informix compound types onto the specified file.
** Each routine identifies its output with the user-specified tag.
*/
extern void dump_blob(FILE *fp, const char *tag, const loc_t *blob);
extern void dump_datetime(FILE *fp, const char *tag, const dtime_t *dp);
extern void dump_decimal(FILE *fp, const char *tag, const dec_t *dp);
extern void dump_interval(FILE *fp, const char *tag, const intrvl_t *ip);
extern void dump_sqlca(FILE *fp, const char *tag, const Sqlca *psqlca);
extern void dump_sqlda(FILE *fp, const char *tag, const Sqlda *sqlda);
extern void dump_sqlva(FILE *fp, int item, const Sqlva *sqlva);
extern void dump_value(FILE *fp, const char *tag, const value_t *vp);

/* Simple interface for dumping the global sqlca structure */
extern void dumpsqlca(FILE *fp, const char *tag);

/*
** Alternatives to the (historically buggy) ESQL/C functions
** rtypmsize() and rtypalign()
*/
extern int jtypmsize(int type, int len);
extern int jtypalign(int offset, int type);

/*
** sqltoken() -- Extract an SQL token from the given string
** Return value points to start of token; *end points one beyond end
** If *end == return value, there are no more tokens in the string
** Understands and ignores {...}, # and -- comments.  Understands
** character strings, and unsigned numbers with optional fractions and
** exponents -- any leading sign is treated as a separate token.
*/
extern char *sqltoken(char *string, char **end);

/* sql_printerror() -- print error in global sqlca on specified file */
extern void sql_printerror(FILE *fp);

/* sql_tabid -- return tabid of table, regardless of database type, etc.
**
** NB: returns -1 on any error; SQL error info is in sqlca record.  The
** owner name can be in quotes or not, and the results may differ
** depending on whether the owner is quoted or not.  It does not matter
** whether the quotes are single or double.  If the first character is a
** quote, the last character is assumed to be the matching quote.  The
** table name must be a valid string; the other parts can be empty
** strings or null pointers.  This code does not handle delimited
** identifiers as table names.  It uses statement IDs p_sql_tabid_q001,
** p_sql_tabid_q002 and c_sql_tabid_q002.
** The function used functions vstrcpy(), strlower(), strupper() from jlss.h.
*/

extern long     sql_tabid(const char *table, const char *owner,
						  const char *dbase, const char *server);
extern char    *sql_mktablename(const char *table, const char *owner,
								const char *dbase, char *output, size_t outlen);
extern char    *sql_mkdbasename(const char *dbase, const char *server,
								char *output, size_t outlen);

#endif	/* ESQLUTIL_H */
