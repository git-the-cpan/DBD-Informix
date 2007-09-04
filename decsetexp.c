/*
@(#)File:           $RCSfile: decsetexp.c,v $
@(#)Version:        $Revision: 2.2 $
@(#)Last changed:   $Date: 2005/01/12 19:30:52 $
@(#)Purpose:        Format the exponent of a DECIMAL
@(#)Author:         J Leffler
@(#)Copyright:      (C) JLSS 2001,2005
@(#)Product:        IBM Informix Database Driver for Perl DBI Version 2007.0904 (2007-09-04)
*/

/*TABSTOP=4*/

#include "decintl.h"

#ifndef lint
static const char rcs[] = "@(#)$Id: decsetexp.c,v 2.2 2005/01/12 19:30:52 jleffler Exp $";
#endif

/* Format an exponent */
char    *dec_setexp(char  *dst, int dp)
{
	*dst++ = 'E';
	if (dp >= 0)
		*dst++ = '+';
	else
	{
		*dst++ = '-';
		dp = -dp;
	}
	if (dp / 100 != 0)
		*dst++ = dp / 100 + '0';
	*dst++ = (dp / 10) % 10 + '0';
	*dst++ = (dp % 10) + '0';
	if (dp / 100 == 0)
		*dst++ = ' ';
	*dst = '\0';
	return(dst);
}

#ifdef TEST

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define DIM(x) (sizeof(x)/sizeof(*(x)))

typedef struct Test
{
	int		val;
	char	*res;
}	Test;

static Test test[] =
{
	{	0,		"E+00 "	},
	{	-1,		"E-01 "	},
	{	-2,		"E-02 "	},
	{	-3,		"E-03 "	},
	{	-10,	"E-10 "	},
	{	-20,	"E-20 "	},
	{	-99,	"E-99 "	},
	{	-100,	"E-100"	},
	{	-120,	"E-120"	},
	{	+1,		"E+01 "	},
	{	+2,		"E+02 "	},
	{	+3,		"E+03 "	},
	{	+10,	"E+10 "	},
	{	+20,	"E+20 "	},
	{	+99,	"E+99 "	},
	{	+100,	"E+100"	},
	{	+120,	"E+120"	},
};

int main(void)
{
	int i;
	int fail = 0;

	for (i = 0; i < DIM(test); i++)
	{
		char buffer[10];
		dec_setexp(buffer, test[i].val);
		if (strcmp(test[i].res, buffer) != 0)
		{
			fail++;
			printf("** FAIL ** in = %d, got <%s>, wanted <%s>\n", test[i].val,
					buffer, test[i].res);
		}
	}
	if (fail == 0)
		printf("== PASS == %d tests\n", i);
	else
		printf("== FAIL == %d tests failed out of %d total\n", fail, i);
	return(fail == 0 ? EXIT_SUCCESS : EXIT_FAILURE);
}

#endif /* TEST */
