#!/usr/bin/perl -w
#
# @(#)$Id: unlogged.t,v 56.4 1997/11/18 06:04:21 johnl Exp $ 
#
# Copyright (C) 1997 Jonathan Leffler (johnl@informix.com)
#
# Test that unlogged databases refuse to connect with AutoCommit => 0

use DBD::InformixTest qw(stmt_ok stmt_fail stmt_note all_ok stmt_test
select_some_data);

$dbname = "dbd_ix_db";

stmt_note("1..8\n");

&stmt_note("# Test DBI->connect('dbi:Informix:.DEFAULT.')\n");
stmt_fail unless ($dbh = DBI->connect('dbi:Informix:.DEFAULT.'));
stmt_ok;

# Don't care about non-existent database
$dbh->{ix_AutoErrorReport} = 0;
$dbh->do("drop database $dbname");

$selver = "SELECT TabName, Owner FROM 'informix'.SysTables WHERE TabName = ' VERSION'";

$dbh->{ix_AutoErrorReport} = 1;
&stmt_note("# Create unlogged database $dbname\n");
&stmt_test($dbh, "create database $dbname");
&select_some_data($dbh, 1, $selver);
&stmt_test($dbh, "close database");
stmt_fail unless ($dbh->disconnect);
stmt_ok;
undef $dbh;

&stmt_note("# Test DBI->connect('dbi:Informix:$dbname',...,{AutoCommit=>0})\n");
$dbh = DBI->connect("dbi:Informix:$dbname",'','',
					{ AutoCommit => 0, PrintError => 1 });
# Under DBI 0.85, this connection worked.  Ideally it should have failed.
# Under DBI 0.90, this connection fails, as it is supposed to!
&stmt_ok if (!defined $dbh);

# Remove test database
stmt_fail unless ($dbh = DBI->connect('dbi:Informix:.DEFAULT.'));
$dbh->{ix_AutoErrorReport} = 1;
&stmt_test($dbh, "drop database $dbname");
stmt_fail unless ($dbh->disconnect);
stmt_ok;

&all_ok();
