/*
@(#)File:           $RCSfile: debug.h,v $
@(#)Version:        $Revision: 3.7 $
@(#)Last changed:   $Date: 2011/04/17 22:01:21 $
@(#)Purpose:        Definitions for the debugging system
@(#)Author:         J Leffler
@(#)Copyright:      (C) JLSS 1990-93,1997-99,2003,2005,2008
@(#)Product:        IBM Informix Database Driver for Perl DBI Version 2011.0612 (2011-06-12)
*/

#ifndef DEBUG_H
#define DEBUG_H

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif /* HAVE_CONFIG_H */

/*
** Usage:  TRACE((level, fmt, ...))
** "level" is the debugging level which must be operational for the output
** to appear. "fmt" is a printf format string. "..." is whatever extra
** arguments fmt requires (possibly nothing).
** The non-debug macro means that the code is validated but never called.
** -- See chapter 8 of 'The Practice of Programming', by Kernighan and Pike.
*/
#ifdef DEBUG
#define TRACE(x)    db_print x
#else
#define TRACE(x)    do { if (0) db_print x; } while (0)
#endif /* DEBUG */

#ifndef lint
#ifdef DEBUG
/* This string can't be made extern - multiple definition in general */
static const char jlss_id_debug_enabled[] = "@(#)*** DEBUG ***";
#endif /* DEBUG */
#ifdef MAIN_PROGRAM
const char jlss_id_debug_h[] = "@(#)$Id: debug.h,v 3.7 2011/04/17 22:01:21 jleffler Exp $";
#endif /* MAIN_PROGRAM */
#endif /* lint */

#include <stdio.h>

extern int      db_getdebug(void);
extern int      db_newindent(void);
extern int      db_oldindent(void);
extern int      db_setdebug(int level);
extern int      db_setindent(int i);
extern void     db_print(int level, const char *fmt,...);
extern void     db_setfilename(const char *fn);
extern void     db_setfileptr(FILE *fp);
extern FILE    *db_getfileptr(void);

/* Semi-private function */
extern const char *db_indent(void);

/**************************************\
** MULTIPLE DEBUGGING SUBSYSTEMS CODE **
\**************************************/

/*
** Usage:  MDTRACE((subsys, level, fmt, ...))
** "subsys" is the debugging system to which this statement belongs.
** The significance of the subsystems is determined by the programmer,
** except that the functions such as db_print refer to subsystem 0.
** "level" is the debugging level which must be operational for the
** output to appear. "fmt" is a printf format string. "..." is
** whatever extra arguments fmt requires (possibly nothing).
** The non-debug macro means that the code is validated but never called.
*/
#ifdef DEBUG
#define MDTRACE(x)  db_mdprint x
#else
#define MDTRACE(x)  do { if (0) db_mdprint x; } while (0)
#endif /* DEBUG */

extern int      db_mdgetdebug(int subsys);
extern int      db_mdparsearg(char *arg);
extern int      db_mdsetdebug(int subsys, int level);
extern void     db_mdprint(int subsys, int level, const char *fmt,...);
extern void     db_mdsubsysnames(char * const *names);

#endif /* DEBUG_H */
