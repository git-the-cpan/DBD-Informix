#!/usr/bin/perl -w
#
#	@(#)$Id: t29update.t,v 60.1 1998/07/30 00:26:44 jleffler Exp $ 
#
#	Simple test for UPDATE with attributes listed in execute call
#
#	Copyright (C) 1998 Jonathan Leffler

use DBD::InformixTest;

&stmt_note("1..2\n");

$dbh = connect_to_test_database();

$dbh->do(qq"CREATE TEMP TABLE T1(c1 INTEGER, c2 INTEGER, c3 INTEGER)");
$dbh->do(qq"INSERT INTO T1 VALUES(1, 2, 3)");
$sth = $dbh->prepare("UPDATE T1 SET (c1, c2) = (?, ?) WHERE c3 = ?");

&stmt_note("# Values should be 1 2 3\n");
&select_some_data($dbh, 1, "SELECT * FROM T1");
@vals = (55, 66, 3);
$sth->execute(@vals);

&select_some_data($dbh, 1, "SELECT * FROM T1");

&stmt_note("# Values should be @vals\n");

&all_ok;

