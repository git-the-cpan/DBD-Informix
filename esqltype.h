/*
@(#)File:            $RCSfile: esqltype.h,v $
@(#)Version:         $Revision: 100.3 $
@(#)Last changed:    $Date: 2002/02/08 22:49:24 $
@(#)Purpose:         Platform and Version Independent Types for ESQL/C
@(#)Author:          J Leffler
@(#)Copyright:       2001 Jonathan Leffler (JLSS)
@(#)Copyright:       2001 Informix Software Inc
@(#)Copyright:       2002 IBM
@(#)Product:         IBM Informix Database Driver for Perl Version 2003.03.0303 (2003-03-03)
*/

/*TABSTOP=4*/

#ifndef ESQLTYPE_H
#define ESQLTYPE_H

#ifdef MAIN_PROGRAM
#ifndef lint
static const char esqltype_h[] = "@(#)$Id: esqltype.h,v 100.3 2002/02/08 22:49:24 jleffler Exp $";
#endif	/* lint */
#endif	/* MAIN_PROGRAM */

/*
** Define Informix types:
** ixInt1   - signed, 1-byte integer
** ixInt2   - signed, 2-byte integer
** ixInt4   - signed, 4-byte integer
** ixMint   - signed machine integer
** ixMlong  - signed machine long
** ixUint1  - unsigned, 1-byte integer
** ixUint2  - unsigned, 2-byte integer
** ixUint4  - unsigned, 4-byte integer
** ixUmint  - unsigned machine integer
** ixUmlong - unsigned machine long
**
** Also attempt to define macros for printf formats for the various
** types.  This is based on the ISO C:1999 (ISO/IEC 9899:1999)
** <inttypes.h> style.  It is easy enough for the pre-9.21 versions of
** ESQL/C.  It is very much more difficult for the versions with the
** "ifxtypes.h" header which does *not* define such macros.  However,
** the ifxtypes.h header does define macros MI_LONG_SIZE and MI_PTR_SIZE
** which define the number of bits in a long and a pointer respectively.
** These values can be used to to decide the mapping.
*/

#if ESQLC_VERSION < 921

typedef signed char	ixInt1;
typedef short	ixInt2;
typedef long	ixInt4;

#define PRId_ixInt1	"d"
#define PRId_ixInt2	"d"
#define PRId_ixInt4	"ld"

typedef int		ixMint;
typedef long	ixMlong;

#define PRId_ixMint		"d"
#define PRId_ixMlong	"ld"

typedef unsigned char	ixUint1;
typedef unsigned short	ixUint2;
typedef unsigned long	ixUint4;

#define PRIo_ixInt1	"o"
#define PRIo_ixInt2	"o"
#define PRIo_ixInt4	"lo"

#define PRIu_ixInt1	"u"
#define PRIu_ixInt2	"u"
#define PRIu_ixInt4	"lu"

#define PRIx_ixInt1	"x"
#define PRIx_ixInt2	"x"
#define PRIx_ixInt4	"lx"

#define PRIX_ixInt1	"X"
#define PRIX_ixInt2	"X"
#define PRIX_ixInt4	"lX"

typedef unsigned int	ixMuint;
typedef unsigned long	ixMulong;

#define PRIo_ixMuint	"o"
#define PRIo_ixMulong	"lo"

#define PRIu_ixMuint	"u"
#define PRIu_ixMulong	"lu"

#define PRIx_ixMuint	"x"
#define PRIx_ixMulong	"lx"

#define PRIX_ixMuint	"X"
#define PRIX_ixMulong	"lX"

/* Omitted typedefs for MCHAR and MSHORT present in ifxtypes.h */
/* typedef char MCHAR; typedef short MSHORT; */

#else

typedef int1	ixInt1;
typedef int2	ixInt2;
typedef int4	ixInt4;

typedef mint	ixMint;
typedef mlong	ixMlong;

typedef uint1	ixUint1;
typedef uint2	ixUint2;
typedef uint4	ixUint4;

typedef muint	ixMuint;
typedef mulong	ixMulong;

#endif	/* ESQLC_VERSION < 921 */

#endif	/* ESQLTYPE_H */
