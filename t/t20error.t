#!/usr/bin/perl -w
#
#	@(#)$Id: t20error.t,v 100.3 2002/02/08 22:50:41 jleffler Exp $ 
#
#	Test error on EXECUTE for DBD::Informix
#
#	Copyright 1997,1999 Jonathan Leffler
#	Copyright 2000      Informix Software Inc
#	Copyright 2002      IBM

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
