#!/usr/bin/perl -w
#
#	@(#)$Id: t/t20error.t version /main/9 2000-01-27 16:20:31 $ 
#
#	Test error on EXECUTE for DBD::Informix
#
#	Copyright (C) 1997,1999 Jonathan Leffler

use DBD::Informix::TestHarness;

# Test install...
$dbh = &connect_to_test_database();

$tabname = "dbd_ix_err01";

&stmt_note("1..5\n");
&stmt_ok();

stmt_test $dbh, qq{
CREATE TEMP TABLE $tabname
(
	Col01	SERIAL NOT NULL PRIMARY KEY,
	Col02	CHAR(20) NOT NULL
)
};

stmt_test $dbh, qq{ CREATE UNIQUE INDEX pk_$tabname ON $tabname(Col02) };

$insert01 = qq{ INSERT INTO $tabname VALUES(0, 'Gee Whizz!') };

$sth = $dbh->prepare($insert01) or die "Prepare failed\n";

# Should be OK!
$rv = $sth->execute();
stmt_fail() if ($rv != 1);

my $msg;
$SIG{__WARN__} = sub { $msg = $_[0]; };

# Should fail (dup value)!
$rv = $sth->execute();
if (defined $rv)
{
	print "# Return from failed execute = <<$rv>>\n";
	stmt_fail();
}
&stmt_fail() unless ($msg && $msg =~ /-100:/ && $msg =~ /-239:/);
$SIG{__WARN__} = 'DEFAULT';

@isam = @{$sth->{ix_sqlerrd}};
print "# SQL = $sth->{ix_sqlcode}; ISAM = $isam[1]\n";
print "# DBI::state: $DBI::state\n";
print "# DBI::err:   $DBI::err\n";
print "# DBI::errstr:\n$DBI::errstr\n";
stmt_ok();

select_some_data $dbh, 1, "SELECT * FROM $tabname";

all_ok();
