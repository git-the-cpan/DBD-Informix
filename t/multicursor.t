#!/usr/bin/perl -w
#
# @(#)multicursor.t	25.3 96/12/04 14:38:27
#
# (c)1996 Hermetica. Written by Alligator Descartes <descarte@hermetica.com>
#
# Tests multiple simultaneous cursors being open

use DBD::InformixTest;

print "1..17\n";
$dbh = connect_to_test_database();
&stmt_ok(0);
$dbh->{AutoErrorReport} = 0;

$tablename1 = "test1";
$tablename2 = "test2";

# Should not succeed, but doesn't matter.
$dbh->do("DROP TABLE $tablename1");
$dbh->do("DROP TABLE $tablename2");

# These should be fine...
&stmt_test($dbh, "CREATE TEMP TABLE $tablename1 (id1 INTEGER, " .
		 "id2 SMALLINT, id3 FLOAT, id4 DECIMAL, name CHAR(64))");
&stmt_test($dbh, "INSERT INTO $tablename1 VALUES(1122, " .
		 "-234, -3.1415926, 3.7655, 'Hortense HorseRadish')");
&stmt_test($dbh, "INSERT INTO $tablename1 VALUES(1001002002, " .
		 "+342, -3141.5926, 3.7655e25, 'Arbuthnot Artichoke')");
&stmt_test($dbh, "CREATE TEMP TABLE $tablename2 (id INTEGER, name CHAR(64))");
&stmt_test($dbh, "INSERT INTO $tablename2 VALUES(379, 'Mauritz Escher')");
&stmt_test($dbh, "INSERT INTO $tablename2 VALUES(380, 'Salvador Dali')");

# Prepare the first SELECT statement
&stmt_note("# 1st SELECT:\n");
$sth1 = $dbh->prepare("SELECT id1, id2, id3, id4, name FROM $tablename1");
&stmt_fail() if (!defined $sth1);
&stmt_ok(0);

# Prepare the second SELECT statement
&stmt_note("# 2nd SELECT\n");
$sth2 = $dbh->prepare("SELECT id, name FROM $tablename2");
&stmt_fail() if (!defined $sth2);
&stmt_ok(0);

# Open the first cursor
&stmt_note("# Open 1st cursor\n");
&stmt_fail() unless $sth1->execute;
&stmt_ok(0);

# Open the second cursor
&stmt_note("# Open 2nd cursor\n");
&stmt_fail() unless $sth2->execute;
&stmt_ok(0);

while (@row1 = $sth1->fetchrow)
{
    print "# Row1: @row1\n";
	&stmt_ok(0);
    @row2 = $sth2->fetchrow;
    if (defined @row2)
	{
        print "# Row2: @row2\n";
		&stmt_ok(0);
    }
}

# Close the cursors
&stmt_note("# Close 1st cursor\n");
&stmt_fail() unless $sth1->finish;
&stmt_ok(0);
undef $sth1;

&stmt_note("# Close 2nd cursor\n");
&stmt_fail() unless $sth2->finish;
&stmt_ok(0);
undef $sth2;

$dbh->disconnect;

&all_ok();

exit;
