#!/usr/bin/perl -w
#
#   @(#)$Id: t93lvarchar.t,v 2005.1 2005/03/14 23:24:12 jleffler Exp $
#
#   Test basic handling of LVARCHAR data
#
#   Copyright 2002-03 IBM
#   Copyright 2005    Jonathan Leffler

use strict;
use DBD::Informix::TestHarness;

my ($dbh) = &test_for_ius;

$dbh->{ChopBlanks} = 1;

&stmt_note("1..7\n");

my ($table) = "dbd_ix_t93lvarchar";
my ($disttype) = "dbd_ix_t93distoflvc";

sub do_stmt
{
	my($dbh, $stmt) = @_;
	print "# $stmt\n";
	$dbh->do($stmt) or stmt_err;
}

sub check_col
{
	my($rownum, $colname, $fetchval, $insertval) = @_;
	my($rc) = 0;
	if ($fetchval ne $insertval)
	{
		$rc = 1;
		$fetchval =~ s/\0/\\000/g;
		stmt_note "# Corrupted data in row $rownum, col $colname:\n#\tfetched  <<$fetchval>>\n#\tinserted <<$insertval>>\n";
	}
	return $rc;
}

sub verify_fetched_data
{
	my ($dbh, $sel, $ncols, @vals) = @_;
	# Fetch the inserted data.
	my ($fetched) = 0;
	stmt_note "# PREPARE: $sel\n";
	my ($sth) = $dbh->prepare($sel) or stmt_fail;
	$sth->execute or stmt_fail;

	my ($results) = $sth->fetchall_arrayref;
	my ($row);
	my ($rc) = 0;
	foreach $row (@$results)
	{
		$fetched++;
		if ($fetched < 3)
		{
			for (my $i = 1; $i < $ncols; $i++)
			{
				$rc += check_col($fetched, $sth->{NAME}[$i], ${$row}[$i], $vals[$i]);
			}
		}
		grep { $_ = "." if !defined $_; } @$row;
		print "# ROW-$fetched: @$row\n";
	}
	$sth->finish;
	stmt_note "# fetched $fetched rows\n";
	return $rc;
}

# Drop any pre-existing versions of the test table and test types
$dbh->{PrintError} = 0;
do_stmt $dbh, "drop table $table";
do_stmt $dbh, "drop type $disttype restrict";
$dbh->{PrintError} = 1;

stmt_test $dbh, "create distinct type $disttype as lvarchar";

my ($stmt) = qq% create table $table (s serial, lvc lvarchar, dlvc $disttype)%;
stmt_test $dbh, $stmt;

my $inserted = 0;

# Insert some data into the table.  NB: $0 refers to this script file!
my ($longstr) = "1234567890" x 5;
stmt_test $dbh, "insert into $table values (10203040, '$longstr', '$longstr')";
$inserted += 1;

my ($ins) = "insert into $table values (?, ?, ?)";
stmt_note("# PREPARE: $ins\n");
my ($sth) = $dbh->prepare($ins) or stmt_fail;
stmt_ok;

$sth->execute(11213141, $longstr, $longstr) or stmt_fail;
$inserted += $sth->rows;

# Insert nulls...
my ($null);
undef $null;
$sth->execute(12223242, $null, $null) or stmt_fail;
stmt_ok;
stmt_note "# inserted nulls OK\n";

$inserted += $sth->rows;
stmt_fail unless $inserted == 3;

my(@vals) = ($null, $longstr, $longstr, 'abc', $longstr, $longstr);

my($rc) = 0;
$rc += verify_fetched_data($dbh, "select s, lvc from $table order by s", 1, @vals);
$rc += verify_fetched_data($dbh, "select s, lvc, dlvc from $table order by s", 2, @vals);
$rc += verify_fetched_data($dbh, "select s, lvc, dlvc, 'abc'::lvarchar from $table order by s", 3, @vals);
$rc += verify_fetched_data($dbh, "select s, lvc, dlvc, 'abc'::lvarchar, lvc as lvc_2 from $table order by s", 4, @vals);
$rc += verify_fetched_data($dbh, "select s, lvc, dlvc, 'abc'::lvarchar, lvc as lvc_2, dlvc as dlvc_2 from $table order by s", 5, @vals);
stmt_fail "# $rc data validation failures\n" if $rc > 0;

# Drop new versions of any of these test types
$dbh->do("drop table $table");
$dbh->do("drop type $disttype restrict");
stmt_ok;

$dbh->disconnect or die;
stmt_ok;

all_ok;
