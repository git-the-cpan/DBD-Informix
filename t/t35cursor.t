#!/usr/bin/perl -w
#
#	@(#)$Id: t35cursor.t,v 100.2 2002/02/12 22:47:43 jleffler Exp $ 
#
#	Test handling of cursors and cursor states
#
#	Copyright 2002 IBM

use strict;
use DBD::Informix::TestHarness;

# Test install...
my ($dbh) = connect_to_test_database;

stmt_note "1..17\n";
stmt_ok;
my ($table) = "dbd_ix_cursor_state";

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

my ($select) = "SELECT * FROM $table ORDER BY Col01";
my ($insert) = "INSERT INTO $table VALUES(0, ?, ?, ?, ?)";

{
# Insert data
my ($sth) = $dbh->prepare($insert);
stmt_fail unless $sth;
stmt_ok;

$sth->bind_param(1, 'Another value');
$sth->bind_param(2, 987654321);
$sth->bind_param(3, '2002-02-28 00:11:22.55555');
$sth->bind_param(4, 2.71828182845904523536);
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
stmt_ok;
}

# Check that there are now four rows of data
select_some_data $dbh, 4, $select;

{
my ($sth) = $dbh->prepare($select) or stmt_fail;

# Finish before execute - no error
$sth->finish or stmt_fail;
stmt_ok;

$sth->execute or stmt_fail;
stmt_ok;

# Finish before any fetch - no error
$sth->finish or stmt_fail;
stmt_ok;

$sth->execute or stmt_fail;
stmt_ok;

my ($row) = $sth->fetchrow_arrayref or stmt_fail;
stmt_ok;

# Finish before all data fetched - no error
$sth->finish or stmt_fail;
stmt_ok;

# Finish again - no error
$sth->finish or stmt_fail;
stmt_ok;

# Explicitly undefine finished statement - no error
undef $sth;
}

{
my ($sth) = $dbh->prepare($select) or stmt_fail;
# Implicitly undefine unexecuted statement - no error
}

{
my ($sth) = $dbh->prepare($select) or stmt_fail;

$sth->execute or stmt_fail;
stmt_ok;
# Implicitly undefine executed statement - no error
}

{
my ($sth) = $dbh->prepare($select) or stmt_fail;

$sth->execute or stmt_fail;
stmt_ok;

my ($row) = $sth->fetchrow_arrayref or stmt_fail;
stmt_ok;
# Implicitly undefine open cursor - no error
}

{
my ($sth) = $dbh->prepare($insert);
stmt_fail unless $sth;
stmt_ok;

# Finish a non-cursory statement - no error
$sth->finish or stmt_fail;
stmt_ok;
# Implicitly undefine prepard statement - no error
}

&all_ok();
