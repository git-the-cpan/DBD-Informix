#!/usr/bin/perl -w
#
#	@(#)$Id: t73blobupd.t,v 100.5 2002/10/19 01:03:58 jleffler Exp $ 
#
#	Test Basic Blobs (INSERT & UPDATE) for DBD::Informix
#
#	Copyright 1999 Jonathan Leffler
#	Copyright 2000 Informix Software Inc
#	Copyright 2002 IBM

use DBD::Informix qw(:ix_types);
use DBD::Informix::TestHarness;

$dbh = &connect_to_test_database();

if (!$dbh->{ix_BlobSupport})
{
	print("1..0 # Skip: No blob support -- no blob testing\n");
	$dbh->disconnect;
	exit(0);
}
else
{
	print("1..19\n");
	&stmt_ok(0);

	$blob_table = "DBD_IX_BlobTest";

	$dbh->{PrintError} = 0;
	$stmt1 = qq{DROP TABLE $blob_table};
	$dbh->do($stmt1);
	# Fail unless table dropped or table not found (-206).
	# Problem found by Nuno Carneiro de Moura <ncmoura@net.mailcom.pt>
	$sqlcode = $dbh->{ix_sqlcode};
	&stmt_fail() unless ($sqlcode == 0 || $sqlcode == -206);
	&stmt_ok(0);
	$stmt2 = qq{CREATE TABLE $blob_table (I SERIAL UNIQUE, T TEXT IN TABLE, B BYTE IN TABLE)};
	&stmt_test($dbh, $stmt2, 0);

	$stmt3 = qq{INSERT INTO $blob_table VALUES(?, ?, ?)};
	&stmt_note("# Testing: \$insert = \$dbh->prepare('$stmt3')\n");
	&stmt_fail() unless ($insert = $dbh->prepare($stmt3));
	&stmt_ok(0);

	$blob1 = "This is a TEXT blob";
	$blob2 = "This is a pseudo-BYTE blob";
	&stmt_note("# Testing: \$insert->execute(1, \$blob1, \$blob2)\n");
	&stmt_fail() unless ($insert->execute(1, $blob1, $blob2));
	&stmt_ok(0);

	# At one time, we got free problems reported when we did this!
	$blob1 = "This is also a TEXT blob";
	$blob2 = "This is also a pseudo-BYTE blob";
	&stmt_note("# Testing: \$insert->execute(2, \$blob1, \$blob2)\n");
	&stmt_fail() unless ($insert->execute(2, $blob1, $blob2));
	&stmt_ok(0);

	$blob3 = "This, too, is a TEXT blob\n" x 4;
	$blob4 = "This, too, is a pseudo-BYTE blob\n" x 10;
	&stmt_note("# Testing: \$insert->execute(3, \$blob3, \$blob4)\n");
	&stmt_fail() unless ($insert->execute(3, $blob3, $blob4));
	&stmt_ok(0);

	&stmt_note("Testing: \$insert->finish\n");
	&stmt_fail() unless ($insert->finish);
	&stmt_ok(0);

	$dbh->commit if ($dbh->{ix_InTransaction});

	# Verify that inserted data can be returned
	$stmt4 = qq{SELECT * FROM $blob_table ORDER BY I};
	&stmt_note("# Testing: \$cursor = \$dbh->prepare('$stmt4')\n");
	&stmt_fail() unless ($cursor = $dbh->prepare($stmt4));
	&stmt_ok(0);

	&stmt_note("# Testing: \$cursor->execute\n");
	&stmt_fail() unless ($cursor->execute);
	&stmt_ok(0);

	&stmt_note("# Testing: \$cursor->fetch\n");
	# Fetch returns a reference to an array!
	while ($ref = $cursor->fetchrow_arrayref)
	{
		&stmt_ok(0);
		@row = @{$ref};
		# Verify returned data!
		&stmt_note("# Values returned: ", $#row + 1, "\n");
		for ($i = 0; $i <= $#row; $i++)
		{
			&stmt_note("# Row value $i: $row[$i]\n");
		}
	}

	# BLOB Update - must use bind_param
	$stmt5 = qq{UPDATE $blob_table SET T = ?, B = ? WHERE I = ?};
	&stmt_note("# Testing: \$upd = \$dbh->prepare('$stmt5')\n");
	&stmt_fail() unless ($upd = $dbh->prepare($stmt5));

	$blob3 = "This, too, is a TEXT blob\n" x 2;
	$blob4 = "This, too, is a pseudo-BYTE blob\n" x 2;
	$upd->bind_param(1, $blob3, { ix_type => IX_TEXT });
	$upd->bind_param(2, $blob4, { ix_type => IX_BYTE });
	$upd->bind_param(3, 3, { ix_type => IX_INTEGER });
	&stmt_fail() unless $upd->execute();

	&stmt_note("# Re-testing: \$cursor->execute\n");
	&stmt_fail() unless ($cursor->execute);
	&stmt_ok(0);

	&stmt_note("# Re-testing: \$cursor->fetch\n");
	# Fetch returns a reference to an array!
	while ($ref = $cursor->fetchrow_arrayref)
	{
		&stmt_ok(0);
		@row = @{$ref};
		# Verify returned data!
		&stmt_note("# Values returned: ", $#row + 1, "\n");
		for ($i = 0; $i <= $#row; $i++)
		{
			&stmt_note("# Row value $i: $row[$i]\n");
		}
	}

	&stmt_note("# Testing: \$cursor->finish\n");
	&stmt_fail() unless ($cursor->finish);
	&stmt_ok();

	# FREE the cursor and asociated data
	undef $cursor;
}

&stmt_note("# Testing: \$dbh->disconnect()\n");
&stmt_fail() unless ($dbh->disconnect);
&stmt_ok(0);

&all_ok;
