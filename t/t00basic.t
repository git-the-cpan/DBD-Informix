#!/usr/bin/perl -w
#
#	@(#)$Id: t00basic.t,v 61.3 1998/11/25 17:15:16 jleffler Exp $ 
#
#	Initial test script for DBD::Informix
#
#	Copyright (C) 1996-98 Jonathan Leffler

use DBD::InformixTest;

$testtable = "dbd_ix_test01";

&stmt_note("1..48\n");

$dbh = &connect_to_test_database(1);
&stmt_ok(0);

print "# DBI Information\n";
print "#     Version:               $DBI::VERSION\n";
print "# Generic Driver Information\n";
print "#     Type:                  $dbh->{Driver}->{Type}\n";
print "#     Name:                  $dbh->{Driver}->{Name}\n";
print "#     Version:               $dbh->{Driver}->{Version}\n";
print "#     Attribution:           $dbh->{Driver}->{Attribution}\n";
print "# Informix Driver Information\n";
print "#     Product:               $dbh->{ix_ProductName}\n";
print "#     Product Version:       $dbh->{ix_ProductVersion}\n";
print "#     Multiple Connections:  $dbh->{ix_MultipleConnections}\n";
print "#     Active Connections:    $dbh->{ix_ActiveConnections}\n";
print "#     Current Connection:    $dbh->{ix_CurrentConnection}\n";
print "# \n";

$dbname = $dbh->{Name};

&stmt_note("# Testing: \$dbh->disconnect()\n");
&stmt_fail() unless ($dbh->disconnect);
&stmt_ok();

&stmt_note("# Re-testing: \$dbh->disconnect()\n");
&stmt_fail() unless ($dbh->disconnect);
&stmt_ok();

# Reconnect.  Old-style connect -- do not use this notation!
{
my $user = $ENV{DBD_INFORMIX_USERNAME};
my $pass = $ENV{DBD_INFORMIX_PASSWORD};
$user = "" if (!defined $user);
$pass = "" if (!defined $pass);
my $mask = $pass;
$pass =~ s/./X/g;
&stmt_note("# Testing: DBI->connect('$dbname', '$user', '$mask', 'Informix')\n");
&stmt_fail() unless ($dbh = DBI->connect($dbname, $user, $pass, 'Informix'));
&stmt_ok();
}

$dbh->{ChopBlanks} = 1;		# Force chopping of trailing blanks 

print "# Generic Database Information\n";
print "#     Type:                    $dbh->{Type}\n";
print "#     Database Name:           $dbh->{Name}\n";
print "#     AutoCommit:              $dbh->{AutoCommit}\n";
print "# Informix Database Information\n";
print "#     Informix-OnLine:         $dbh->{ix_InformixOnLine}\n";
print "#     Logged Database:         $dbh->{ix_LoggedDatabase}\n";
print "#     Mode ANSI Database:      $dbh->{ix_ModeAnsiDatabase}\n";
print "#     AutoErrorReport:         $dbh->{ix_AutoErrorReport}\n";
print "#     Transaction Active:      $dbh->{ix_InTransaction}\n";
print "#\n";

# Remove table if it already exists, warning (not failing) if it doesn't
$oldmode = $dbh->{ix_AutoErrorReport};
$dbh->{ix_AutoErrorReport} = 0;
$stmt1 = "DROP TABLE $testtable";
&stmt_test($dbh, $stmt1, 1);
$dbh->{ix_AutoErrorReport} = $oldmode;

# Create table (now that it does not exist)...
$stmt2 = "CREATE TABLE $testtable (id INTEGER NOT NULL, name CHAR(64))";
&stmt_test($dbh, $stmt2, 0);

# Drop it (again)
&stmt_test($dbh, $stmt1, 0);

# Create it again!
&stmt_retest($dbh, $stmt2, 0);

$stmt3 = "INSERT INTO $testtable VALUES(1, 'Alligator Descartes')";
&stmt_test($dbh, $stmt3, 0);

$stmt4 = "DELETE FROM $testtable WHERE id = 1";
&stmt_test($dbh, $stmt4, 0);

# Test SELECT of empty data set
$stmt5 = "SELECT * FROM $testtable WHERE id = 1";
&stmt_note("# Testing: \$cursor = \$dbh->prepare('$stmt5')\n");
&stmt_fail() unless ($cursor = $dbh->prepare($stmt5));
&stmt_ok();

# Print statement...
&stmt_note("# Statement: $cursor->{Statement}\n");

&stmt_note("# Testing: \$cursor->execute\n");
&stmt_fail() unless ($cursor->execute);
&stmt_ok();

&stmt_note("# Statement: $cursor->{Statement}\n");
&stmt_note("# Testing: \$cursor->fetch\n");

$i = 0;
while ((@row = $cursor->fetch) and $#row > 0)
{
	$i++;
	&stmt_note("# Row $i: $row[0] => $row[1]\n");
	&stmt_note("# FETCH succeeded but should have failed!\n");
	&stmt_fail();
}

&stmt_fail() unless ($#row == 0);
&stmt_note("# OK (nothing found)\n");
&stmt_ok(0);

&print_sqlca($cursor);

&stmt_note("# Testing: \$cursor->finish\n");
&stmt_fail() unless ($cursor->finish);
&stmt_ok(0);

# FREE the cursor and asociated data
undef $cursor;

# Insert some data
&stmt_retest($dbh, $stmt3, 0);

# Verify that inserted data can be returned
&stmt_note("# Re-testing: \$cursor = \$dbh->prepare('$stmt5')\n");
&stmt_fail() unless ($cursor = $dbh->prepare($stmt5));
&stmt_ok(0);

&stmt_note("# Re-testing: \$cursor->execute\n");
&stmt_fail() unless ($cursor->execute);
&stmt_ok(0);

&stmt_note("# Re-testing: \$cursor->fetch\n");
# Fetch returns a reference to an array!
while ($ref = $cursor->fetch)
{
	@row = @{$ref};
	# Verify returned data!
	@exp = (1, "Alligator Descartes");
	&stmt_note("# Values returned: ", $#row + 1, "\n");
	for ($i = 0; $i <= $#row; $i++)
	{
		&stmt_note("# Row value $i: $row[$i]\n");
		die "Incorrect value returned: got $row[$i]; wanted $exp[$i]\n"
			unless ($exp[$i] eq $row[$i]);
	}
}

# Verify data attributes!
@type = @{$cursor->{TYPE}};
for ($i = 0; $i <= $#type; $i++) { print ("# Type      $i: $type[$i]\n"); }
@name = @{$cursor->{NAME}};
for ($i = 0; $i <= $#name; $i++) { print ("# Name      $i: <<$name[$i]>>\n"); }
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

$stmt6 = "UPDATE $testtable SET id = 2 WHERE name = 'Alligator Descartes'";
&stmt_retest($dbh, $stmt6, 0);

$stmt7 = "INSERT INTO $testtable VALUES(1, 'Jonathan Leffler')";
&stmt_test($dbh, $stmt7, 0);

sub select_all
{
	my ($exp1) = @_;		# Reference to associative array
	my (%exp2) = %{$exp1};	# Associative array of numbers (keys) and names
	my (@row, $i);	# Local variables

	&stmt_note("# Checking Updated Data\n");
	$stmt8 = "SELECT * FROM $testtable ORDER BY id";
	&stmt_note("# Re-testing: \$cursor = \$dbh->prepare('$stmt8')\n");
	&stmt_fail() unless ($cursor = $dbh->prepare($stmt8));
	&stmt_ok(0);

	&stmt_note("# Re-testing: \$cursor->execute\n");
	&stmt_fail() unless ($cursor->execute);
	&stmt_ok(0);

	&stmt_note("# Testing: \$cursor->fetchrow iteratively\n");
	$i = 1;
	while (@row = $cursor->fetchrow)
	{
		&stmt_note("# Row $i: $row[0] => $row[1]\n");
		if ($row[1] eq $exp2{$row[0]})
		{
			&stmt_ok(0);
		}
		else
		{
			&stmt_note("# Wrong value:\n");
			&stmt_note("# -- Got <<$row[1]>>\n");
			&stmt_note("# -- Wanted <<$exp2{$row[0]}>>\n");
			&stmt_fail();
		}
		$i++;
	}

	&stmt_note("# Re-testing: \$cursor->finish\n");
	&stmt_fail() unless ($cursor->finish);
	&stmt_ok(0);

	# Free cursor referencing the table...
	undef $cursor;
}

&select_all({
	1 => 'Jonathan Leffler',
	2 => 'Alligator Descartes',
});

# Now the table is dropped.
&stmt_retest($dbh, $stmt1, 0);

# Test stored procedures...
if ($dbh->{ix_ProductVersion} >= 500)
{
	$stmt10 = "DROP PROCEDURE dbd_ix_01";
	&stmt_test($dbh, $stmt10, 1);

	$stmt11 =
	q{
	CREATE PROCEDURE dbd_ix_01(val1 DECIMAL, val2 DECIMAL)
		-- Sometimes known as ndelta_eq()
		RETURNING INTEGER;
		IF (val1 = val2) THEN RETURN 1; END IF;
		IF NOT (val1 = val2) THEN RETURN 0; END IF;
		RETURN NULL;
	END PROCEDURE;
	};
	&stmt_test($dbh, $stmt11, 0);

	$stmt12 = "EXECUTE PROCEDURE dbd_ix_01(23.00, 23)";
	&stmt_note("# Testing: \$cursor = \$dbh->prepare('$stmt12')\n");
	&stmt_fail() unless ($cursor = $dbh->prepare($stmt12));
	&stmt_ok(0);

	&stmt_note("# Re-testing: \$cursor->execute\n");
	&stmt_fail() unless ($cursor->execute);
	&stmt_ok(0);

	&stmt_note("# Re-testing: \$cursor->fetchrow\n");
	&stmt_fail() unless (@row = $cursor->fetchrow);
	&stmt_ok(0);

	&stmt_note("# Values returned/expected: ", $#row + 1, "/1\n");
	for ($i = 0; $i <= $#row; $i++)
	{
			&stmt_note("# Row value $i: $row[$i]\n");
			die "Unexpected value returned\n" unless $row[$i] == 1;
	}

	&stmt_note("# Re-testing: \$cursor->finish\n");
	&stmt_fail() unless ($cursor->finish);
	&stmt_ok(0);

	# FREE the cursor and asociated data
	undef $cursor;

	# Remove stored procedure
	&stmt_retest($dbh, $stmt10, 0);
}

# Test execute with bound values
&stmt_retest($dbh, $stmt2, 0);	# CREATE TABLE
&stmt_retest($dbh, $stmt7, 0);	# INSERT Alligator
&stmt_retest($dbh, $stmt3, 0);	# UPDATE Alligator
&stmt_retest($dbh, $stmt6, 0);	# INSERT Jonathan

$stmt13 = "INSERT INTO $testtable VALUES(?, ?)";
&stmt_note("# Testing: \$sth = \$dbh->prepare('$stmt13')\n");
&stmt_fail() unless ($sth = $dbh->prepare($stmt13));
&stmt_ok(0);

@bind = ( "3", "Frederick the Great" );
&stmt_note("# Testing: \$sth->execute(@bind)\n");
&stmt_fail() unless ($sth->execute(@bind));
&stmt_ok(0);
&print_sqlca($sth);

&stmt_note("# Testing: \$sth->execute([4.00, \"Ghenghis Khan\"])\n");
&stmt_fail() unless ($sth->execute(4.00, "Ghenghis Khan"));
&stmt_ok(0);

&select_all({
1 => 'Jonathan Leffler',
2 => 'Alligator Descartes',
3 => 'Frederick the Great',
4 => 'Ghenghis Khan',
});

# FREE the statement and asociated data
undef $sth;

&stmt_note("# Testing: \$dbh->disconnect()\n");
&stmt_fail() unless ($dbh->disconnect);
&stmt_ok(0);

&all_ok;
