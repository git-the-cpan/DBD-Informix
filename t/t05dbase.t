#!/usr/bin/perl -w
#
# @(#)$Id: t05dbase.t,v 62.1 1999/09/19 21:18:32 jleffler Exp $ 
#
#	Copyright (C) 1997,1999 Jonathan Leffler
#
# Test database creation and default connections.
# Note that database statements cannot be used with an explicit connection
# with ESQL/C 6.0x and up.

BEGIN { require "perlsubs/InformixTest.pl"; }

$dbname = "dbd_ix_db";

stmt_note("1..19\n");

# Do not want these defaults to affect testing (in this file only).
delete $ENV{DBI_DSN};
delete $ENV{DBI_DBNAME};

&stmt_note("# Test (implicit default) DBI->connect('',...)\n");
stmt_fail unless ($dbh = DBI->connect('','','','Informix'));
stmt_ok;

# Don't care about non-existent database
$dbh->{PrintError} = 0;
$dbh->do("drop database $dbname");

$selver = "SELECT TabName, Owner FROM 'informix'.SysTables WHERE TabName = ' VERSION'";

$dbh->{PrintError} = 1;
&stmt_test($dbh, "create database $dbname");
&select_some_data($dbh, 1, $selver);
&stmt_test($dbh, "close database");
&stmt_test($dbh, "drop database $dbname");
stmt_fail unless ($dbh->disconnect);
stmt_ok;

undef $dbh;

&stmt_note("# Test (explicit default) DBI->connect('.DEFAULT.',...)\n");
stmt_fail unless ($dbh = DBI->connect('.DEFAULT.','','','Informix'));
stmt_ok;

$dbh->{PrintError} = 1;
&stmt_test($dbh, "create database $dbname");
&select_some_data($dbh, 1, $selver);
&stmt_test($dbh, "close database");
&stmt_test($dbh, "drop database $dbname");
stmt_fail unless ($dbh->disconnect);
stmt_ok;

# Test disconnecting implicit connections (B42204)
&stmt_note("# Test (explicit default) DBI->connect('.DEFAULT.',...)\n");
stmt_fail unless ($dbh = DBI->connect('.DEFAULT.','','','Informix'));
stmt_ok;
$dbh->{PrintError} = 1;
&stmt_test($dbh, "create database $dbname");
&select_some_data($dbh, 1, $selver);
&stmt_note("# Test disconnect on DEFAULT connection\n");
stmt_fail unless ($dbh->disconnect);
stmt_ok;

# Clean up test database
&stmt_note("# Clean up test database\n");
stmt_fail unless ($dbh = DBI->connect('.DEFAULT.','','','Informix'));
stmt_ok;
&stmt_test($dbh, "drop database $dbname");
stmt_fail unless ($dbh->disconnect);
stmt_ok;

&all_ok();