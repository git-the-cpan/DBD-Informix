/*
@(#)File:           ixblob.ec
@(#)Version:        50.1
@(#)Last changed:   97/01/12
@(#)Purpose:        Handle Blobs
@(#)Author:         J Leffler
@(#)Copyright:      (C) Jonathan Leffler 1992,1995,1996,1997
@(#)Product:        :PRODUCT:
*/

/*TABSTOP=4*/
/*LINTLIBRARY*/

#include <assert.h>
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "esqlc.h"
#include "esqlperl.h"

#define FILENAMESIZE	128
#define DEFAULT_TMPDIR	"/tmp"

#ifndef lint
static const char sccs[] = "@(#)ixblob.ec	50.1 97/01/12";
#endif

const char *sql_dbtemp(void)
{
	static char    *db_temp;

	if (db_temp == (char *)0)
	{
		db_temp = getenv("DBTEMP");
		if (db_temp == (char *)0)
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
	if (blob->loc_fname == (char *)0)
		return(-1);
	blob->loc_loctype = LOCFNAME;
	blob->loc_fname = malloc(strlen(tmp) + 1);
	blob->loc_mode = 0666;
	blob->loc_oflags = LOC_WONLY | LOC_RONLY;
	blob->loc_size = -1;
	blob->loc_indicator = 0;
	blob->loc_fd = -1;
#ifdef DEBUG
	dump_blob(blob);
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
	dump_blob(blob);
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
	dump_blob(blob);
#endif	/* DEBUG */
	return(0);
}

/*
** Initialise a Blob data structure ready for use.
** Returns: 0 => OK, non-zero => fail
*/
int blob_locate(Blob * blob, BlobLocn locn)
{
	int rc;

	blob->loc_status = 0;
	blob->loc_type = SQLTEXT;
	blob->loc_xfercount = 0;
	switch(locn)
	{
	case BLOB_IN_NAMEFILE:
		rc = blob_locinnamefile(blob);
		break;
	case BLOB_IN_ANONFILE:
		rc = blob_locinanonfile(blob);
		break;
	case BLOB_DEFAULT:
	case BLOB_IN_MEMORY:
		rc = blob_locinmem(blob);
		break;
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
		break;

	case LOCUSER:
	default:
		assert(0);
		break;
	}
}