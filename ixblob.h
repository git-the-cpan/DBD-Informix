/*
@(#)Purpose:         ESQL/C Utility Functions for DBD::Informix
@(#)Author:          J Leffler
@(#)Copyright:       1997-98 Jonathan Leffler
@(#)Copyright:       2002    IBM
@(#)Product:         IBM Informix Database Driver for Perl Version 2003.03.0400 (2003-03-04)
*/

/*TABSTOP=4*/

#ifndef IXBLOB_H
#define IXBLOB_H

#ifdef MAIN_PROGRAM
#ifndef lint
static const char ixblob_h[] = "@(#)$Id: ixblob.h,v 100.1 2002/02/08 22:49:28 jleffler Exp $";
#endif	/* lint */
#endif	/* MAIN_PROGRAM */

#include <stdio.h>
#include "esqlc.h"

/* Return the name specified by $DBTEMP, defaulting to /tmp */
extern const char *sql_dbtemp(void);

enum BlobLocn
{
	BLOB_DEFAULT, BLOB_IN_MEMORY, BLOB_IN_ANONFILE, BLOB_IN_NAMEFILE
};
typedef enum BlobLocn BlobLocn;

/*
** If you are using blobs in memory, the space allocated for the
** blob needs to be released by blob_locate().  Blob files may or
** may not need to be deleted; if dflag is non-zero, then the file
** is deleted.
*/
extern BlobLocn blob_getlocmode(void);
extern int blob_locate(Blob *blob, BlobLocn locn);
extern void blob_release(Blob *blob, int dflag);
extern void blob_setlocmode(BlobLocn locn);

#endif	/* IXBLOB_H */
