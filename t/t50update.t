#!/usr/bin/perl -w
#
# @(#)$Id: t50update.t,v 60.1 1998/07/30 04:46:50 jleffler Exp $
#
# Copyright (C) 1998 Jonathan Leffler (johnl@informix.com)
#
# Test for UPDATE on zero rows in MODE ANSI database.
# Note that database statements cannot be used with an explicit connection
# with ESQL/C 6.0x and up.

use DBD::InformixTest qw(stmt_ok stmt_fail stmt_note all_ok stmt_test
                         stmt_err select_some_data);

$dbname = "dbd_ix_db";

stmt_note("1..9\n");

&stmt_note("# Use explicit default connection, new connect syntax\n");
stmt_fail unless ($dbh = DBI->connect('dbi:Informix:.DEFAULT.','',''));
stmt_ok;

# Don't care about non-existent database
$dbh->{ix_AutoErrorReport} = 0;
$dbh->do("drop database $dbname");

$selver = "SELECT TabName, Owner FROM 'informix'.SysTables WHERE TabName = ' VERSION'";

my($create);
if ($dbh->{ix_InformixOnLine})
{
	$create = "create database $dbname with log mode ansi";
}
else
{
	$create = "create database $dbname with log in '/tmp/$dbname.log' mode ansi";
}

$dbh->{ix_AutoErrorReport} = 1;
stmt_test($dbh, $create);
select_some_data($dbh, 1, $selver);
if ($dbname ne $dbh->{ix_DatabaseName})
{
	stmt_err("Incorrect database name recorded ('$dbh->{ix_DatabaseName}' should be '$dbname')\n");
	stmt_fail;
}
stmt_test($dbh, "create table empty (col integer not null)");
stmt_test($dbh, "update empty set col = col * 2 where 1 = 0");
stmt_test($dbh, "commit work");
stmt_test($dbh, "close database");
if ($dbh->{ix_DatabaseName})
{
	stmt_err("Incorrect database name recorded ('$dbh->{ix_DatabaseName}' should be an empty string)\n");
	stmt_fail;
}
stmt_test($dbh, "drop database $dbname");
stmt_note("# Disconnect\n");
stmt_fail unless ($dbh->disconnect);
stmt_ok;

&all_ok();
