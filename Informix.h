/*
 *	@(#)$Id: Informix.h,v 100.1 2002/02/08 22:48:45 jleffler Exp $ 
 *
 * Copyright 1994-95      Tim Bunce
 * Copyright 1995-96      Alligator Descartes
 * Copyright 1996-97,1999 Jonathan Leffler
 * Copyright 2002         IBM
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
