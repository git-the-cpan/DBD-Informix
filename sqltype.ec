/*
@(#)File:            $RCSfile: sqltype.ec,v $
@(#)Version:         $Revision: 2.2 $
@(#)Last changed:    $Date: 1998/11/17 21:30:43 $
@(#)Purpose:         Convert type and length from Syscolumns to string
@(#)Author:          J Leffler
@(#)Copyright:       (C) JLSS 1988-1993,1995-98
@(#)Product:         $Product: DBD::Informix Version 0.62 (1999-09-19) $
*/

/*TABSTOP=4*/
/*LINTLIBRARY*/

#ifndef lint
static const char rcs[] = "@(#)$Id: sqltype.ec,v 2.2 1998/11/17 21:30:43 jleffler Exp $";
#endif

#include <string.h>
#include "esqlc.h"
#include "esqlutil.h"

static const char * const sqltypes[] = 
{
	"CHAR",
	"SMALLINT",
	"INTEGER",
	"FLOAT",
	"SMALLFLOAT",
	"DECIMAL",
	"SERIAL",
	"DATE",
	"MONEY",
	"NULL",
	"DATETIME",
	"BYTE",
	"TEXT",
	"VARCHAR",
	"INTERVAL",
	"NCHAR",
	"NVARCHAR",
	"INT8",
	"SERIAL8",
	"SET",
	"MULTISET",
	"LIST",
	"ROW",
	"COLLECTION",
	"ROWREF",
	"[reserved25]",
	"[reserved26]",
	"[reserved27]",
	"[reserved28]",
	"[reserved29]",
	"[reserved30]",
	"[reserved31]",
	"[reserved32]",
	"[reserved33]",
	"[reserved34]",
	"[reserved35]",
	"[reserved36]",
	"[reserved37]",
	"[reserved38]",
	"[reserved39]",
	"FIXED UDT",
	"VARIABLE UDT",
	"REFSER8",
	"LVARCHAR",
	"SENDRECV",
	"BOOLEAN",
	"IMPEXP",
	"IMPEXPBIN",
};

static const char dt_day[] = "DAY";
static const char dt_fraction1[] = "FRACTION(1)";
static const char dt_fraction2[] = "FRACTION(2)";
static const char dt_fraction3[] = "FRACTION(3)";
static const char dt_fraction4[] = "FRACTION(4)";
static const char dt_fraction5[] = "FRACTION(5)";
static const char dt_fraction[] = "FRACTION";
static const char dt_hour[] = "HOUR";
static const char dt_minute[] = "MINUTE";
static const char dt_month[] = "MONTH";
static const char dt_second[] = "SECOND";
static const char dt_unknown[] = "{unknown}";
static const char dt_year[] = "YEAR";

static const char * const dt_fr_ext[] = 
{
	dt_year,
	dt_unknown,
	dt_month,
	dt_unknown,
	dt_day,
	dt_unknown,
	dt_hour,
	dt_unknown,
	dt_minute,
	dt_unknown,
	dt_second,
	dt_unknown,
	dt_fraction,
	dt_unknown,
	dt_unknown,
	dt_unknown
};

static const char * const dt_to_ext[] = 
{
	dt_year,
	dt_unknown,
	dt_month,
	dt_unknown,
	dt_day,
	dt_unknown,
	dt_hour,
	dt_unknown,
	dt_minute,
	dt_unknown,
	dt_second,
	dt_fraction1,
	dt_fraction2,
	dt_fraction3,
	dt_fraction4,
	dt_fraction5
};

static char	typestr[SQLTYPENAME_BUFSIZ];
static int sqlmode = 0;

/*
** Get/Set Type Formatting mode
** If the mode is set to 1, then sqltypename() formats
** INTERVAL HOUR(6) TO HOUR as INTERVAL HOUR(6).
** Otherwise it uses the standard Informix type name.
*/
int sqltypemode(int mode)
{
	int	oldmode = sqlmode;
	sqlmode = mode;
	return(oldmode);
}

char	*sqltypename(int coltype, int collen, char *buffer)
{
	int		precision;
	int		dt_fr;
	int		dt_to;
	int		dt_ld;
	int		vc_min;
	int		vc_max;
	int		scale;
	int		type = MASKNONULL(coltype);
	char   *start = buffer;

	if (coltype & SQLDISTINCT)
	{
		strcpy(start, "DISTINCT ");
		start += strlen(start);
	}

	switch (type)
	{
	case SQLCHAR:
	case SQLNCHAR:
		sprintf(start, "%s(%d)", sqltypes[type], collen);
		break;

	case SQLSMINT:
	case SQLINT:
	case SQLFLOAT:
	case SQLSMFLOAT:
	case SQLDATE:
	case SQLSERIAL:
	case SQLNULL:
	case SQLTEXT:
	case SQLBYTES:
	case SQLINT8:
	case SQLSERIAL8:
		strcpy(start, sqltypes[type]);
		break;

	/* IUS types -- may need more work in future */
	case SQLSET:
	case SQLLIST:
	case SQLMULTISET:
	case SQLCOLLECTION:
	case SQLROW:
	case SQLROWREF:
		strcpy(start, sqltypes[type]);
		break;

	case SQLDECIMAL:
	case SQLMONEY:
		precision = (collen >> 8) & 0xFF;
		scale = (collen & 0xFF);
		if (scale == 0xFF)
			sprintf(start, "%s(%d)", sqltypes[type], precision);
		else
			sprintf(start, "%s(%d,%d)", sqltypes[type], precision, scale);
		break;

	case SQLVCHAR:
	case SQLNVCHAR:
		vc_min = VCMIN(collen);
		vc_max = VCMAX(collen);
		if (vc_min == 0)
			sprintf(start, "%s(%d)", sqltypes[type], vc_max);
		else
			sprintf(start, "%s(%d,%d)", sqltypes[type], vc_max, vc_min);
		break;

	case SQLDTIME:
		dt_fr = TU_START(collen);
		dt_to = TU_END(collen);
		if (sqlmode != 1)
			sprintf(start, "%s %s TO %s", sqltypes[type], dt_fr_ext[dt_fr],
					dt_to_ext[dt_to]);
		else if (dt_fr == TU_FRAC)
			sprintf(start, "%s %s", sqltypes[type], dt_to_ext[dt_to]);
		else if (dt_fr == dt_to)
			sprintf(start, "%s %s", sqltypes[type], dt_to_ext[dt_to]);
		else
			sprintf(start, "%s %s TO %s", sqltypes[type], dt_fr_ext[dt_fr],
					dt_to_ext[dt_to]);
		break;

	case SQLINTERVAL:
		dt_fr = TU_START(collen);
		dt_to = TU_END(collen);
		dt_ld = TU_FLEN(collen);
		if (sqlmode != 1 && dt_fr == TU_FRAC)
			sprintf(start, "%s %s TO %s", sqltypes[type],
					dt_fr_ext[dt_fr], dt_to_ext[dt_to]);
		else if (sqlmode != 1)
			sprintf(start, "%s %s(%d) TO %s", sqltypes[type],
					dt_fr_ext[dt_fr], dt_ld, dt_to_ext[dt_to]);
		else if (dt_fr == TU_FRAC)
			sprintf(start, "%s %s", sqltypes[type], dt_to_ext[dt_to]);
		else if (dt_fr == dt_to)
			sprintf(start, "%s %s(%d)", sqltypes[type], dt_to_ext[dt_to],
					dt_ld);
		else
			sprintf(start, "%s %s(%d) TO %s", sqltypes[type],
					dt_fr_ext[dt_fr], dt_ld, dt_to_ext[dt_to]);
		break;

	default:
		sprintf(start, "Unknown (type %d, len %d)", coltype, collen);
		ESQLC_VERSION_CHECKER();
		break;
	}
	return(buffer);
}

/* For backwards compatability only */
/* Not thread-safe because it uses static return data */
const char	*sqltype(int coltype, int collen)
{
	return(sqltypename(coltype, collen, typestr));
}

#ifdef TEST

#define DIM(x)	(sizeof(x)/sizeof(*(x)))

typedef struct	Typelist
{
	char	*code;
	int		coltype;
	int		collen;
}	Typelist;

static Typelist	types[] =
{
	{	"serial",							262,		4		},
	{	"char",								0,			10		},
	{	"date",								7,			4		},
	{	"decimal",							5,			4351	},
	{	"decimal(16)",						5,			4351	},
	{	"decimal(32,14)",					5,			8206	},
	{	"float",							3,			8		},
	{	"integer",							2,			4		},
	{	"money",							8,			4098	},
	{	"money(16,2)",						8,			4098	},
	{	"smallfloat",						4,			4		},
	{	"smallint",							1,			2		},
	{	"varchar(128)",						13,			128		},
	{	"varchar(128,64)",					13,			16512	},
	{	"datetime day to day",				10,			580		},
	{	"datetime hour to fraction(3)",		10,			2413	},
	{	"datetime minute to fraction(3)",	10,			1933	},
	{	"datetime month to fraction(3)",	10,			3373	},
	{	"datetime second to fraction(5)",	10,			1967	},
	{	"datetime second to second",		10,			682		},
	{	"datetime year to fraction(3)",		10,			4365	},
	{	"datetime year to fraction(5)",		10,			4879	},
	{	"datetime year to year",			10,			1024	},
	{	"interval day(4) to fraction(3)",	14,			3405	},
	{	"interval day(9) to fraction(5)",	14,			5199	},
	{	"interval day to fraction(5)",		14,			3407	},
	{	"interval hour(4) to fraction(3)",	14,			2925	},
	{	"interval hour(6) to fraction(5)",	14,			3951	},
	{	"interval hour to fraction(5)",		14,			2927	},
	{	"byte in table",					11,			56		},
	{	"text in table",					12,			56		},
	{	"datetime fraction to fraction", 10,			973		},
	{	"datetime fraction to fraction(1)", 10,			459		},
	{	"datetime fraction to fraction(2)", 10,			716		},
	{	"datetime fraction to fraction(3)", 10,			973		},
	{	"datetime fraction to fraction(4)", 10,			1230	},
	{	"datetime fraction to fraction(5)", 10,			1487	},
	{	"interval fraction to fraction",	14,			973		},
	{	"interval fraction to fraction(1)", 14,			459		},
	{	"interval fraction to fraction(2)", 14,			716		},
	{	"interval fraction to fraction(3)", 14,			973		},
	{	"interval fraction to fraction(4)", 14,			1230	},
	{	"interval fraction to fraction(5)", 14,			1487	},
};

static void printtypes(int mode)
{
	int             i;

	sqltypemode(mode);
	printf("%-32s %4s %6s   %s\n", "Code", "Type", "Length", "Full type");
	for (i = 0; i < DIM(types); i++)
	{
		printf("%-32s %4d %6d = %s\n",
			   types[i].code, types[i].coltype, types[i].collen,
			   sqltype(types[i].coltype, types[i].collen));
		fflush(stdout);
	}
}

int main()
{
	printtypes(0);
	printtypes(1);
	return (0);
}

#endif	/* TEST */
