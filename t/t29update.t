#!/usr/bin/perl -w
#
#	@(#)$Id: t29update.t,v 100.3 2002/02/08 22:50:47 jleffler Exp $ 
#
#	Simple test for UPDATE with attributes listed in execute call
#
#	Copyright 1998-99 Jonathan Leffler
#	Copyright 2000    Informix Software Inc
#	Copyright 2002    IBM

use DBD::Informix::TestHarness;

&stmt_note("1..3\n");

my $tabname = "dbd_ix_t1";

my $dbh = connect_to_test_database();

$dbh->{RaiseError} = 1;
$dbh->do(qq"CREATE TEMP TABLE $tabname(c1 INTEGER, c2 INTEGER, c3 INTEGER)");
$dbh->do(qq"INSERT INTO $tabname VALUES(1, 2, 3)");
my $sth = $dbh->prepare("UPDATE $tabname SET (c1, c2) = (?, ?) WHERE c3 = ?");

&stmt_note("# Values should be 1 2 3\n");
&select_some_data($dbh, 1, "SELECT * FROM $tabname");
@vals = (55, 66, 3);
$sth->execute(@vals);

&select_some_data($dbh, 1, "SELECT * FROM $tabname");
&stmt_note("# Values should be @vals\n");

$sth->execute(12, 14, 3);
&select_some_data($dbh, 1, "SELECT * FROM $tabname");
&stmt_note("# Values should be 12 14 3\n");

$dbh->disconnect;

&all_ok;

