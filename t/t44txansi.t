#!/usr/bin/perl -w
#
#	@(#)$Id: t44txansi.t,v 100.5 2002/11/05 18:40:58 jleffler Exp $ 
#
#	Test AutoCommit On for DBD::Informix
#
#	Copyright 1996-97,1999 Jonathan Leffler
#	Copyright 2000         Informix Software Inc
#	Copyright 2002         IBM
#
# AutoCommit On => Each statement is a self-contained transaction
# Ensure MODE ANSI databases use cursors WITH HOLD

use DBD::Informix::TestHarness;

# Test install...
$dbh = &connect_to_test_database();

if (!$dbh->{ix_ModeAnsiDatabase})
{
	&stmt_note("1..0 # Skip: MODE ANSI test - database '$dbh->{Name}' is not MODE ANSI\n");
	$dbh->disconnect;
	exit(0);
}

&stmt_note("1..15\n");
&stmt_ok();

$ac = $dbh->{AutoCommit} ? "On" : "Off";
print "# Default AutoCommit is $ac\n";
$dbh->{AutoCommit} = 1;
$ac = $dbh->{AutoCommit} ? "On" : "Off";
print "# AutoCommit was set to $ac\n";

$trans01 = "DBD_IX_Trans01";
$select = "SELECT * FROM $trans01";

stmt_test $dbh, qq{
CREATE TEMP TABLE $trans01
(
	Col01	SERIAL NOT NULL PRIMARY KEY,
	Col02	CHAR(20) NOT NULL,
	Col03	DATE NOT NULL,
	Col04	DATETIME YEAR TO FRACTION(5) NOT NULL
)
};

my $date = &date_as_string($dbh, 12, 25, 1996);

# Confirm that table exists but is empty.
select_zero_data $dbh, $select;

$tag1  = 'Elfdom';
$insert01 = qq{INSERT INTO $trans01
VALUES(0, '$tag1', '$date', CURRENT YEAR TO FRACTION(5))};

stmt_test $dbh, $insert01;

select_some_data $dbh, 1, $select;

# Insert two more rows of data.
stmt_test $dbh, $insert01;
$tag2 = 'Santa Claus Home';
$insert01 =~ s/$tag1/$tag2/;
stmt_test $dbh, $insert01;

# Check that there is some data
select_some_data $dbh, 3, $select;

sub print_row
{
	my($row) = @_;
	my(@row) = @{$row};
	my($pad, $i) = ("#-# ", 0);
	for ($i = 0; $i < @row; $i++)
	{
		&stmt_note("$pad$row[$i]");
		$pad = " :: ";
	}
	&stmt_note("\n");
}

# Prepare, open and fetch one row from a cursor
&stmt_fail unless ($sth = $dbh->prepare($select));
&stmt_fail unless ($sth->execute);
&stmt_fail unless ($row1 = $sth->fetch);
print_row $row1;
&stmt_ok;

# Insert another two rows of data (committing those rows)
stmt_test $dbh, $insert01;
$tag2 = 'Santa Claus Home';
$insert01 =~ s/$tag2/$tag1/;
stmt_test $dbh, $insert01;

# Check that the cursor still works!
while ($row2 = $sth->fetch)
{
	print_row $row2;
}
&stmt_fail if ($sth->{ix_sqlcode} < 0);
&stmt_ok;

# Check that there is some data
select_some_data $dbh, 5, $select;

# Delete the data.
stmt_test $dbh, "DELETE FROM $trans01";

# Check that there is no data
select_zero_data $dbh, $select;

&all_ok();
