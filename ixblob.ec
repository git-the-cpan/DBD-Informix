/*
@(#)File:           $RCSfile: ixblob.ec,v $
@(#)Version:        $Revision: 2005.2 $
@(#)Last changed:   $Date: 2005/08/12 17:22:43 $
@(#)Purpose:        Handle Blobs
@(#)Author:         J Leffler
@(#)Copyright:      (C) JLSS 1996-98,2000-01,2003,2005
@(#)Product:        IBM Informix Database Driver for Perl DBI Version 2007.0226 (2007-02-25)
*/

/*TABSTOP=4*/
/*LINTLIBRARY*/

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif /* HAVE_CONFIG_H */

#ifndef _XOPEN_SOURCE
/* JL 2005-07-25: Some systems (eg AIX 5.2) define _XOPEN_SOURCE 600 */
#define _XOPEN_SOURCE	500
#endif /* _XOPEN_SOURCE */

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

/*
** 2005-08-12: Windows fix - from Brian D Campbell <campbelb@lucent.com>
** access() is defined in <io.h>, but F_OK is not.  E_ACC is apparently
** equivalent to F_OK and defined as 00.
*/
#ifndef F_OK
#define F_OK	0
#endif /* F_OK */

#ifdef DEBUG
#include "esqlutil.h"
#endif /* DEBUG */

#define FILENAMESIZE	128

#ifndef DEFAULT_TMPDIR
#define DEFAULT_TMPDIR	"/tmp"
#endif

static BlobLocn def_blob_locn = BLOB_IN_MEMORY;
static Blob zero_blob = { 0 };
static char *blob_dir = 0;

#ifndef lint
static const char rcs[] = "@(#)$Id: ixblob.ec,v 2005.2 2005/08/12 17:22:43 jleffler Exp $";
#endif

BlobLocn blob_getlocmode(void)
{
	return(def_blob_locn);
}

void blob_setlocmode(BlobLocn locn)
{
	def_blob_locn = locn;
}

void blob_setdirectory(const char *dir)
{
	if (blob_dir != 0)
		free(blob_dir);
	blob_dir = (char *)malloc(strlen(dir)+1);
	if (blob_dir != 0)
		strcpy(blob_dir, dir);
}

const char *blob_getdirectory(void)
{
	const char *rv = blob_dir;
	if (rv == 0)
		rv = sql_dbtemp();
	return rv;
}

const char *sql_dbtemp(void)
{
	static char    *db_temp = 0;

	if (db_temp == (char *)0)
	{
		if (((db_temp = getenv("DBTEMP")) == (char *)0) &&
			((db_temp = getenv("TMPDIR")) == (char *)0))
			db_temp = DEFAULT_TMPDIR;
	}
	return(db_temp);
}

/*
** Return a dynamically allocated string containing a unique file name.
**
** Note that there is a window of vulnerability between the time when
** the absence of the file is established in this function and when the
** file is actually created by the current process during which another
** program (or part of this program) could create the file.
**
** Using mktemp() is not recommended by the Linux/GNU headers (the man
** pages claim it is BSD 4.3 only, but it was in Version 7 Unix too),
** and it is not defined by POSIX.  The standard alternatives are:
**      tmpnam()    ISO C 1990  -- no control over directory
**      tmpfile()   ISO C 1990  -- no access to name
**      tempnam()   SVID/BDS4.3 -- not very standard; otherwise OK
**      mkstemp()   BSD4.3      -- even less standard; otherwise OK
** By design, we need control over the directory, so if mktemp() was
** always available, using mktemp() is the least of many evils.
** However, at least one machine did not provide a header declaring
** mktemp(), which leads to compilation problems, so we are, in fact,
** better off writing our own.  It does not have to be all that complex,
** as long as we assume flexible names in the file system.  That is
** pretty safe these days!
*/
char *blob_newfilename(void)
{
	char            tmp[FILENAMESIZE];
	char *rv;
	static int counter = 0;

	do
	{
		sprintf(tmp, "%s/blob.%05d.%06d", blob_getdirectory(), (int)getpid(), ++counter);
	}
	while (access(tmp, F_OK) == 0);

	/* Cast result of malloc() to placate C++ compilers (eg MSVC) */
	rv = (char *)malloc(strlen(tmp) + 1);
	if (rv != (char *)0)
		strcpy(rv, tmp);
	return(rv);
}

static int blob_locinnamefile(Blob *blob)
{
	blob->loc_fname = blob_newfilename();
	if (blob->loc_fname == (char *)0)
		return(-1);
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
int blob_locate(Blob * blob, BlobLocn locn)
{
	int rc;

	*blob = zero_blob;
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
