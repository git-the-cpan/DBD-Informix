#!/usr/bin/perl -w
#
#   @(#)$Id: t95int8.t,v 2004.1 2004/12/02 21:54:46 jleffler Exp $
#
#   Test handling of INT8/SERIAL8
#
#   Based on problem report by Steve Vornbrock <stevev@wamnet.com>.
#
#   Copyright 2003 Steve Vornbrock
#   Copyright 2003 IBM

use strict;
use DBD::Informix::TestHarness;
use DBD::Informix qw(:ix_types);

my $dbh = &test_for_ius;
&stmt_note("1..2\n");

my $bignum1 = 4278190080;
my $table = "dbd_ix_testint8";

$dbh->do(qq%CREATE TEMP TABLE $table(id INT8)%);

my $sth = $dbh->prepare(qq%INSERT INTO $table VALUES(?)%);

# JL 2003-07-15: Unfixed bug in DBD::Informix - bound types should be sticky!
&stmt_note("# Big number 1 = $bignum1\n");
$sth->bind_param(1, $bignum1, {ix_type => IX_INT8 });
$sth->execute();

my $bignum2 = $bignum1 * 23581;
&stmt_note("# Big number 2 = $bignum2\n");
$sth->execute($bignum2);
stmt_ok;

$sth = $dbh->prepare(qq%SELECT id FROM $table%);

my $row1 = { 'id' => $bignum1 };
my $row2 = { 'id' => $bignum2 };
my $res2 = { $bignum1 => $row1, $bignum2 => $row2 };

$sth->execute ?  validate_unordered_unique_data($sth, 'id', $res2) : &stmt_nok;

$dbh->disconnect;

all_ok;

__END__


$dbh->{RaiseError} = 1;
$dbh->do(qq"CREATE TEMP TABLE $tabname(c1 INTEGER, c2 INTEGER, c3 INTEGER)");
$dbh->do(qq"INSERT INTO $tabname VALUES(1, 2, 3)");
my $sth = $dbh->prepare("UPDATE $tabname SET (c1, c2) = (?, ?) WHERE c3 = ?");

my $sel = $dbh->prepare("SELECT * FROM $tabname") or stmt_fail;

$sel->execute;
validate_unordered_unique_data($sel, 'c1', {  1 => { 'c1' =>  1, 'c2' =>  2, 'c3' => 3 } });


