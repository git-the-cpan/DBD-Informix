/*
 *	@(#)$Id: Informix.h version /main/9 1999-12-23 18:42:00 $ 
 *
 * Portions Copyright (c) 1994,1995 Tim Bunce
 * Portions Copyright (c) 1995,1996 Alligator Descartes
 * Portions Copyright (c) 1996,1997,1999 Jonathan Leffler
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 */

/*TABSTOP=4*/

#ifndef INFORMIX_H
#define INFORMIX_H

#define NEED_DBIXS_VERSION 9

/* For ActiveState Perl on NT */
/* Change from Michael Kopchenov <myk@informix.com> */
#ifdef PERL_OBJECT
#define NO_XSLOCKS
class CPerlObj;
extern CPerlObj* pPerl;
#endif

#include <DBIXS.h>		/* Installed by the DBI module */
#include "dbdimp.h"		/* Informix implementation details */
#include <dbd_xsh.h>	/* Installed by the DBI module */

#endif /* INFORMIX_H */
