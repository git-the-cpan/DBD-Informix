/*
@(#)File:           $Id: ixblob.ec,v 100.2 2002/02/08 22:49:27 jleffler Exp $
@(#)Based on:       ixblob.ec 50.9 1998-10-28 18:42:12
@(#)Purpose:        Handle Blobs
@(#)Author:         J Leffler
@(#)Copyright:      1996-98 Jonathan Leffler
@(#)Copyright:      2000    Informix Software Inc
@(#)Copyright:      2002    IBM
@(#)Product:        IBM Informix Database Driver for Perl Version 2003.03.0401 (2003-03-04)
*/

/*TABSTOP=4*/
/*LINTLIBRARY*/

#include <assert.h>
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
/* Windows 95 and Windows NT fix from Harald Ums <Harald.Ums@sevensys.de> */
#ifdef _WIN32
#include <io.h>
#else
#include <unistd.h>
#endif /* _WIN32 */
#include "ixblob.h"

#ifdef DEBUG
#include "esqlutil.h"
#endif /* DEBUG */

#define FILENAMESIZE	128

#ifndef DEFAULT_TMPDIR
#define DEFAULT_TMPDIR	"/tmp"
#endif

static BlobLocn def_blob_locn = BLOB_IN_MEMORY;

#ifndef lint
static const char rcs[] = "@(#)$Id: ixblob.ec,v 100.2 2002/02/08 22:49:27 jleffler Exp $";
#endif

BlobLocn blob_getlocmode(void)
{
	return(def_blob_locn);
}

void blob_setlocmode(BlobLocn locn)
{
	def_blob_locn = locn;
}

const char *sql_dbtemp(void)
{
	static char    *db_temp;

	if (db_temp == (char *)0)
	{
		if (((db_temp = getenv("DBTEMP")) == (char *)0) &&
			((db_temp = getenv("TMPDIR")) == (char *)0))
			db_temp = DEFAULT_TMPDIR;
	}
	return(db_temp);
}

static int blob_locinnamefile(Blob *blob)
{
	char            tmp[FILENAMESIZE];

	strcpy(tmp, sql_dbtemp());
	strcat(tmp, "/blob.XXXXXX");
	mktemp(tmp);
	/* Cast result of malloc() to placate C++ compilers (eg MSVC) */
	blob->loc_fname = (char *)malloc(strlen(tmp) + 1);
	if (blob->loc_fname == (char *)0)
		return(-1);
	strcpy(blob->loc_fname, tmp);
	blob->loc_loctype = LOCFNAME;
	blob->loc_mode = 0666;
	blob->loc_oflags = LOC_WONLY | LOC_RONLY;
	blob->loc_size = -1;
	blob->loc_indicator = 0;
	blob->loc_fd = -1;
#ifdef DEBUG
	dump_blob(stderr, "blob_locinnamefile()", blob);
#endif	/* DEBUG */
	return(0);
}

static int blob_locinanonfile(Blob *blob)
{
	char            tmp[FILENAMESIZE];

	/* Open a file and then delete it, but keep it open. */
	/* The system cleans it up regardless of how we exit */
	strcpy(tmp, sql_dbtemp());
	strcat(tmp, "/blob.XXXXXX");
	blob->loc_loctype = LOCFILE;
	blob->loc_fname = (char *)0;
	blob->loc_mode = 0666;
	blob->loc_oflags = LOC_WONLY | LOC_RONLY;
	blob->loc_size = -1;
	blob->loc_indicator = 0;
	mktemp(tmp);
	blob->loc_fd = open(tmp, 0666, O_RDWR);
	if (blob->loc_fd < 0)
	{
		return(-1);
	}
	unlink(tmp);
#ifdef DEBUG
	dump_blob(stderr, "blob_locinanonfile()", blob);
#endif	/* DEBUG */
	return(0);
}

static int blob_locinmem(Blob *blob)
{
	/* Use memory only */
	blob->loc_loctype = LOCMEMORY;
	blob->loc_size = 0;
	blob->loc_bufsize = -1;
	blob->loc_buffer = (char *)0;
	blob->loc_indicator = 0;
	blob->loc_oflags = 0;
#ifdef DEBUG
	dump_blob(stderr, "blob_locinmem()", blob);
#endif	/* DEBUG */
	return(0);
}

/*
** Initialise a Blob data structure ready for use.
** Returns: 0 => OK, non-zero => fail
*/
int blob_locate(Blob *blob, BlobLocn locn)
{
	int rc;

	/**
	** JL 2000-03-03: Using memset is a hack; it is not really
	** understood why it is necessary, but it seems to avoid some
	** problems on NT and with Purify.  An alternative to memset would
	** create a static variable "static Blob zero_blob = { 0 };" and use
	** "*blob = zero_blob;" to initialize the data.
	*/
	memset(blob, 0, sizeof(Blob));
	blob->loc_status = 0;
	blob->loc_type = SQLTEXT;
	blob->loc_xfercount = 0;
	if (locn == BLOB_DEFAULT)
		locn = blob_getlocmode();
	switch(locn)
	{
	case BLOB_IN_NAMEFILE:
		rc = blob_locinnamefile(blob);
		break;
	case BLOB_IN_ANONFILE:
		rc = blob_locinanonfile(blob);
		break;
	case BLOB_IN_MEMORY:
		rc = blob_locinmem(blob);
		break;
	case BLOB_DEFAULT:
	default:
		assert(0);
		rc = -1;
		break;
	}
	return(rc);
}

void blob_release(Blob *blob, int dflag)
{
	switch (blob->loc_loctype)
	{
	case LOCFILE:
		if (blob->loc_fd >= 0)
			close(blob->loc_fd);
		blob->loc_fd = -1;
		break;

	case LOCFNAME:
		if (blob->loc_fd >= 0)
			close(blob->loc_fd);
		blob->loc_fd = -1;
		if (blob->loc_fname != (char *)0)
			{
			if (dflag)
				unlink(blob->loc_fname);
			free(blob->loc_fname);
			blob->loc_fname = 0;
			}
		break;

	case LOCMEMORY:
		if (blob->loc_buffer != (char *)0)
			free(blob->loc_buffer);
		blob->loc_buffer = (char *)0;
		blob->loc_bufsize = -1;
		blob->loc_mflags = 0;
		blob->loc_size = 0;
		blob->loc_indicator = 0;
		break;

	case LOCUSER:
	default:
		assert(0);
		break;
	}
}
