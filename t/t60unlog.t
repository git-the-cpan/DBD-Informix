#!/usr/bin/perl -w
#
# @(#)$Id: t/t60unlog.t version /main/12 2000-02-10 16:53:48 $ 
#
# Portions Copyright 1997,1999 Jonathan Leffler
# Portions Copyright 2000      Informix Software Inc
# Portions Copyright 2002      IBM
#
# Test that unlogged databases refuse to connect with AutoCommit => 0

use DBD::Informix::TestHarness;

my ($dbname) = "dbd_ix_db";
my ($user) = $ENV{DBD_INFORMIX_USERNAME};
my ($pass) = $ENV{DBD_INFORMIX_PASSWORD};

&stmt_note("# Test DBI->connect('dbi:Informix:.DEFAULT.')\n");
stmt_fail unless ($dbh = DBI->connect('dbi:Informix:.DEFAULT.', $user, $pass));

stmt_note("1..8\n");
stmt_ok;

# Don't care about non-existent database
$dbh->{PrintError} = 0;
$dbh->do("drop database $dbname");
$dbh->{PrintError} = 1;

$selver = "SELECT TabName, Owner FROM 'informix'.SysTables WHERE TabName = ' VERSION'";

&stmt_note("# Create unlogged database $dbname\n");
&stmt_test($dbh, "create database $dbname");

if ($dbh->{ix_ServerVersion} >= 800 && $dbh->{ix_ServerVersion} < 900)
{
	# XPS 8.xx does not support unlogged databases, so this test is
	# doomed to fail if it runs against XPS.
	$dbh->{PrintError} = 0;
	$dbh->do("close database");
	$dbh->do("drop database $dbname");
	$dbh->disconnect;
	&stmt_note("# XPS database - no unlogged databases!\n");
	my($i);
	# Already printed 2 ok's (one in stmt_test); 6 more needed.
	for ($i = 0; $i < 6; $i++) { &stmt_ok; }
	&all_ok;
	exit 0;
}

&select_some_data($dbh, 1, $selver);
&stmt_test($dbh, "close database");
stmt_fail unless ($dbh->disconnect);
stmt_ok;
undef $dbh;

my $msg;
$SIG{__WARN__} = sub { $msg = $_[0]; };
&stmt_note("# Test DBI->connect('dbi:Informix:$dbname',...,{AutoCommit=>0})\n");
$dbh = DBI->connect("dbi:Informix:$dbname", $user, $pass,
					{ AutoCommit => 0, PrintError => 1 });
$SIG{__WARN__} = 'DEFAULT';
# Under DBI 0.85, this connection worked.  Ideally it should have failed.
# Under DBI 0.90, this connection fails, as it is supposed to!
&stmt_ok if (!defined $dbh);
&stmt_fail unless ($msg && $msg =~ /-256:/);
$msg =~ s/\n/ /mg;
&stmt_note("# $msg\n");

# Remove test database
stmt_fail unless ($dbh = DBI->connect('dbi:Informix:.DEFAULT.', $user, $pass));
$dbh->{PrintError} = 1;
&stmt_test($dbh, "drop database $dbname");
stmt_fail unless ($dbh->disconnect);
stmt_ok;

&all_ok();
