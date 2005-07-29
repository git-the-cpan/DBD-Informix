/*
@(#)File:           $RCSfile: decsci.c,v $
@(#)Version:        $Revision: 3.4 $
@(#)Last changed:   $Date: 2005/03/21 08:48:53 $
@(#)Purpose:        Exponential formatting of DECIMALs
@(#)Author:         J Leffler
@(#)Copyright:      (C) JLSS 1991-93,1996-97,1999,2001,2003,2005
@(#)Product:        IBM Informix Database Driver for Perl DBI Version 2005.02 (2005-07-29)
*/

#ifdef TEST
#define USE_DEPRECATED_DECSCI_FUNCTIONS
#endif /* TEST */

#include "esqlc.h"
#include "decsci.h"
#include "decintl.h"

#ifndef __STDC__
/*
** JL - 1999-12-06
** For some versions of ESQL/C (eg 7.23), the dececvt() and decfcvt()
** functions are not declared unless __STDC__ is defined.  Patch this
** up by declaring them, prototype and all, if __STDC__ is not defined.
*/
extern char *dececvt(ifx_dec_t *np, int ndigit, int *decpt, int *sign);
#endif /* __STDC__ */

#define SIGN(s, p)  ((s) ? '-' : ((p) ? '+' : ' '))
#define VALID(n)	(((n) <= 0) ? 6 : (((n) > 32) ? 32 : (n)))

#define CONST_CAST(t, v)	((t)(v))

#ifndef lint
static const char rcs[] = "@(#)$Id: decsci.c,v 3.4 2005/03/21 08:48:53 jleffler Exp $";
#endif

#ifdef USE_DEPRECATED_DECSCI_FUNCTIONS
char *decsci(const ifx_dec_t *d, int ndigit, int plus)
{
	/* For 32 digits, 3-digit exponent, leading blanks, etc, 42 is enough */
	static char buffer[42];
	if (dec_sci(d, ndigit, plus, buffer, sizeof(buffer)) != 0)
		*buffer = '\0';
	return(buffer);
}
#endif /* USE_DEPRECATED_DECSCI_FUNCTIONS */

/*	Format a scientific notation number */
int dec_sci(const ifx_dec_t *d, int ndigit, int plus, char *buffer, size_t buflen)
{
	char     *dst = buffer;
	char     *src;
	int       sn;
	int       dp;
	ifx_dec_t z;

	if (d->dec_pos == DECPOSNULL)
	{
		*dst = '\0';
		return(0);
	}

	ndigit = VALID(ndigit);
	src = dececvt(CONST_CAST(ifx_dec_t *, d), ndigit, &dp, &sn);
	*dst++ = SIGN(sn, plus);	/* Sign */
	*dst++ = *src++;			/* Digit before decimal point */
	*dst++ = '.';				/* Decimal point */
	while (*src)				/* Digits after decimal point */
		*dst++ = *src++;
	deccvdbl(0.0, &z);
	dst = dec_setexp(dst, dp - (deccmp(CONST_CAST(ifx_dec_t *, d), &z) != 0));	/* Exponent */
	return(0);
}

#ifdef TEST

#include <stdio.h>
#include <string.h>

#define DIM(x)	(sizeof(x)/sizeof(*(x)))

static char    *values[] =
{
 "0",
 "+3.14159265358979323844e+00",
 "-3.14159265358979323844e+01",
 " 3.14159265358979323844e+02",
 "+3.14159265358979323844e+03",
 "-3.14159265358979323844e+34",
 " 3.14159265358979323844e+68",
 "+3.14159265358979323844e+99",
 "-3.14159265358979323844e+100",
 " 9.99999999999999999999e+125",
 "+1.00000000000000000000e+126",
 "-3.14159265358979323844e+00",
 " 3.14159265358979323844e-01",
 "+3.14159265358979323844e-02",
 "-3.14159265358979323844e-03",
 " 3.14159265358979323844e-34",
 "+3.14159265358979323844e-68",
 "-3.14159265358979323844e-99",
 " 3.14159265358979323844e-100",
 "+3.14159265358979323844e-126",
 "-3.14159265358979323844e-127",
 " 1.00000000000000000000e-128",
 "+1.00000000000000000000e-129",
 "-1.00000000000000000000e-130",
 " 9.99999999999999999999e-131",
};

int main(void)
{
	char     *s;
	ifx_dec_t d;
	int       i;
	int       err;

	printf("\nScientific notation\n");
	printf("%-30s %s\n", "Input value", "Formatted");
	for (i = 0; i < DIM(values); i++)
	{
		if ((err = deccvasc(values[i], strlen(values[i]), &d)) != 0)
			printf("deccvasc error %d on %s\n", err, values[i]);
		else
		{
			s = decsci(&d, 6, i % 2);
			printf("%-30s :%s:\n", values[i], s);
		}
	}

	return(0);
}

#endif	/* TEST */
