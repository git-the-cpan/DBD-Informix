#!/usr/bin/perl -w
#
# @(#)original.t	25.2 96/12/04 14:22:29
#
# (c)1996 Hermetica. Written by Alligator Descartes <descarte@hermetica.com>
#
# Original basic test -- rewritten to use DBD::InformixTest

use DBD::InformixTest;

print("1..11\n");

$dbh = connect_to_test_database();
&stmt_ok;

print "# Preparing SELECT * from systables ***\n";

$cursor = $dbh->prepare("SELECT * FROM systables");
&stmt_fail() unless (defined $cursor);
&stmt_ok;

&stmt_fail() unless $cursor->execute;
&stmt_ok;

print "# Selecting data as an array ***\n";

# Do not rely on the number of tables in Systables -- it varies too much!
my $i = 0;
while (@row = $cursor->fetchrow)
{
	$i++;
    print "# Row: @row\n";
}

&stmt_fail() unless $i > 0;
&stmt_ok;

&stmt_fail() unless $cursor->finish;
&stmt_ok;
undef $cursor;

print "# Preparing SELECT * FROM systables WHERE tabname = 'systables' ***\n";

$cursor2 = $dbh->prepare("SELECT tabname, owner FROM systables" .
						 " WHERE tabname = 'systables'");
&stmt_fail() unless (defined $cursor2);
&stmt_ok;

&stmt_fail() unless $cursor2->execute;
&stmt_ok;

print # Selecting data as a list of specified vars ***\n";

$i = 0;
while (($tabname, $owner) = $cursor2->fetchrow)
{
	$i++;
    print "# tabname = $tabname\towner = $owner\n";
}

&stmt_fail() unless $i > 0;
&stmt_ok;

&stmt_fail() unless $cursor2->finish;
&stmt_ok;
undef $cursor2;

&stmt_fail() unless $dbh->do("CREATE TEMP TABLE pants2 (a INTEGER)");
&stmt_ok;

&stmt_fail() unless $dbh->disconnect;
&stmt_ok;
&all_ok;
