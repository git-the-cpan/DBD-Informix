#!/usr/bin/perl -w
#
#   @(#)$Id: t60unlog.t,v 2003.3 2003/01/04 00:36:38 jleffler Exp $
#
#   Test that unlogged databases refuse to connect with AutoCommit => 0
#
#   Copyright 1997,1999 Jonathan Leffler
#   Copyright 2000      Informix Software Inc
#   Copyright 2002-03   IBM

use DBD::Informix::TestHarness;
use strict;

my ($dbname) = "dbd_ix_db";
my ($user) = $ENV{DBD_INFORMIX_USERNAME};
my ($pass) = $ENV{DBD_INFORMIX_PASSWORD};

&stmt_note("# Test DBI->connect('dbi:Informix:.DEFAULT.')\n");
my $dbh;
stmt_fail unless ($dbh = DBI->connect('dbi:Informix:.DEFAULT.', $user, $pass));

stmt_note("1..9\n");
stmt_ok;

# Don't care about non-existent database
$dbh->{PrintError} = 0;
$dbh->do("drop database $dbname");
$dbh->{PrintError} = 1;
$dbh->{ChopBlanks} = 1;

my $select = "SELECT TabName, Owner FROM 'informix'.SysTables WHERE TabID = 1";

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

my $result = { 'systables' => { 'owner' => 'informix', 'tabname' => 'systables' } };

my $sth = $dbh->prepare($select) or stmt_fail;
stmt_ok;
$sth->execute ? validate_unordered_unique_data($sth, 'tabname', $result) : &stmt_nok;

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
&stmt_note("# Connection failed - which is the correct response\n") if (!defined $dbh);
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
