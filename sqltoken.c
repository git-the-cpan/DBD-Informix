/*
@(#)Purpose:         Identify SQL token in string
@(#)Author:          J Leffler
@(#)Copyright:       1998-99 Jonathan Leffler (JLSS)
@(#)Copyright:       2002    IBM
@(#)Product:         IBM Informix Database Driver for Perl Version 2003.03.0400 (2003-03-04)
*/

/*TABSTOP=4*/

#include <assert.h>
#include <ctype.h>
#include <string.h>

#include "esqlutil.h"

#define LCURLY '{'
#define RCURLY '}'

#ifndef lint
static const char rcs[] = "@(#)$Id: sqltoken.c,v 100.2 2002/12/06 22:18:23 jleffler Exp $";
#endif

/*
** sqltoken() - get SQL token
**
** Returns pointer to start of next SQL token (keyword, string,
** punctuation) in given string, or pointer to null at end of string if
** there is none.  The end of the token is in the end parameter.
*/
char *sqltoken(char *input, char **end)
{
	char *token;
	unsigned char  c;
	unsigned char  q;

	while (*input != '\0')
	{
		while ((c = *input) != '\0' && isspace(c))
			input++;
		if ((c = *input) == LCURLY && *(input + 1) == '+')
		{
			/* Optimizer hint; treat as symbol */
			if ((token = strchr(input, RCURLY)) == 0)
				break;
			*end = token + 1;
			return input;
		}
		else if ((c = *input) == LCURLY)
		{
			/* Routine comment -- ignore */
			if ((token = strchr(input, RCURLY)) == 0)
				break;
			input = token + 1;
		}
		else if ((c == '#') || (*input == '-' && *(input + 1) == '-'))
		{
			if ((token = strchr(input + 1, '\n')) == 0)
				break;
			input = token + 1;
		}
		else if (c == '\'' || c == '"')
		{
			char *str;
			token = input;
			str = token + 1;
			q = c;
			/* Ignores newlines in quoted strings! */
			/* Does handle adjacent doubled quotes */
			while ((str = strchr(str, q)) != 0)
			{
				if (*(str + 1) != q)
				{
					*end = str + 1;
					return token;
				}
				str += 2;
			}
			break;
		}
		else if (isdigit(c) || (c == '.' && isdigit((unsigned char)input[1])))
		{
			/* Intelligent number parsing */
			/* Handles unsigned integers, fixed point, */
			/* and exponental (1E+32) notation */
			token = input;
			if (c == '.')
				input++;
			while ((c = *input++) != '\0' && isdigit(c))
				;
			if (c == '.')
			{
				while ((c = *input++) != '\0' && isdigit(c))
					;
			}
			if (c == 'e' || c == 'E')
			{
				/* Maybe exponential notation -- in fact should be... */
				if (isdigit((unsigned char)*input) ||
					((*input == '+' || *input == '-') && isdigit((unsigned char)input[1])))
				{
					if ((c = *input++) == '+' || c == '-')
						input++;
					while ((c = *input++) != '\0' && isdigit(c))
						;
				}
			}
			*end = input - 1;
			return token;
		}
		else if (isalpha(c) || c == '_')
		{
			/* Word */
			token = input;
			while ((c = *input++) != '\0' && (isalnum(c) || c == '_'))
				;
			*end = input - 1;
			return token;
		}
		else
		{
			/* Punctuation - symbols */
			token = input++;
			/* Only compound symbols known are: <> != <= >= || :: (used in IUS) */
			/* Any other punctuation character is a single token */
			if (*input != '\0' && (c == '<' || c == '!' || c == '|' || c == '>' || c == ':'))
			{
				switch (c)
				{
				case '<':
					if (*input == '>' || *input == '=')
						input++;
					break;
				case '>':
					if (*input == '=')
						input++;
					break;
				case '!':
					if (*input == '=')
						input++;
					break;
				case '|':
					if (*input == '|')
						input++;
					break;
				case ':':
					if (*input == ':')
						input++;
					break;
				default:
					assert(0);
					break;
				}
			}
			*end = input;
			return token;
		}
	}
	*end = input;
	return(input);
}

#ifdef TEST

#include <stdio.h>

#define DIM(x)	(sizeof(x)/sizeof(*(x)))

static char *input[] =
{
	"SELECT * FROM SysTables",
	"SELECT { * } Tabid FROM SysTables",
	"SELECT -- * \n Tabid FROM SysTables",
	"SELECT #- * \n Tabid FROM SysTables",
	"SELECT a+b FROM 'informix'.systables",
	"SELECT a+1 AS\"a\"\"b\",a+1.23AS'a''b2'FROM db@server:\"user\".table\n"
		"WHERE (x+2 UNITS DAY)>=(DATETIME(1998-12-23 13:12:10) YEAR TO SECOND-1 UNITS DAY)\n"
		"  AND t<+3.14159E+32\n",
	"SELECT a.--this should be in comment and invisible\n"
		"b FROM SomeDbase:{this should be in comment and invisible too}\n"
		"user.#more commentary\n\t\ttablename",
	"SELECT (a>=<=<>!=||...(b)) FROM Nowhere",
	"{cc}-1{c}+1{c}.1{c}-.1{c}+.1{}-1.2E3{c}+1.23E+4{c}-1.234e-56",
	"info columns for 'cdhdba'.cdh_user",
	"select a::type as _ from _",
	"select {+ hint} _ as _ from _",
};

int main(void)
{
	int i;
	int n;
	char *str;
	char *src;
	char *end;
	char  buffer[2048];

	for (i = 0; i < DIM(input); i++)
	{
		str = input[i];
		printf("Data: <<%s>>\n", str);
		while (*(src = sqltoken(str, &end)) != '\0' && src != end)
		{
			strncpy(buffer, src, end - src);
			buffer[end - src] = '\0';
			n++;
			printf("Token: <<%s>>\n", buffer);
			str = end;
		}
	}
	return 0;
}

#endif /* TEST */
