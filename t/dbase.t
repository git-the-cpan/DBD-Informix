#!/usr/bin/perl -w
#
# @(#)dbase.t	55.1 97/05/20 11:06:27
#
# Copyright (C) 1997 Jonathan Leffler (johnl@informix.com)
#
# Test database creation
# Note that database statements cannot be used with an explicit connection
# with ESQL/C 6.0x and up.

use DBD::InformixTest qw(stmt_ok stmt_fail stmt_note all_ok stmt_test);

$dbname = "dbd_ix_db";

stmt_note("1..10\n");

stmt_fail unless ($dbh = DBI->connect('','','','Informix'));
stmt_ok;

# Don't care about non-existent database
$dbh->{ix_AutoErrorReport} = 0;
$dbh->do("drop database $dbname");

$dbh->{ix_AutoErrorReport} = 1;
&stmt_test($dbh, "create database $dbname");
&stmt_test($dbh, "close database");
&stmt_test($dbh, "drop database $dbname");
stmt_fail unless ($dbh->disconnect);
stmt_ok;

undef $dbh;

stmt_fail unless ($dbh = DBI->connect('.DEFAULT.','','','Informix'));
stmt_ok;

$dbh->{ix_AutoErrorReport} = 1;
stmt_fail unless ($dbh->do("create database $dbname"));
stmt_ok;
stmt_fail unless ($dbh->do("close database"));
stmt_ok;
stmt_fail unless ($dbh->do("drop database $dbname"));
stmt_ok;
stmt_fail unless ($dbh->disconnect);
stmt_ok;

&all_ok();
