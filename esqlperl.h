/*
@(#)File:            esqlperl.h
@(#)Version:         53.2
@(#)Last changed:    97/03/06
@(#)Purpose:         ESQL/C Utility Functions for DBD::Informix
@(#)Author:          J Leffler
@(#)Copyright:       (C) Jonathan Leffler 1996,1997
@(#)Product:         :PRODUCT:
*/

/*TABSTOP=4*/

#ifndef ESQLPERL_H
#define ESQLPERL_H

#ifdef MAIN_PROGRAM
#ifndef lint
static const char esqlperl_h[] = "@(#)esqlperl.h	53.2 97/03/06";
#endif	/* lint */
#endif	/* MAIN_PROGRAM */

#include <stdio.h>
#include "esqlc.h"

enum Boolean
{
	False, True
};
typedef enum Boolean Boolean;

/*
** The sqltypename() routine assumes is has a buffer of at least
** SQLTYPENAME_BUFSIZ bytes in which too work.
** The return address is the start of the buffer.
*/
#define SQLTYPENAME_BUFSIZ sizeof("INTERVAL MINUTE(2) TO FRACTION(5)")
extern char *sqltypename(int coltype, int collen, char *buffer);

/* Return the name specified by $DBTEMP, defaulting to /tmp */
extern const char *sql_dbtemp(void);

enum BlobLocn
{
	BLOB_DEFAULT, BLOB_IN_MEMORY, BLOB_IN_ANONFILE, BLOB_IN_NAMEFILE,
	BLOB_DUMMY_VALUE, BLOB_NULL_VALUE
};
typedef enum BlobLocn BlobLocn;

/*
** If you are using blobs in memory, the space allocated for the
** blob needs to be released by blob_locate().  Blob files may or
** may not need to be deleted; if dflag is non-zero, then the file
** is deleted.  Note that blob_locate() does not handle BLOB_DUMMY_VALUE
** or BLOB_NULL_VALUE.
*/
extern int blob_locate(Blob *blob, BlobLocn locn);
extern void blob_release(Blob *blob, int dflag);

extern void dbd_ix_debug(int n, char *fmt, const char *arg);
extern void dbd_ix_setconnection(char *conn);

#if ESQLC_VERSION >= 600
extern void dbd_ix_disconnect(char *connection);
extern Boolean dbd_ix_connect(char *conn, char *dbase, char *user, char *pass);
#else
extern void dbd_ix_closedatabase(void);
extern Boolean dbd_ix_opendatabase(char *dbase);
#endif	/* ESQLC_VERSION >= 600 */

#endif	/* ESQLPERL_H */
