/*
@(#)File:           $RCSfile: decintl.h,v $
@(#)Version:        $Revision: 2.2 $
@(#)Last changed:   $Date: 2005/03/20 07:54:21 $
@(#)Purpose:        Internal Functions for manipulating DECIMAL values
@(#)Author:         J Leffler
@(#)Copyright:      (C) JLSS 2001,2005
@(#)Product:        IBM Informix Database Driver for Perl DBI Version 2007.0904 (2007-09-04)
*/

/*TABSTOP=4*/

#ifndef DECINTL_H
#define DECINTL_H

#ifdef MAIN_PROGRAM
#ifndef lint
static const char decintl_h[] = "@(#)$Id: decintl.h,v 2.2 2005/03/20 07:54:21 jleffler Exp $";
#endif	/* lint */
#endif	/* MAIN_PROGRAM */

extern char *dec_setexp(char  *dst, int dp);

#endif	/* DECINTL_H */
