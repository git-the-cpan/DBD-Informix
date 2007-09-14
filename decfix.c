/*
@(#)File:           $RCSfile: decfix.c,v $
@(#)Version:        $Revision: 3.5 $
@(#)Last changed:   $Date: 2005/04/12 05:19:28 $
@(#)Purpose:        Fixed formatting of DECIMALs
@(#)Author:         J Leffler
@(#)Copyright:      (C) JLSS 1991-93,1996-97,1999,2001,2003,2005
@(#)Product:        IBM Informix Database Driver for Perl DBI Version 2007.0914 (2007-09-14)
*/

#ifdef TEST
#define USE_DEPRECATED_DECSCI_FUNCTIONS
#endif /* TEST */

#include "esqlc.h"
#include "decsci.h"

/*
** JL - 2001-10-04
** NB: The functions here have not been internationalized at all: there
** is no provision for a decimal point other than period, and there is
** no provision for grouping either before or after the decimal point.
** There is no provision for for omitting the decimal point for 0
** decimal places.
*/

#ifndef __STDC__
/*
** JL - 1999-12-06
** For some versions of ESQL/C (eg 7.23), the dececvt() and decfcvt()
** functions are not declared unless __STDC__ is defined.  Patch this
** up by declaring them, prototype and all, if __STDC__ is not defined.
** JL - 2001-10-04
** NB: the interface to decfcvt() is not thread safe either; we'll need
** to write our own some day using a layout that is thread-safe.  We can
** then fix the const-ness of the interface, too.
*/
extern char *decfcvt(ifx_dec_t *np, int ndigit, int *decpt, int *sign);
#endif /* __STDC__ */

#define SIGN(s, p)  ((s) ? '-' : ((p) ? '+' : ' '))
#define VALID(n)	(((n) <= 0) ? 0 : (((n) > 162) ? 162 : (n)))

#define CONST_CAST(t, v)	((t)(v))

#ifndef lint
static const char rcs[] = "@(#)$Id: decfix.c,v 3.5 2005/04/12 05:19:28 jleffler Exp $";
#endif

#ifdef USE_DEPRECATED_DECSCI_FUNCTIONS
char           *decfix(const ifx_dec_t *d, int ndigit, int plus)
{
	/* fixed format could have -0.(130*0)(32 digits) + null for length 166 */
	static char     buffer[166];
	if (dec_fix(d, ndigit, plus, buffer, sizeof(buffer)) != 0)
		*buffer = '\0';
	return(buffer);
}
#endif /* USE_DEPRECATE_DECSCI_FUNCTIONS */

/*
**	Format a fixed-point number.  Unreliable for ndigit > 58 because of the
**	implementation of decfcvt in ${SOURCE}/genlib/decconv.c
*/
int dec_fix(const ifx_dec_t *d, int ndigit, int plus, char *buffer, size_t buflen)
{
	char  *dst = buffer;
	char  *src;
	int    i;
	int    sn;
	int    dp;

	/* Deal with null values first */
	if (d->dec_pos == DECPOSNULL)
	{
		*dst = '\0';
		return(0);
	}

	ndigit = VALID(ndigit);

	src = decfcvt(CONST_CAST(ifx_dec_t *, d), ndigit, &dp, &sn);

	*dst++ = SIGN(sn, plus);	/* Sign */
	if (dp >= 1)
	{
		while (dp-- > 0)
			*dst++ = ((*src) ? *src++ : '0');
		if (ndigit > 0)
			*dst++ = '.';
		for (i = 0; i < ndigit; i++)
			*dst++ = ((*src) ? *src++ : '0');
	}
	else
	{
		*dst++ = '0';
		if (ndigit > 0)
			*dst++ = '.';
		i = 0;
		while (dp++ < 0 && i++ < ndigit)
			*dst++ = '0';
		while (i++ < ndigit)
			*dst++ = ((*src) ? *src++ : '0');
	}
	*dst = '\0';

	return(0);
}

#ifdef TEST

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define DIM(x)	(sizeof(x)/sizeof(*(x)))

typedef struct Test
{
	const char *val;
	int dp;
	int plus;
	const char *res;
} Test;

static Test test[] =
{
	{	"0", 3, 1, "+0.000"	},
	{	"0", 6, 1, "+0.000000"	},
	{	"+3.14159265358979323844e+00", 6, 0, " 3.141593"	},
	{	"-3.14159265358979323844e+00", 5, 0, "-3.14159"	},
	{	"-3.14159265358979323844e+01", 5, 1, "-31.41593"	},
	{	"-3.14159265358979323844e+01", 9, 0, "-31.415926536"	},
	{	" 3.14159265358979323844e+02", 12, 1,	"+314.159265358979"	},
	{	"+3.14159265358979323844e+03", 0,  1,	"+3142"	},
	{	"-3.14159265358979323844e+34", 0,  1,	"-31415926535897932384400000000000000"	},
	{	" 3.14159265358979323844e+68", 3, 0, " 314159265358979323844000000000000000000000000000000000000000000000000.000"	},
	{	"+3.14159265358979323844e+99", 0, 0, " 3141592653589793238440000000000000000000000000000000000000000000000000000000000000000000000000000000"	},
	{	"-3.14159265358979323844e+100", 0, 0, "-31415926535897932384400000000000000000000000000000000000000000000000000000000000000000000000000000000"	},
	{	" 9.99999999999999999999e+124", 0, 0, " 99999999999999999999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" 	},
	{	"+1.00000000000000000000e+125", 0, 0, " 100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"	},
	{	" 9.99999999999999999999e+125", 0, 0, " 999999999999999999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" 	},
	{	"+1.00000000000000000000e+126", 0, 0, ""	},
	{	" 3.14159265358979323844e-01",	3,	0,	" 0.314"	},
	{	"+3.14159265358979323844e-02",	6,	1,	"+0.031416"	},
	{	"-3.14159265358979323844e-03",	6,	0,	"-0.003142"	},
	{	" 3.14159265358979323844e-34",	10,	0,	" 0.0000000000"	},
	{	"+3.14159265358979323844e-66",	70,	0,	" 0.0000000000000000000000000000000000000000000000000000000000000000031416"	},
	{	"+3.14159265358979323844e-67",	70,	0,	" 0.0000000000000000000000000000000000000000000000000000000000000000003142"	},
	{	"+3.14159265358979323844e-68",	70,	0,	" 0.0000000000000000000000000000000000000000000000000000000000000000000314"	},
	{	"+3.14159265358979323844e-69",	70,	0,	" 0.0000000000000000000000000000000000000000000000000000000000000000000031"	},
	{	"+3.14159265358979323844e-70",	70,	0,	" 0.0000000000000000000000000000000000000000000000000000000000000000000003"	},
	{	"+3.14159265358979323844e-71",	70,	0,	" 0.0000000000000000000000000000000000000000000000000000000000000000000000"	},
	{	" 1.000000000000000000000000000001E-108",	140,	1,	"+0.00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000100"	},
	{	"+3.14159265358979323844e-126",	20,	1,	"+0.00000000000000000000"	},
	{	"-3.14159265358979323844e-127",	135,	0,	"-0.000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000314159265"	},
	{	"11.001001001001001001001001001001E-128",	161,	1,	"+0.00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011001001001001001001001001001001000"	},
	{	"+1.00000000000000000000e-129",	10,	1,	"+0.0000000000"	},
	{	"-1.00000000000000000000e-130",	10,	1,	"-0.0000000000"	},
	{	" 9.99999999999999999999e-131",	0,	0,	""	},
};

int main(void)
{
	int       rv;
	ifx_dec_t d;
	int       i;
	int       err;
	char      buffer[166];
	int       fail = 0;
	int       take = 0;

	for (i = 0; i < DIM(test); i++)
	{
		if ((err = deccvasc(CONST_CAST(char *, test[i].val), strlen(test[i].val), &d)) != 0)
			printf("deccvasc error %d on %s\n", err, test[i].val);
		else
		{
			take++;
			rv = dec_fix(&d, test[i].dp, test[i].plus, buffer, sizeof(buffer));
			if (rv != 0 || strcmp(test[i].res, buffer) != 0)
			{
				fail++;
				printf("** FAIL ** input <%s>\n\tgot    <%s>\n\t"
						"wanted <%s>\n\terror = %d\n",
						test[i].val, buffer, test[i].res, rv);
			}
		}
	}
	if (fail == 0)
		printf("== PASS == %d tests\n", take);
	else
		printf("** FAIL ** %d failures in %d tests\n", fail, take);

	return((fail == 0) ? EXIT_SUCCESS : EXIT_FAILURE);
}

#endif	/* TEST */
