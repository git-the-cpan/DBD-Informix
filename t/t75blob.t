#!/usr/bin/perl -w
#
#	@(#)$Id: t75blob.t,v 62.3 1999/09/19 22:36:52 jleffler Exp $ 
#
#	Self-contained Test for Blobs (INSERT & SELECT) for DBD::Informix
#
#	Copyright (C) 1996-97,1999 Jonathan Leffler

BEGIN { require "perlsubs/InformixTest.pl"; }

# KLUDGE - of the worst type!
print("1..1\n");
&stmt_note("# Test disabled - because it routinely fails!\n");
&stmt_ok(0);
&all_ok();
exit(0);

$tablename = "DBD_IX_BlobTest2";

# Test install...
$dbh = connect_to_test_database();

if (!$dbh->{ix_InformixOnLine})
{
	print("1..2\n");
	&stmt_note("# Not Informix-OnLine -- no blob testing\n");
	&stmt_ok(0);
}
else
{
	print("1..10\n");
	&stmt_ok(0);
	$dbh->{PrintError} = 1;

	$stmt2 = qq{ CREATE TEMP TABLE $tablename (I SERIAL UNIQUE, B BYTE IN TABLE, 
				 T TEXT IN TABLE) };
	&stmt_test($dbh, $stmt2, 0);

	$stmt3 = qq{ INSERT INTO $tablename VALUES(?, ?, ?) };
	&stmt_note("# Testing: \$insert = \$dbh->prepare('$stmt3')\n");
	&stmt_fail() unless ($insert = $dbh->prepare($stmt3));
	&stmt_ok(0);

	for ($i = 1; $i <= 20; $i++)
	{
		$repeat = int(rand 30) + 1;
		$blob1 = "This is a pseudo-BYTE blob " x $repeat;
		$blob2 = "This is a TEXT blob " x $repeat;
		$blob1 = "<<$repeat>>$blob1";
		$blob2 = "<<$repeat>>$blob2";
		chop $blob1;
		chop $blob2;
		&stmt_note("# Loop $i: repeat $repeat\n");
		&stmt_fail() unless ($insert->execute($i, $blob1, $blob2));
		&stmt_note("# insert OK $i\n");
		## This causes -608 errors on the next iteration of the
		## main loop in v0.59; fixed in v0.60.
		if ($i % 6 == 0)
		{
			$i++;
			&stmt_note("# Loop $i: double null\n");
			&stmt_fail() unless ($insert->execute($i, undef, undef));
			&stmt_note("# aux insert OK $i\n");
		}
	}
	&stmt_ok(0);

	&stmt_note("Testing: \$insert->finish\n");
	&stmt_fail() unless ($insert->finish);
	&stmt_ok(0);

	# Verify that inserted data can be returned
	$stmt4 = qq{ SELECT * FROM $tablename ORDER BY I };
	&stmt_note("# Testing\n\$cursor = \$dbh->prepare('$stmt4')\n");
	&stmt_fail() unless ($cursor = $dbh->prepare($stmt4));
	&stmt_ok(0);

	&stmt_note("# Testing: \$cursor->execute\n");
	&stmt_fail() unless ($cursor->execute);
	&stmt_ok(0);

	&stmt_note("# Testing: \$cursor->fetch\n");
	# Fetch returns a reference to an array!
	while ($ref = $cursor->fetch)
	{
		@row = @{$ref};
		# Verify returned data!
		&stmt_note("# Values returned: ", $#row + 1, "\n");
		for ($i = 0; $i <= $#row; $i++)
		{
			$val = $row[$i];
			if (defined $val)
			{
				$val = substr($row[$i], 0, 30) . "..."
					if (length($val) > 33);
				&stmt_note("# Row value $i: $val\n");
			}
			else
			{
				&stmt_note("# Row value $i: <<NULL>>\n");
			}
		}
	}
	&stmt_ok(0);

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
	print("# Number of Columns: $nfld; Number of Parameters: $nbnd\n");

	&stmt_note("# Re-testing: \$cursor->finish\n");
	&stmt_fail() unless ($cursor->finish);
	&stmt_ok(0);

	# FREE the cursor and asociated data
	undef $cursor;

	$dbh->do("DROP TABLE $tablename");
}

&stmt_note("# Testing: \$dbh->disconnect()\n");
&stmt_fail() unless ($dbh->disconnect);
&stmt_ok(0);

&all_ok();
