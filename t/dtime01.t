#!/usr/bin/perl -w
#
# @(#)$Id: dtime01.t,v 59.2 1998/03/11 17:32:32 jleffler Exp $
#
# Copyright (C) 1998 Jonathan Leffler (johnl@informix.com)
#
# Test for handling DATETIME literals in SQL statements
# Note that DBD::Informix would mangle a time such as '12:30:23' to '12??'
# because dbd_ix_preparse() would treat the :30 as a positional parameter
# (in a misguided attempt to accommodate Oracle scripts).

use DBI;
use DBD::InformixTest qw(stmt_ok stmt_fail stmt_note all_ok stmt_test
connect_to_test_database select_some_data);

print("1..11\n");

# Test installation of driver
# NB: Do not use install_driver in your own code.
#     Use DBI->connect as shown below.
&stmt_note("# Testing: DBI->install_driver('Informix')\n");
$drh = DBI->install_driver('Informix');
&stmt_ok(0);

print "# DBI Information\n";
print "#     Version:               $DBI::VERSION\n";
print "# Generic Driver Information\n";
print "#     Type:                  $drh->{Type}\n";
print "#     Name:                  $drh->{Name}\n";
print "#     Version:               $drh->{Version}\n";
print "#     Attribution:           $drh->{Attribution}\n";
print "# Informix Driver Information\n";
print "#     Product:               $drh->{ix_ProductName}\n";
print "#     Product Version:       $drh->{ix_ProductVersion}\n";
print "#     Multiple Connections:  $drh->{ix_MultipleConnections}\n";
print "#     Active Connections:    $drh->{ix_ActiveConnections}\n";
print "#     Current Connection:    $drh->{ix_CurrentConnection}\n";
print "# \n";

$tablename = "dbd_ix_test3";

$dbh = connect_to_test_database(1);
&stmt_ok;

$stmt1 = qq{
CREATE TEMP TABLE $tablename
(
	id1     INTEGER,
	id2     DATETIME YEAR TO SECOND,
	id3     INTERVAL HOUR(6) TO FRACTION(3)
)
};
$stmt1 =~ s/\s+/ /gm;
&stmt_test($dbh, $stmt1, 0);

&stmt_test($dbh, qq"INSERT INTO $tablename VALUES(1122,
				 DATETIME(1998-03-05 09:11:46) YEAR TO SECOND,
				 INTERVAL(23:59:59.999) HOUR(6) TO FRACTION(3))");
&stmt_test($dbh, qq"INSERT INTO $tablename VALUES(1001002002,
				 DATETIME(2000-02-29 23:59:59) YEAR TO SECOND,
				 INTERVAL(-2223:09:50.630) HOUR(6) TO FRACTION(3))");

$stmt2 = qq"SELECT id1, id2, id3 FROM $tablename
	WHERE id2 > DATETIME(1970-01-01 00:00:00) YEAR TO SECOND
	  AND id3 > INTERVAL(-10000:00:00.000) HOUR(6) TO FRACTION(3)";
&stmt_note("# Testing: prepare('$stmt2')\n");
$sth = $dbh->prepare($stmt2);
&stmt_fail() unless (defined $sth);
&stmt_ok(0);

&stmt_fail() unless $sth->execute;
&stmt_ok(0);

while (($id1, $id2, $id3) = $sth->fetchrow)
{
	&stmt_ok(0);
    &stmt_note("# Row: $id1\t$id2\t$id3\n");
}

&stmt_fail() unless $sth->finish;
&stmt_ok(0);
undef $sth;

&stmt_fail() unless $dbh->disconnect;
&stmt_ok(0);
&all_ok();
