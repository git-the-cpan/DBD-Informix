#!/usr/bin/perl -w
#
#	@(#)transact01.t	53.1 97/03/06 20:37:43
#
#	Test Transactions for DBD::Informix
#
#	Copyright (C) 1996,1997 Jonathan Leffler

use DBD::InformixTest;

# Test install...
$dbh = &connect_to_test_database();

if ($dbh->{ix_LoggedDatabase} == 0)
{
	&stmt_note("1..1\n");
	&stmt_note("# No transactions on unlogged database '$dbh->{Name}'\n");
	&stmt_ok(0);
	&all_ok();
}

&stmt_note("1..20\n");
&stmt_ok();
if ($dbh->{ix_ModeAnsiDatabase})
{ &stmt_note("# This is a MODE ANSI database\n"); }
else
{ &stmt_note("# This is a regular logged database\n"); }

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

# How to insert date values even when you can't be bothered to sort out
# what DBDATE will do...  You cannot insert an MDY() expression directly.
$sel1 = "SELECT MDY(12,25,1996) FROM 'informix'.SysTables WHERE Tabid = 1";
&stmt_fail() unless ($st1 = $dbh->prepare($sel1));
&stmt_fail() unless ($st1->execute);
&stmt_fail() unless (@row = $st1->fetchrow);
undef $st1;

if ($dbh->{ix_ModeAnsiDatabase})
{
	&stmt_fail() unless ($dbh->commit());
}

# Turn off automatic errors (we're going to generate some errors)
$dbh->{ix_AutoErrorReport} = 0;

# Start a transaction (to be rolled back).
stmt_test $dbh, "BEGIN WORK";

$date = $row[0];
$tag1  = 'Elfdom';
$insert01 = qq{INSERT INTO $trans01
VALUES(0, '$tag1', '$date', CURRENT YEAR TO FRACTION(5))};

stmt_test $dbh, $insert01;

&stmt_fail() unless ($dbh->rollback);
&stmt_ok();

# Start another transaction (to be rolled back).
stmt_test $dbh, "BEGIN WORK";

select_zero_data $dbh, $select;

# Insert two rows of data.
stmt_test $dbh, $insert01;
$tag2 = 'Santa Claus Home';
$insert01 =~ s/$tag1/$tag2/;
stmt_test $dbh, $insert01;

# Check that there is some data
select_some_data $dbh, 2, $select;

# Rollback!
&stmt_fail() unless ($dbh->rollback);

# Start another transaction (to be committed).
stmt_test $dbh, "BEGIN WORK";

# Check that there is no data
select_zero_data $dbh, $select;

# Insert two rows of data.
stmt_test $dbh, $insert01;
$tag2 = 'Santa Claus Home';
$insert01 =~ s/$tag2/$tag1/;
stmt_test $dbh, $insert01;

# Check that there is some data
select_some_data $dbh, 2, $select;

# Commit it
&stmt_fail() unless ($dbh->commit);

# Start another transaction (to be rolled back).
stmt_test $dbh, "BEGIN WORK";

# Check that there is still some data
select_some_data $dbh, 2, $select;

# Delete the data.
stmt_test $dbh, "DELETE FROM $trans01";

# Check that there is no data
select_zero_data $dbh, $select;

# Rollback the transaction
&stmt_fail() unless ($dbh->rollback);

# Do not explicitly start another transaction.
# Check that there is still some data
select_some_data $dbh, 2, $select;

# Report any errors during cleanup operations
$dbh->{ix_AutoErrorReport} = 1;

&all_ok();
