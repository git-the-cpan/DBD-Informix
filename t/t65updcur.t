#!/usr/bin/perl -w
#
#	@(#)$Id: t/t65updcur.t version /main/9 1999-09-19 21:18:32 $ 
#
#	Test $sth->{CursorName} and cursors FOR UPDATE for DBD::Informix
#
#	Copyright (C) 1997,1999 Jonathan Leffler

BEGIN { require "perlsubs/InformixTest.pl"; }

# Test install...
$dbh = &connect_to_test_database();

&stmt_note("1..13\n");
&stmt_ok();

$table = "DBD_IX_TestTable";
$select = "SELECT * FROM $table";

stmt_test $dbh, qq{
CREATE TEMP TABLE $table
(
	Col01	SERIAL NOT NULL PRIMARY KEY,
	Col02	CHAR(30) NOT NULL,
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

$date = $row[0];
$tag1  = $dbh->quote('Mornington Crescent');
$insert01 = qq{INSERT INTO $table
VALUES(0, $tag1, '$date', CURRENT YEAR TO FRACTION(5))};

# Insert two rows of data
stmt_test $dbh, $insert01;
$tag2 = $dbh->quote("King's Cross / St Pancras");
$insert01 =~ s/$tag1/$tag2/;
stmt_test $dbh, $insert01;

# Check that there is some data
select_some_data $dbh, 2, $select;

$selupd = $select . " FOR UPDATE";
print "# $selupd\n";
&stmt_fail() unless ($st1 = $dbh->prepare($selupd));
&stmt_ok();

# Attribute caching working again!
$name = $st1->{CursorName};
for ($i = 0; $i < 3; $i++)
{
	$x = ($name eq $st1->{CursorName}) ? "OK" : "** BROKEN **";
	print "# Cursor name $i: $st1->{CursorName} $x\n";
}

$name = $st1->{CursorName};
$updstmt = "UPDATE $table SET Col02 = ? WHERE CURRENT OF $name";
print "# $updstmt\n";
&stmt_fail() unless ($st2 = $dbh->prepare($updstmt));
&stmt_ok();

$delstmt = "DELETE FROM $table WHERE CURRENT OF $name";
print "# $delstmt\n";
&stmt_fail() unless ($st3 = $dbh->prepare($delstmt));
&stmt_ok();

# In a logged database, must be in a transaction
# Given new AutoCommit behaviour, must set AutoCommit Off.
$dbh->{AutoCommit} = 0
	unless (!$dbh->{ix_LoggedDatabase});

$n = 0;
&stmt_fail() unless ($st1->execute());
&stmt_ok();

&stmt_fail() unless ($data = $st1->fetch);
&stmt_ok();
$n++;
@row = @{$data};
for ($i = 0; $i <= $#row; $i++)
{
	print "Row $n: Field $i: <<$row[$i]>>\n";
}

$row[1] = "ABC " . $row[1];
&stmt_fail() unless ($st2->execute($row[1]));

&stmt_fail() unless ($data = $st1->fetch);
&stmt_ok();
$n++;
@row = @{$data};
for ($i = 0; $i <= $#row; $i++)
{
	print "Row $n: Field $i: <<$row[$i]>>\n";
}

&stmt_fail() unless ($st3->execute);
&stmt_ok;

# In a logged database, must be in a transaction
$dbh->commit unless (!$dbh->{ix_LoggedDatabase});

# Check that there is some data
select_some_data $dbh, 1, $select;

&all_ok();
