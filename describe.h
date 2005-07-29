/*
@(#)File:           $RCSfile: describe.h,v $
@(#)Version:        $Revision: 1.10 $
@(#)Last changed:   $Date: 2003/09/08 18:29:12 $
@(#)Purpose:        Header file for use with describe
@(#)Author:         J Leffler
@(#)Copyright:      (C) JLSS 1993,1997-98,2000,2003
@(#)Product:        IBM Informix Database Driver for Perl DBI Version 2005.02 (2005-07-29)
*/

/*TABSTOP=4*/

#ifndef DESCRIBE_H
#define DESCRIBE_H

#ifdef MAIN_PROGRAM
#ifndef lint
static const char describe_h[] = "@(#)$Id: describe.h,v 1.10 2003/09/08 18:29:12 jleffler Exp $";
#endif	/* lint */
#endif	/* MAIN_PROGRAM */

/*
** sql_describe() allocates space for a given sqlda structure.
** The return value should be freed via sql_release() when the work is complete.
** The del_blob_file argument indicates whether any blobs in files should be deleted.
*/
extern void *sql_describe(Sqlda *desc);
extern void sql_release(Sqlda *desc, void *buffer, int del_blob_file);

#endif	/* DESCRIBE_H */
