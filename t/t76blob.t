#!/usr/bin/perl -w
#
#	@(#)$Id: t76blob.t,v 100.4 2002/10/19 00:27:50 jleffler Exp $
#
#	Reproduce 451 errors with Perl.
#
#	Copyright 1999 Bibliotech Ltd., 631-633 Fulham Rd., London SW6 5UQ.
#	Copyright 1999 Jonathan Leffler
#	Copyright 2000 Informix Software Inc
#	Copyright 2002 IBM

use DBD::Informix::TestHarness;

$tablename = "dbd_ix_blobtest";

# Test install...
$dbh = connect_to_test_database();

if (!$dbh->{ix_BlobSupport})
{
	print("1..0 # Skip: No blob support -- no blob testing\n");
	$dbh->disconnect;
	exit(0);
}
else
{
	print("1..8\n");
	&stmt_ok(0);

	# If prior test fails, it leaves a permanent table in the database.
	# This has to be removed by this test.
	# We do not care whether this works or not.
	{
	my ($msg);
	$SIG{__WARN__} = sub { $msg = $_[0]; };
	$dbh->do(qq{ drop table $tablename });
	$SIG{__WARN__} = 'DEFAULT';
	}

	# Create temp table.
	$dbh->do(qq{ create temp table $tablename (col1 text in table, col2 int)})
		or &stmt_fail();
	&stmt_ok(0);

	# Insert a couple of rows. Note the first row
	# is a single '' (empty string, not a null) and
	# the second row is a string containing data.

	$dbh->do("insert into $tablename (col1, col2) values (?, 1)", undef, '')
		or &stmt_fail();
	$dbh->do("insert into $tablename (col1, col2) values (?, 2)", undef, 'abc')
		or &stmt_fail();
	$dbh->do("insert into $tablename (col1, col2) values (?, 3)", undef, 'def')
		or &stmt_fail();
	&stmt_ok(0);

	# Select the rows. Order them so that the row
	# containing the empty string blob is fetched first.
	$sth = $dbh->prepare("select col1, col2 from $tablename order by col2")
		or &stmt_fail();
	$sth->execute()
		or &stmt_fail();

	while ($ref = $sth->fetchrow_arrayref)
	{
		my @row = @$ref;
		# Should a zero length blob be treated as undefined by Perl?
		$row[0] = '' if !defined($row[0]);
		&stmt_note("# fetched row: $row[1] <<$row[0]>>\n");
		&stmt_ok(0);
	}
	&stmt_fail() unless ($sth->{ix_sqlcode} >= 0);
	$sth->finish();
	&stmt_ok(0);
}

&stmt_fail() unless $dbh->disconnect;
&stmt_ok(0);
&all_ok();

