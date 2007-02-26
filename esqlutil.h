/*
@(#)File:           $RCSfile: esqlutil.h,v $
@(#)Version:        $Revision: 2006.1 $
@(#)Last changed:   $Date: 2006/01/30 21:19:47 $
@(#)Purpose:        ESQL/C Utility Functions
@(#)Author:         J Leffler
@(#)Copyright:      (C) JLSS 1995-2006
@(#)Product:        IBM Informix Database Driver for Perl DBI Version 2007.0226 (2007-02-25)
*/

/*TABSTOP=4*/

#ifndef ESQLUTIL_H
#define ESQLUTIL_H

#ifdef MAIN_PROGRAM
#ifndef lint
static const char esqlutil_h[] = "@(#)$Id: esqlutil.h,v 2006.1 2006/01/30 21:19:47 jleffler Exp $";
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
extern char *sqltypename(ixInt2 coltype, ixInt4 collen, char *buffer, size_t buflen);
extern char *iustypename(ixInt2 coltype, ixInt4 collen, ixInt4 xtd_id, char *buffer, size_t buflen);
extern const char *sqltype(ixInt2 coltype, ixInt4 collen);	/* Deprecated! */
extern int sqltypemode(int mode);

/* -- Future direction -- */
/*
#include "dumpesql.h"
*/
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
extern void dump_sqlda(FILE *fp, const char *tag, const Sqlda *desc);
extern void dump_sqlva(FILE *fp, int item, const Sqlva *sqlvar);
extern void dump_value(FILE *fp, const char *tag, const value_t *vp);
extern void dump_sqldescriptor(FILE *fp, const char *tag, const char *name);

/* Simple interface for dumping the global sqlca structure */
extern void dumpsqlca(FILE *fp, const char *tag);

/*
** Alternatives to the (historically buggy) ESQL/C functions
** rtypmsize() and rtypalign()
*/
extern int jtypmsize(int type, int len);
extern int jtypalign(int offset, int type);

/* sqltoken(), iustoken() -- #include "sqltoken.h" */

/* sql_printerror() -- print error in global sqlca on specified file */
extern void sql_printerror(FILE *fp);
/* sql_formaterror() -- format error message based on data in global sqlca */
extern void sql_formaterror(char *buffer, size_t buflen);

#endif	/* ESQLUTIL_H */
