#!/usr/bin/perl -w
#
#	@(#)$Id: t72blob.t,v 95.3 1999/12/04 23:45:10 jleffler Exp $ 
#
#	Test Basic Blobs (INSERT & SELECT) for DBD::Informix
#
#	Copyright (C) 1996-97,1999 Jonathan Leffler

BEGIN { require "perlsubs/InformixTest.pl"; }

# Test install...
$dbh = connect_to_test_database();

if (!$dbh->{ix_BlobSupport})
{
	print("1..0\n");
	&stmt_note("# No blob support -- no blob testing\n");
	$dbh->disconnect;
	exit(0);
}
else
{
	print("1..15\n");
	&stmt_ok(0);

	$dbh->{PrintError} = 0;
	$stmt1 = 'DROP TABLE Dbd_IX_BlobTest';
	$dbh->do($stmt1);
	# Fail unless table dropped or table not found (-206).
	# Problem found by Nuno Carneiro de Moura <ncmoura@net.mailcom.pt>
	$sqlcode = $dbh->{ix_sqlcode};
	&stmt_fail() unless ($sqlcode == 0 || $sqlcode == -206);
	&stmt_ok(0);
	$stmt2 = 'CREATE TABLE Dbd_IX_BlobTest (I SERIAL UNIQUE, ' .
			 ' T TEXT IN TABLE, B BYTE IN TABLE)';
	&stmt_test($dbh, $stmt2, 0);

	$stmt3 = 'INSERT INTO Dbd_IX_BlobTest VALUES(?, ?, ?)';
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

	$blob3 = "This, too, is a TEXT blob";
	$blob4 = "This, too, is a pseudo-BYTE blob";
	&stmt_note("# Testing: \$insert->execute(3, \$blob3, \$blob4)\n");
	&stmt_fail() unless ($insert->execute(3, $blob3, $blob4));
	&stmt_ok(0);

	&stmt_note("Testing: \$insert->finish\n");
	&stmt_fail() unless ($insert->finish);
	&stmt_ok(0);

	$dbh->commit if ($dbh->{ix_InTransaction});

	# Verify that inserted data can be returned
	$stmt4 = 'SELECT * FROM Dbd_IX_BlobTest ORDER BY I';
	&stmt_note("# Testing: \$cursor = \$dbh->prepare('$stmt4')\n");
	&stmt_fail() unless ($cursor = $dbh->prepare($stmt4));
	&stmt_ok(0);

	&stmt_note("# Re-testing: \$cursor->execute\n");
	&stmt_fail() unless ($cursor->execute);
	&stmt_ok(0);

	&stmt_note("# Re-testing: \$cursor->fetch\n");
	# Fetch returns a reference to an array!
	while ($ref = $cursor->fetch)
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

	# Verify data attributes!
	@type = @{$cursor->{TYPE}};
	for ($i = 0; $i <= $#type; $i++) { print ("# Type      $i: $type[$i]\n"); }
	@name = @{$cursor->{NAME}};
	for ($i = 0; $i <= $#name; $i++) { print ("# Name      $i: $name[$i]\n"); }
	@null = @{$cursor->{NULLABLE}};
	for ($i = 0; $i <= $#null; $i++) { print ("# Nullable  $i: $null[$i]\n"); }
	@prec = @{$cursor->{PRECISION}};
	for ($i = 0; $i <= $#prec; $i++) { print ("# Precision $i: $prec[$i]\n"); }
	@scal = @{$cursor->{SCALE}};
	for ($i = 0; $i <= $#scal; $i++) { print ("# Scale     $i: $scal[$i]\n"); }

	$nfld = $cursor->{NUM_OF_FIELDS};
	$nbnd = $cursor->{NUM_OF_PARAMS};
	&stmt_note("# Number of Columns: $nfld; Number of Parameters: $nbnd\n");

	&stmt_note("# Testing: \$cursor->finish\n");
	&stmt_fail() unless ($cursor->finish);
	&stmt_ok();

	# FREE the cursor and asociated data
	undef $cursor;

	&stmt_fail() unless $dbh->do($stmt1);
}

&stmt_note("# Testing: \$dbh->disconnect()\n");
&stmt_fail() unless ($dbh->disconnect);
&stmt_ok(0);

&all_ok();
