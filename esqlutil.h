/*
@(#)File:            $RCSfile: esqlutil.h,v $
@(#)Version:         $Revision: 1.7 $
@(#)Last changed:    $Date: 1997/04/29 15:09:25 $
@(#)Purpose:         ESQL/C Utility Functions
@(#)Author:          J Leffler
@(#)Copyright:       (C) JLSS 1995-97
@(#)Product:         $Product: DBD::Informix Version 0.58 (1998-01-15) $
*/

/*TABSTOP=4*/

#ifndef ESQLUTIL_H
#define ESQLUTIL_H

#ifdef MAIN_PROGRAM
#ifndef lint
static const char esqlutil_h[] = "@(#)$Id: esqlutil.h,v 1.7 1997/04/29 15:09:25 johnl Exp $";
#endif	/* lint */
#endif	/* MAIN_PROGRAM */

#include <stdio.h>
#include "esqlc.h"

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

#define SQLTYPENAME_BUFSIZ sizeof("INTERVAL MINUTE(2) TO FRACTION(5)")
extern char *sqltypename(int coltype, int collen, char *buffer);
extern const char *sqltype(int coltype, int collen);
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
extern void dump_value(FILE *fp, const char *tag, const value_t *vp);

/* Simple interface for dumping the global sqlca structure */
extern void dumpsqlca(FILE *fp, const char *tag);

/*
** Alternatives to the (historically buggy) ESQL/C functions
** rtypmsize() and rtypalign()
*/
extern int jtypmsize(int type, int len);
extern int jtypalign(int offset, int type);

#endif	/* ESQLUTIL_H */
