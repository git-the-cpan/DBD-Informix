/*
@(#)File:            esqlc.h
@(#)Version:         1.9
@(#)Last changed:    96/12/04
@(#)Purpose:         Include all relevant ESQL/C type definitions
@(#)Author:          J Leffler
@(#)Copyright:       (C) JLSS 1992,1993,1995,1996
@(#)Product:         :PRODUCT:
*/

#ifndef ESQLC_H
#define ESQLC_H

#ifdef MAIN_PROGRAM
#ifndef lint
static const char esqlc_h[] = "@(#)esqlc.h	1.9 96/12/04";
#endif	/* lint */
#endif	/* MAIN_PROGRAM */

#ifndef ESQLC_VERSION
#ifdef ESQLC_4_10
#define ESQLC_VERSION 410
#endif /* ESQLC_4_00 */
#ifdef ESQLC_4_00
#define ESQLC_VERSION 400
#endif /* ESQLC_4_00 */
#ifdef ESQLC_5_00
#define ESQLC_VERSION 500
#endif /* ESQLC_5_00 */
#ifdef ESQLC_6_00
#define ESQLC_VERSION 600
#endif /* ESQLC_6_00 */
#ifdef ESQLC_7_00
#define ESQLC_VERSION 700
#endif /* ESQLC_7_00 */
#ifdef ESQLC_7_10
#define ESQLC_VERSION 710
#endif /* ESQLC_7_10 */
#ifdef ESQLC_7_20
#define ESQLC_VERSION 720
#endif /* ESQLC_7_20 */
#endif /* ESQLC_VERSION */

/* If it still isn't defined, use version 0 */
#ifndef ESQLC_VERSION
#define ESQLC_VERSION 0
#endif /* ESQLC_VERSION */

/*
** On DEC OSF/1 and 64-bits machines, __STDC__ is not necessarily defined,
** but the use of prototypes is necessary under optimization to ensure that
** pointers are treated correctly (sizeof(void *) != sizeof(int)).
** The <sqlhdr.h> prototypes for version 6.00 and above are only active if
** __STDC__ is defined (whether 1 or 0 or something else does not matter).
** If USE_PROTOTYPES is defined, then the code with ESQLC_UNDEF_STDC
** ensures that the ESQL/C prototypes are visible, even if __STDC__ is not
** otherwise defined, and it also ensures the __STDC__ is not defined
** outside the scope of this header and those it includes.
*/
#undef ESQLC_UNDEF_STDC
#ifdef USE_PROTOTYPES
#ifndef __STDC__
#define ESQLC_UNDEF_STDC
#define __STDC__
#endif /* __STDC__ */
#endif /* USE_PROTOTYPES */

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

/* -- Include Files	*/

#include <datetime.h>
#include <decimal.h>
#include <locator.h>
#include <sqlca.h>
#include <sqlda.h>
#include <sqlstype.h>
#include <sqltypes.h>

#if ESQLC_VERSION >= 400
#include <varchar.h>
#endif /* ESQLC_VERSION >= 400 */

#if ESQLC_VERSION < 400
/* No prototypes available */
#elif ESQLC_VERSION < 410
#include "esql4_00.h"
#include "esqllib.h"
#elif ESQLC_VERSION < 500
#include "esql4_10.h"
#include "esqllib.h"
#elif ESQLC_VERSION < 600
#include "esql5_00.h"
#include "esqllib.h"
#else
/* For later versions, sqlhdr.h contains the requisite declarations */
/* For earlier versions, you are on your own! */
#include <sqlhdr.h>

#ifdef __STDC__
extern int      sqgetdbs(int *ret_fcnt,
                         char **fnames,
                         int fnsize,
                         char *farea,
                         int fasize);
#else
extern int      sqgetdbs();
#endif /* __STDC__ */
#endif

/* -- Constant Definitions */

/* A table name may be: database@server:"owner".table */
/* This contains 5 punctuation characters and a null */
#define SQL_NAMELEN	18
#define SQL_USERLEN	8
#define SQL_TABNAMELEN	(3 * SQL_NAMELEN + SQL_USERLEN + 6)

#define loc_mode	lc_union.lc_file.lc_mode
#define sqlva		sqlvar_struct

/* -- Type Definitions */

typedef loc_t	        Blob;
typedef struct decimal	Decimal;
typedef struct dtime	Datetime;
typedef struct intrvl	Interval;
typedef struct sqlca_s	Sqlca;
typedef struct sqlda	Sqlda;
typedef struct sqlva	Sqlva;

#ifdef __cplusplus
}
#endif /* __cplusplus */

#ifdef ESQLC_UNDEF_STDC
#undef __STDC__
#endif /* ESQLC_UNDEF_STDC */
#undef ESQLC_UNDEF_STDC

#endif	/* ESQLC_H */
