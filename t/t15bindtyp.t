#!/usr/bin/perl -w
#
#	@(#)$Id: t15bindtyp.t,v 100.3 2002/02/08 22:50:40 jleffler Exp $ 
#
#	Test handling of bind_param with type attributes for DBD::Informix
#
#	Copyright 2000 Informix Software Inc
#	Copyright 2002 IBM

use strict;
use DBI qw(:sql_types);
use DBD::Informix qw(:ix_types);
use DBD::Informix::TestHarness;

# Test install...
my ($dbh) = connect_to_test_database;

my ($ntests) = 7;
if ($dbh->{ix_BlobSupport})
{
	# XPS 8.[012]x does not support blobs.
	$ntests = 14;
}
stmt_note "1..$ntests\n";

stmt_ok;
my ($table) = "dbd_ix_bind_param";

{
	# Testing non-blob types
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

	# Insert a row of values.
	my ($sth) = $dbh->prepare("INSERT INTO $table VALUES(0, ?, ?, ?, ?)");
	&stmt_fail() unless $sth;
	&stmt_ok;

	$sth->bind_param(1, 'Another value', { ix_type => IX_CHAR });
	$sth->bind_param(2, 987654321, { TYPE => SQL_INTEGER });
	$sth->bind_param(3, '1997-02-28 00:11:22.55555', { ix_type => IX_DATETIME });
	$sth->bind_param(4, 2.8128, { TYPE => SQL_NUMERIC });
	&stmt_fail() unless $sth->execute;

	# Check that there is one row of data
	select_some_data $dbh, 1, $select;

	# Check that there are now two rows of data, substantially the same
	&stmt_fail() unless $sth->execute;
	select_some_data $dbh, 2, $select;

	# Try some new bind values
	$sth->bind_param(1, 'Some other data', { ix_type => IX_VARCHAR });
	$sth->bind_param(4, 3.141593, { ix_type => IX_DECIMAL });
	&stmt_fail() unless $sth->execute;

	# Check that there are now three rows of data
	select_some_data $dbh, 3, $select;

	# Try some more new bind values
	$sth->bind_param(2, 12345, { ix_type => IX_SMALLINT });
	$sth->bind_param(3, '2000-02-29 23:59:59.99999', { ix_type => IX_VARCHAR });	# Semi-legitimate!
	&stmt_fail() unless $sth->execute;

	# Check that there are now four rows of data
	select_some_data $dbh, 4, $select;
}

if ($dbh->{ix_BlobSupport})
{
	# Testing BYTE and TEXT blob types
	stmt_test $dbh, qq{DROP TABLE $table};

	# Create table for testing
	stmt_test $dbh, qq{
	CREATE TEMP TABLE $table
	(
		Col01	SERIAL(1000) NOT NULL,
		Col02	CHAR(20) NOT NULL,
		Col03	BYTE NOT NULL,
		Col04	TEXT NOT NULL
	)
	};

	my ($select) = "SELECT * FROM $table ORDER BY Col01";

	# Insert a row of values.
	my ($sth) = $dbh->prepare("INSERT INTO $table VALUES(0, ?, ?, ?)");
	&stmt_fail() unless $sth;
	&stmt_ok;

	$sth->bind_param(1, 'Another value', { ix_type => IX_CHAR }) or stmt_fail;
	$sth->bind_param(2, 987654321, { ix_type => IX_BYTE }) or stmt_fail;
	$sth->bind_param(3, '1997-02-28 00:11:22.55555', { ix_type => IX_TEXT }) or stmt_fail;
	&stmt_fail() unless $sth->execute;

	# Check that there is one row of data
	select_some_data $dbh, 1, $select;

	# Check that there are now two rows of data, substantially the same
	&stmt_fail() unless $sth->execute;
	select_some_data $dbh, 2, $select;

	# Check that you can update a blob!
	my ($st2) = $dbh->prepare("UPDATE $table SET Col03 = ?, Col04 = ? WHERE Col01 = ?");
	&stmt_fail() unless $st2;
	$st2->bind_param(1, 'A Pseudo-BYTE value', { ix_type => IX_BYTE }) or stmt_fail;
	$st2->bind_param(2, 'A Pseudo-TEXT value', { ix_type => IX_TEXT }) or stmt_fail;
	$st2->bind_param(3, 1000) or stmt_fail;
	$st2->execute or stmt_fail;

	# Try some new bind values
	$sth->bind_param(1, 'Some other data', { ix_type => IX_VARCHAR });
	$sth->bind_param(3, 3.141593, { ix_type => IX_TEXT });
	&stmt_fail() unless $sth->execute;

	# Check that there are now three rows of data
	select_some_data $dbh, 3, $select;

	# Try some more new bind values
	$sth->bind_param(2, 12345, { ix_type => IX_BYTE });
	$sth->bind_param(3, '2000-02-29 23:59:59.99999', { ix_type => IX_TEXT });
	&stmt_fail() unless $sth->execute;

	# Check that there are now four rows of data
	select_some_data $dbh, 4, $select;
}

&all_ok();