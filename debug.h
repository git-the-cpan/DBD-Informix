/*
@(#)File:           $RCSfile: debug.h,v $
@(#)Version:        $Revision: 3.4 $
@(#)Last changed:   $Date: 2005/07/29 00:21:11 $
@(#)Purpose:        Definitions for the debugging system
@(#)Author:         J Leffler
@(#)Copyright:      (C) JLSS 1990-93,1997-99,2003,2005
@(#)Product:        IBM Informix Database Driver for Perl DBI Version 2007.0904 (2007-09-04)
*/

#ifndef DEBUG_H
#define DEBUG_H

/* -- Macro Definitions	*/

/*
** Usage:  TRACE((level, fmt, ...))
** "level" is the debugging level which must be operational for the output
** to appear. "fmt" is a printf format string. "..." is whatever extra
** arguments fmt requires (possibly nothing).
*/
#ifdef DEBUG
#define TRACE(x)	db_print x
#else
#define TRACE(x)	((void)0)
#endif /* DEBUG */

/* -- Declarations */

#ifndef lint
#ifdef DEBUG
/* This string can't be made extern - multiple definition in general */
static const char jlss_id_debug_enabled[] = "@(#)*** DEBUG ***";
#endif /* DEBUG */
#ifdef MAIN_PROGRAM
const char jlss_id_debug_h[] = "@(#)$Id: debug.h,v 3.4 2005/07/29 00:21:11 jleffler Exp $";
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
*/
#ifdef DEBUG
#define MDTRACE(x)	db_mdprint x
#else
#define MDTRACE(x)	((void)0)
#endif /* DEBUG */

extern int      db_mdgetdebug(int subsys);
extern int      db_mdparsearg(char *arg);
extern int      db_mdsetdebug(int subsys, int level);
extern void     db_mdprint(int subsys, int level, const char *fmt,...);
extern void     db_mdsubsysnames(char const * const *names);

#endif	/* DEBUG_H */
