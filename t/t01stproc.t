#!/usr/bin/perl -w
#
#	@(#)$Id: t01stproc.t,v 62.1 1999/09/19 21:18:32 jleffler Exp $ 
#
#	Test stored procedure handling for DBD::Informix
#
#	Copyright (C) 1999 Jonathan Leffler

BEGIN { require "perlsubs/InformixTest.pl"; }

&stmt_note("1..9\n");

$dbh = &connect_to_test_database();
&stmt_ok(0);

# Test stored procedures...
&stmt_fail unless ($dbh->{ix_ProductVersion} >= 500);

$stmt10 = "DROP PROCEDURE dbd_ix_01";
{
my ($q) = $dbh->{PrintError};
$dbh->{PrintError} = 0;
&stmt_test($dbh, $stmt10, 1);
$dbh->{PrintError} = $q;
}

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


&stmt_note("# Testing: \$dbh->disconnect()\n");
&stmt_fail() unless ($dbh->disconnect);
&stmt_ok(0);

&all_ok;
