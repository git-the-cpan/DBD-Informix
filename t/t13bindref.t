#!/usr/bin/perl -w
#
#	@(#)$Id: t/t13bindref.t version /main/2 2000-02-29 15:43:34 $ 
#
#	Test handling of bind_param_inout for DBD::Informix
#
#	Copyright 2000 Informix Software Inc

use strict;
use DBD::Informix::TestHarness;

# Currently, bind_param_inout is not supported by DBD::Informix
stmt_note "1..0\n";
exit;

# Test install...
my ($dbh) = connect_to_test_database;

stmt_note "1..7\n";
stmt_ok;
my ($table) = "dbd_ix_bind_param";

# Create table for testing
stmt_test $dbh, qq{
CREATE TEMP TABLE $table
(
	Col01	SERIAL(1000) NOT NULL,
	Col02	CHAR(20) NOT NULL,
	Col03	INTEGER NOT NULL,
	Col04	DATETIME YEAR TO FRACTION(5) NOT NULL,
	Col05   DECIMAL NOT NULL
)
};

my ($select) = "SELECT * FROM $table";

# Insert a row of values.
my ($sth) = $dbh->prepare("INSERT INTO $table VALUES(0, ?, ?, ?, ?)");
&stmt_fail() unless $sth;
&stmt_ok;

my ($col02, $col03, $col04, $col05);

$sth->bind_param_inout(1, \$col02, 30);
$sth->bind_param_inout(2, \$col03, 30);
$sth->bind_param_inout(3, \$col04, 30);
$sth->bind_param_inout(4, \$col05, 30);

$col02 = 'Another value';
$col03 = 987654321;
$col04 = '1997-02-28 00:11:22.55555';
$col05 = 2.8128;

&stmt_fail() unless $sth->execute;

# Check that there is one row of data
select_some_data $dbh, 1, $select;

# Check that there are now two rows of data, substantially the same
&stmt_fail() unless $sth->execute;
select_some_data $dbh, 2, $select;

# Try some new bind values
$col02 = 'Some other data';
$col05 = 3.141593;
&stmt_fail() unless $sth->execute;

# Check that there are now three rows of data
select_some_data $dbh, 3, $select;

# Try some more new bind values
$col03 = 123456789;
$col03 = '2000-02-29 23:59:59.99999';
&stmt_fail() unless $sth->execute;

# Check that there are now four rows of data
select_some_data $dbh, 4, $select;

&all_ok();
