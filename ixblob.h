/*
@(#)File:            $RCSfile: ixblob.h,v $
@(#)Version:         $Revision: 50.2 $
@(#)Last changed:    $Date: 1997/05/05 16:52:06 $
@(#)Purpose:         ESQL/C Utility Functions for DBD::Informix
@(#)Author:          J Leffler
@(#)Copyright:       (C) Jonathan Leffler 1997
@(#)Product:         $Product: DBD::Informix Version 0.57 (1997-11-13) $
*/

/*TABSTOP=4*/

#ifndef IXBLOB_H
#define IXBLOB_H

#ifdef MAIN_PROGRAM
#ifndef lint
static const char ixblob_h[] = "@(#)$Id: ixblob.h,v 50.2 1997/05/05 16:52:06 johnl Exp $";
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
** is deleted.  Note that blob_locate() does not handle BLOB_DUMMY_VALUE
** or BLOB_NULL_VALUE.
*/
extern BlobLocn blob_getlocmode(void);
extern int blob_locate(Blob *blob, BlobLocn locn);
extern void blob_release(Blob *blob, int dflag);
extern void blob_setlocmode(BlobLocn locn);

#endif	/* IXBLOB_H */
