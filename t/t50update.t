#!/usr/bin/perl -w
#
#   @(#)$Id: t50update.t,v 2003.3 2003/01/04 00:36:38 jleffler Exp $
#
#   Test for UPDATE on zero rows in MODE ANSI database.
#
#   Copyright 1998-99 Jonathan Leffler
#   Copyright 2000    Informix Software Inc
#   Copyright 2002-03 IBM
#
# Note that database statements cannot be used with an explicit connection
# with ESQL/C 6.0x and up.

use DBD::Informix::TestHarness;
use strict;

my ($dbname) = "dbd_ix_db";
my ($user) = $ENV{DBD_INFORMIX_USERNAME};
my ($pass) = $ENV{DBD_INFORMIX_PASSWORD};
my ($dbh);

stmt_note("1..10\n");

&stmt_note("# Use explicit default connection, new connect syntax\n");
stmt_fail unless ($dbh = DBI->connect('dbi:Informix:.DEFAULT.',$user,$pass));
stmt_ok;

# Do not report non-existent database
$dbh->{PrintError} = 0;
$dbh->do("drop database $dbname");

my $selver = "SELECT TabName, Owner FROM 'informix'.SysTables WHERE TabID = 1";

my($create);
if ($dbh->{ix_InformixOnLine})
{
	$create = "create database $dbname with log mode ansi";
}
else
{
	$create = "create database $dbname with log in '/tmp/$dbname.log' mode ansi";
}

my $result = { 'systables' => { 'owner' => 'informix', 'tabname' => 'systables' } };

$dbh->{PrintError} = 1;
$dbh->{ChopBlanks} = 1;
stmt_test($dbh, $create);
my $sth = $dbh->prepare($selver) or stmt_fail;
stmt_ok;
$sth->execute ? validate_unordered_unique_data($sth, 'tabname', $result) : &stmt_nok;

if ($dbname ne $dbh->{ix_DatabaseName})
{
	stmt_err("Incorrect database name recorded ('$dbh->{ix_DatabaseName}' should be '$dbname')\n");
	stmt_fail;
}
stmt_test($dbh, "create table empty (col integer not null)");
stmt_test($dbh, "update empty set col = col * 2 where 1 = 0");
stmt_fail unless $dbh->{ix_sqlcode} == 100;
print_sqlca($dbh);
stmt_test($dbh, "commit work");
stmt_test($dbh, "close database");
if ($dbh->{ix_DatabaseName})
{
	stmt_err("Incorrect database name recorded ('$dbh->{ix_DatabaseName}' should be an empty string)\n");
	stmt_fail;
}
stmt_test($dbh, "drop database $dbname");
stmt_note("# Disconnect\n");
$dbh->disconnect ? &stmt_ok : &stmt_fail;

&all_ok();
