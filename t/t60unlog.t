#!/usr/bin/perl -w
#
# @(#)$Id: t/t60unlog.t version /main/11 2000-02-10 12:10:42 $ 
#
# Portions Copyright 1997,1999 Jonathan Leffler
# Portions Copyright 2000      Informix Software Inc
#
# Test that unlogged databases refuse to connect with AutoCommit => 0

use DBD::Informix::TestHarness;

my ($dbname) = "dbd_ix_db";
my ($user) = $ENV{DBD_INFORMIX_USERNAME};
my ($pass) = $ENV{DBD_INFORMIX_PASSWORD};

&stmt_note("# Test DBI->connect('dbi:Informix:.DEFAULT.')\n");
stmt_fail unless ($dbh = DBI->connect('dbi:Informix:.DEFAULT.', $user, $pass));

if ($dbh->{ix_ServerVersion} >= 800 && $dbh->{ix_ServerVersion} < 900)
{
	# XPS 8.xx does not support unlogged databases, so this test is
	# doomed to fail if it runs against XPS.
	$dbh->disconnect or stmt_fail;
	print "1..0\n";
	exit 0;
}

stmt_note("1..8\n");
stmt_ok;

# Don't care about non-existent database
$dbh->{PrintError} = 0;
$dbh->do("drop database $dbname");

$selver = "SELECT TabName, Owner FROM 'informix'.SysTables WHERE TabName = ' VERSION'";

$dbh->{PrintError} = 1;
&stmt_note("# Create unlogged database $dbname\n");
&stmt_test($dbh, "create database $dbname");
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
