#!/usr/bin/perl -w
#
#	@(#)$Id: t/t14bindcol.t version /main/1 2000-02-24 19:22:16 $ 
#
#	Test handling of bind_col and bind_columns for DBD::Informix
#
#	Copyright 2000 Informix Software Inc

use strict;
use DBD::Informix::TestHarness;

# Test install...
my ($dbh) = connect_to_test_database;

stmt_note "1..7\n";
stmt_ok;
my ($table) = "dbd_ix_bind_col";

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

{
# Insert data
my ($sth) = $dbh->prepare("INSERT INTO $table VALUES(0, ?, ?, ?, ?)");
stmt_fail unless $sth;
stmt_ok;

$sth->bind_param(1, 'Another value');
$sth->bind_param(2, 987654321);
$sth->bind_param(3, '1997-02-28 00:11:22.55555');
$sth->bind_param(4, 2.8128);
$sth->execute or stmt_fail;

# Check that there are now two rows of data, substantially different
$sth->execute('Different data', 88888888, '1900-01-01 00:00:00.00000', 0) or stmt_fail;

# Try some new bind values
$sth->bind_param(1, 'Some other data');
$sth->bind_param(4, 3.141593);
$sth->execute or stmt_fail;

# Try some more new bind values
$sth->bind_param(2, 123456789);
$sth->bind_param(3, '2000-02-29 23:59:59.99999');
$sth->execute or stmt_fail;
}

# Check that there are now four rows of data
select_some_data $dbh, 4, $select;

my ($col01, $col02, $col03, $col04, $col05);

my ($sth) = $dbh->prepare($select);
stmt_fail unless $sth;
stmt_ok;

$sth->bind_col(1, \$col01) or stmt_fail;
$sth->bind_col(2, \$col02) or stmt_fail;
$sth->bind_col(3, \$col03) or stmt_fail;
$sth->bind_col(4, \$col04) or stmt_fail;
$sth->bind_col(5, \$col05) or stmt_fail;
$sth->execute or stmt_fail;

while ($sth->fetch)
{
	stmt_note "# 1: $col01, 2: $col02, 3: $col03, 4: $col04, 5: $col05\n";
}

stmt_ok;

my ($val01, $val02, $val03, $val04, $val05);
$sth->bind_columns((\$val01, \$val02, \$val03, \$val04, \$val05)) or stmt_fail;
$sth->execute or stmt_fail;

while ($sth->fetch)
{
	stmt_note "# 1: $val01, 2: $val02, 3: $val03, 4: $val04, 5: $val05\n";
}

stmt_ok;

&all_ok();
