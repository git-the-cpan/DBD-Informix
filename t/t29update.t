#!/usr/bin/perl -w
#
#   @(#)$Id: t29update.t,v 2003.2 2003/01/03 19:02:36 jleffler Exp $
#
#   Simple test for UPDATE with attributes listed in execute call
#
#   Copyright 1998-99 Jonathan Leffler
#   Copyright 2000    Informix Software Inc
#   Copyright 2002-03 IBM

use DBD::Informix::TestHarness;
use strict;

&stmt_note("1..3\n");

my $tabname = "dbd_ix_t1";

my $dbh = connect_to_test_database();

$dbh->{RaiseError} = 1;
$dbh->do(qq"CREATE TEMP TABLE $tabname(c1 INTEGER, c2 INTEGER, c3 INTEGER)");
$dbh->do(qq"INSERT INTO $tabname VALUES(1, 2, 3)");
my $sth = $dbh->prepare("UPDATE $tabname SET (c1, c2) = (?, ?) WHERE c3 = ?");

my $sel = $dbh->prepare("SELECT * FROM $tabname") or stmt_fail;

$sel->execute;
validate_unordered_unique_data($sel, 'c1', {  1 => { 'c1' =>  1, 'c2' =>  2, 'c3' => 3 } });

my @vals = (55, 66, 3);
$sth->execute(@vals);

$sel->execute;
validate_unordered_unique_data($sel, 'c2', { 66 => { 'c1' => 55, 'c2' => 66, 'c3' => 3 } });

$sth->execute(12, 14, 3);

$sel->execute;
validate_unordered_unique_data($sel, 'c3', {  3 => { 'c1' => 12, 'c2' => 14, 'c3' => 3 } });

$dbh->disconnect;

&all_ok;

