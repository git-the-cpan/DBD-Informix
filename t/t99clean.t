#!/usr/bin/perl -w
#
#	@(#)$Id: t99clean.t,v 61.2 1998/11/23 21:26:42 jleffler Exp $ 
#
#	Clean up DBD::Informix testing debris from the test database
#   NB: Running with AutoCommit on.
#
#	Copyright (C) 1998 Jonathan Leffler

use DBD::InformixTest;

my ($dbh) = &connect_to_test_database();

&stmt_note("1..1\n");

# Do not report any errors.
$dbh->{PrintError} = 0;

# Clean up from any previous runs.
foreach $type ('view', 'synonym', 'base')
{
	my $kw = $type;
	$kw =~ s/base/table/;
	my @names = grep /\.dbd_ix_/i, $dbh->func($type, '_tables');
	foreach (@names)
	{
		&stmt_note("# drop $kw $_\n");
		$dbh->do(qq% drop $kw $_ %);
	}
}

# IUS test debris!
$dbh->do(q% DROP TABLE dbd_ix_maker %);
$dbh->do(q% DROP TABLE dbd_ix_location %);
$dbh->do(q% DROP ROW TYPE dbd_ix_location RESTRICT %);
$dbh->do(q% DROP TYPE dbd_ix_percent RESTRICT %);

$dbh->disconnect;

&stmt_ok();

&all_ok();


