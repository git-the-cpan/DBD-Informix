/*
@(#)File:            $RCSfile: esqlperl.h,v $
@(#)Version:         $Revision: 61.2 $
@(#)Last changed:    $Date: 1998/11/17 17:08:25 $
@(#)Purpose:         ESQL/C Utility Functions for DBD::Informix
@(#)Author:          J Leffler
@(#)Copyright:       (C) Jonathan Leffler 1996-98
@(#)Product:         Informix Database Driver for Perl Version 0.97005 (2000-02-10)
*/

/*TABSTOP=4*/

#ifndef ESQLPERL_H
#define ESQLPERL_H

#ifdef MAIN_PROGRAM
#ifndef lint
static const char esqlperl_h[] = "@(#)$Id: esqlperl.h version /main/15 1998-11-17 17:08:25 $";
#endif	/* lint */
#endif	/* MAIN_PROGRAM */

#include <stdio.h>
#include "esqlc.h"
#include "ixblob.h"

enum Boolean
{
	False, True
};
typedef enum Boolean Boolean;

/*
** Under some circumstances, MSVC gets horrendously fussy and rejects
** valid C code.  This is a sop to MSVC and to other C++ compilers.
*/
#define DBD_IX_BOOLEAN(x)	((x) ? True : False)

/*
** The sqltypename() routine assumes is has a buffer of at least
** SQLTYPENAME_BUFSIZ bytes in which too work.
** The return address is the start of the buffer.
*/
#define SQLTYPENAME_BUFSIZ sizeof("DISTINCT INTERVAL MINUTE(2) TO FRACTION(5)")
extern char *sqltypename(int coltype, int collen, char *buffer);

extern void dbd_ix_debug(int n, char *fmt, const char *arg);
extern void dbd_ix_debug_l(int n, char *fmt, long arg);
extern void dbd_ix_setconnection(char *conn);

#if ESQLC_VERSION >= 600
extern void dbd_ix_disconnect(char *connection);
extern Boolean dbd_ix_connect(char *conn, char *dbase, char *user, char *pass);
#else
extern void dbd_ix_closedatabase(char *dbase);
extern Boolean dbd_ix_opendatabase(char *dbase);
#endif	/* ESQLC_VERSION >= 600 */

/* Informix to ODBC mapping for type, precision and scale */
extern int map_type_ifmx_to_odbc(int coltype, int collen);
extern int map_prec_ifmx_to_odbc(int coltype, int collen);
extern int map_scale_ifmx_to_odbc(int coltype, int collen);

#endif	/* ESQLPERL_H */
