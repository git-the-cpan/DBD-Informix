#!/usr/bin/perl -w
#
#	@(#)$Id: t/t83oconn.t version /main/5 2000-01-27 16:21:57 $ 
#
#	Check old connection method for DBD::Informix
#
#   Derived from t00basic.t.
#
#   *** DO NOT USE THE CONNECTION METHOD WITH 'Informix' AS 4TH ARGUMENT ***
#
#	Copyright (C) 1999 Jonathan Leffler

use DBD::Informix::TestHarness;

&stmt_note("1..3\n");

my $dbname;

{
my $dbh = &connect_to_test_database() or &stmt_fail;
$dbname = $dbh->{Name};
$dbh->disconnect() or &stmt_fail;
&stmt_ok;
}

# Old-style connect -- do not use this notation!
{
my $dbh;
my $user = $ENV{DBD_INFORMIX_USERNAME};
my $pass = $ENV{DBD_INFORMIX_PASSWORD};
$user = "" if (!defined $user);
$pass = "" if (!defined $pass);
my $mask = $pass;
$mask =~ s/./X/g;
&stmt_note("# Testing: DBI->connect('$dbname', '$user', '$mask', 'Informix')\n");
&stmt_fail() unless ($dbh = DBI->connect($dbname, $user, $pass, 'Informix'));
&stmt_ok();
&stmt_fail() unless ($dbh->disconnect);
&stmt_ok();
}

&all_ok;
