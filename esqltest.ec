/*
 * @(#)$Id: esqltest.ec,v 56.4 1997/07/08 21:56:43 johnl Exp $ 
 *
 * DBD::Informix for Perl Version 5 -- Test Informix-ESQL/C environment
 *
 * Copyright (c) 1997 Jonathan Leffler
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 */

/*TABSTOP=4*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "esqlperl.h"

#ifndef __STDC__
/* Using this is more reliable than using #error */
error "Please read the README file, and Makefile.PL, and get __STDC__ defined"
#endif /* __STDC__ */

/* SunOS 4.1.3 <stdlib.h> does not provide EXIT_SUCCESS/EXIT_FAILURE */
#ifndef EXIT_FAILURE
#define EXIT_FAILURE 1
#endif
#ifndef EXIT_SUCCESS
#define EXIT_SUCCESS 0
#endif

static int estat = EXIT_SUCCESS;

#ifndef lint
static const char rcs[] = "@(#)$Id: esqltest.ec,v 56.4 1997/07/08 21:56:43 johnl Exp $";
#endif

/*
** Various people ran into problems testing DBD::Informix because the
** basic Informix environment was not set up correctly.
** This code was written as a self-defense measure to try and ensure
** that DBD::Informix had some chance of being tested successfully
** before the tests are run.
*/

/* Format and print an Informix error message (both SQL and ISAM parts) */
void            ix_printerr(FILE *fp, long rc)
{
	char            errbuf[256];
	char            fmtbuf[256];
	char            sql_buf[256];
	char            isambuf[256];
	char            msgbuf[sizeof(sql_buf)+sizeof(isambuf)];

	if (rc < 0)
	{
		/* Format SQL (primary) error */
		if (rgetmsg(rc, errbuf, sizeof(errbuf)) != 0)
			strcpy(errbuf, "<<Failed to locate SQL error message>>");
		sprintf(fmtbuf, errbuf, sqlca.sqlerrm);
		sprintf(sql_buf, "SQL: %ld: %s", rc, fmtbuf);

		/* Format ISAM (secondary) error */
		if (sqlca.sqlerrd[1] != 0)
		{
			if (rgetmsg(sqlca.sqlerrd[1], errbuf, sizeof(errbuf)) != 0)
				strcpy(errbuf, "<<Failed to locate ISAM error message>>");
			sprintf(fmtbuf, errbuf, sqlca.sqlerrm);
			sprintf(isambuf, "ISAM: %ld: %s", sqlca.sqlerrd[1], fmtbuf);
		}
		else
			isambuf[0] = '\0';

		/* Concatenate SQL and ISAM messages */
		/* Note that the messages have trailing newlines */
		strcpy(msgbuf, sql_buf);
		strcat(msgbuf, isambuf);

		/* Record error number and error message */
		fprintf(fp, "%s\n", msgbuf);

		/* Set exit status */
		estat = EXIT_FAILURE;
	}
}

static void test_permissions(char *dbname)
{
	EXEC SQL CREATE TABLE dbd_ix_esqltest (Col01 INTEGER NOT NULL);
	if (sqlca.sqlcode < 0)
	{
		fprintf(stderr, "You cannot use %s as a test database.\n", dbname);
		fprintf(stderr, "You do not have sufficient privileges.\n");
		ix_printerr(stderr, sqlca.sqlcode);
		estat = EXIT_FAILURE;
	}
	else
	{
		EXEC SQL DROP TABLE dbd_ix_esqltest;
		if (sqlca.sqlcode < 0)
		{
			fprintf(stderr, "Failed to drop table dbd_ix_esqltest in database %s\n", dbname);
			fprintf(stderr, "Please remove it manually.\n");
			ix_printerr(stderr, sqlca.sqlcode);
		}
	}
	/*
	** Ignore any errors on rollback.
	** The ROLLBACK (or a COMMIT) is necessary if $DBD_INFORMIX_DATABASE is
	** a MODE ANSI database and DBD_INFORMIX_DATABASE2 is either unset or
	** set to the same database.
	** Problem found by Kent S. Gordon (kgor@inetspace.com).
	*/
	EXEC SQL ROLLBACK WORK;
}

void dbd_ix_debug(int level, char *fmt, const char *arg)
{
	putchar('\t');
	printf(fmt, arg);
}

void dbd_ix_debug_l(int level, char *fmt, long arg)
{
	putchar('\t');
	printf(fmt, arg);
}

int main(int argc, char **argv)
{
	/* Command-line arguments are ignored at the moment */
	char *dbidsn = getenv("DBI_DSN");
	char *dbase0 = getenv("DBI_DBNAME");
	char *dbase1 = getenv("DBD_INFORMIX_DATABASE");
	char *dbase2 = getenv("DBD_INFORMIX_DATABASE2");
	char *user = getenv("DBD_INFORMIX_USERNAME");
	char *pass =  getenv("DBD_INFORMIX_PASSWORD");
	char *server =  getenv("DBD_INFORMIX_SERVER");
	char  dbname[60];
	Boolean conn_ok;
	static char  conn1[20] = "connection_1";
	static char  conn2[20] = "connection_2";

	/* Check whether the default connection variable is set */
	if (dbidsn != 0 && *dbidsn != '\0')
	{
		printf("\tFYI: $DBI_DSN is set to '%s'.\n", dbidsn);
		printf("\t\tIt is not used by any of the DBD::Informix tests.\n");
		printf("\t\tIt is unset by the tests which would otherwise break.\n");
	}

	/* Set the basic default database name */
	if (dbase0 == 0 || *dbase0 == '\0')
	{
		dbase0 = "stores";
		printf("\t$DBI_DBNAME unset - defaulting to '%s'.\n", dbase0);
	}
	else
	{
		printf("\t$DBI_DBNAME set to '%s'.\n", dbase0);
	}

	/* Test for the explicit DBD::Informix database */
	if (dbase1 == 0 || *dbase1 == '\0')
	{
		dbase1 = dbase0;
		printf("\t$DBD_INFORMIX_DATABASE unset - defaulting to '%s'.\n", dbase1);
	}
	else
		printf("\t$DBD_INFORMIX_DATABASE set to '%s'.\n", dbase1);

	/* Test for the secondary database for multi-connection testing */
	if (dbase2 == 0 || *dbase2 == '\0')
	{
		dbase2 = dbase1;
		printf("\t$DBD_INFORMIX_DATABASE2 unset - defaulting to '%s'.\n", dbase2);
	}
	else
		printf("\t$DBD_INFORMIX_DATABASE2 set to '%s'.\n", dbase2);

	/* Test whether the server name should be set. */
	if (server == 0 || *server == '\0')
	{
		server = getenv("INFORMIXSERVER");
		if (server == 0 || *server == '\0')
			printf("\t$DBD_INFORMIX_SERVER and $INFORMIXSERVER both unset - no default.\n");
		else
			printf("\t$DBD_INFORMIX_SERVER unset - defaulting to $INFORMIXSERVER '%s'.\n", server);
	}
	else
		printf("\t$DBD_INFORMIX_SERVER set to '%s'.\n", server);

	/* Convert to dbase@server notation if appropriate */
	if (strpbrk(dbase1, "/@") == 0 && server != 0 && *server != '\0')
	{
		sprintf(dbname, "%s@%s", dbase1, server);
		dbase1 = dbname;
	}

	/* Report whether username is set, and what it is */
	if (user == 0 || *user == '\0')
		printf("\t$DBD_INFORMIX_USERNAME is unset.\n");
	else
		printf("\t$DBD_INFORMIX_USERNAME is set to '%s'.\n", user);

	/* Report whether password is set, but not what it is */
	if (pass == 0 || *pass == '\0')
		printf("\t$DBD_INFORMIX_PASSWORD is unset.\n");
	else
		printf("\t$DBD_INFORMIX_PASSWORD is set.\n");

	printf("Testing connection to %s\n", dbase1);
#if ESQLC_VERSION >= 600
    /* 6.00 and later versions of Informix-ESQL/C support CONNECT */
	printf("\tDBD_INFORMIX_USERNAME & DBD_INFORMIX_PASSWORD are ignored\n");
	printf("\t\tunless both variables are set.\n");
    conn_ok = dbd_ix_connect(conn1, dbase1, user, pass);
#else
    /* Pre-6.00 versions of Informix-ESQL/C do not support CONNECT */
    /* Use DATABASE statement */
	printf("\tDBD_INFORMIX_USERNAME & DBD_INFORMIX_PASSWORD are ignored.\n");
    conn_ok = dbd_ix_opendatabase(dbase1);
#endif  /* ESQLC_VERSION >= 600 */

	if (sqlca.sqlcode < 0)
	{
		ix_printerr(stderr, sqlca.sqlcode);
	}
	else
		test_permissions(dbase1);

#if ESQLC_VERSION >= 600
	printf("Testing concurrent connection to %s\n", dbase2);
    /* 6.00 and later versions of Informix-ESQL/C support CONNECT */
    conn_ok = dbd_ix_connect(conn2, dbase2, user, pass);
#else
    /* Pre-6.00 versions of Informix-ESQL/C do not support CONNECT */
    /* Use DATABASE statement */
	printf("Testing connection to %s\n", dbase2);
    conn_ok = dbd_ix_opendatabase(dbase2);
#endif  /* ESQLC_VERSION >= 600 */

	if (sqlca.sqlcode < 0)
	{
		ix_printerr(stderr, sqlca.sqlcode);
	}
	else
		test_permissions(dbase2);

	if (estat == EXIT_SUCCESS)
		printf("Your Informix environment is OK\n\n");
	else
	{
		printf("\n*** Your Informix environment is not usable");
		printf("\n*** You must fix it before building or testing DBD::Informix\n\n");
	}
	return(estat);
}
