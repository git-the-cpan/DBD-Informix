/*
@(#)File:            $RCSfile: ixblob.h,v $
@(#)Version:         $Revision: 50.3 $
@(#)Last changed:    $Date: 1998/04/09 21:48:10 $
@(#)Purpose:         ESQL/C Utility Functions for DBD::Informix
@(#)Author:          J Leffler
@(#)Copyright:       (C) Jonathan Leffler 1997-98
@(#)Product:         IBM Informix Database Driver for Perl Version 1.00.PC2 (2002-02-01)
*/

/*TABSTOP=4*/

#ifndef IXBLOB_H
#define IXBLOB_H

#ifdef MAIN_PROGRAM
#ifndef lint
static const char ixblob_h[] = "@(#)$Id: ixblob.h version /main/4 1998-04-09 21:48:10 $";
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
