/*
@(#)Purpose:         ESQL/C Utility Functions
@(#)Author:          J Leffler
@(#)Copyright:       1995-99 Jonathan Leffler (JLSS)
@(#)Copyright:       2002    IBM
@(#)Product:         IBM Informix Database Driver for Perl Version 2003.03.0400 (2003-03-04)
*/

/*TABSTOP=4*/

#ifndef ESQLUTIL_H
#define ESQLUTIL_H

#ifdef MAIN_PROGRAM
#ifndef lint
static const char esqlutil_h[] = "@(#)$Id: esqlutil.h,v 100.1 2002/02/08 22:49:25 jleffler Exp $";
#endif	/* lint */
#endif	/* MAIN_PROGRAM */

#include <stdio.h>
#include "esqlc.h"

/*
** Code which depends on ESQL/C version should embed a call to
** ESQL_VERSION_CHECKER().  The code assumes an ANSI C Preprocessor.
** The return value is the actual ESQL/C version (920 for 9.20).
*/
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
extern void dump_blob(FILE *fp, const char *tag, const Blob *blob);
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
/* sql_formaterror() -- format error message based on data in global sqlca */
extern void sql_formaterror(char *buffer, size_t buflen);

/*
** sql_tabid -- return tabid of table, regardless of database type, etc.
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
**
** sql_procid -- return procid of procedure, regardless of database
** type, etc.  This is analogous to sql_tabid() and uses statement IDs
** p_sql_procid_q002 and c_sql_procid_q002.
**
** The sql_mktablename() and sqlmkdbasename() functions format the
** components of a table and database name into a string.  If the owner,
** or dbase or server information is not available, pass a null pointer.
** The functions place the data in the buffer identified by output and
** outlen, and return a pointer to the output buffer if successful, or a
** pointer to null if there is not enough room or some other failure.
*/

extern long     sql_tabid(const char *table, const char *owner,
						  const char *dbase, const char *server);
extern char    *sql_mktablename(const char *table, const char *owner,
								const char *dbase, char *output, size_t outlen);
extern char    *sql_mkdbasename(const char *dbase, const char *server,
								char *output, size_t outlen);
extern long     sql_procid(const char *proc, const char *owner,
						  const char *dbase, const char *server);

#endif	/* ESQLUTIL_H */
