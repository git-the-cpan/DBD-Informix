#!/usr/bin/perl -w
#
#	@(#)chopblanks.t	54.2 97/05/15 16:20:37
#
#	ChopBLanks attribute test script for DBD::Informix
#
#	Copyright (C) 1997 Jonathan Leffler

use DBD::InformixTest;

$tabname = "dbd_ix_trbl_01";

$dbh = &connect_to_test_database();
$subtests = 5;
$comtests = 2;
$multiplier = 2;
$multiplier = 4 if (defined $dbh->{ix_InformixOnLine});
$ntests = $subtests * $multiplier + $comtests;
&stmt_note("1..$ntests\n");
&stmt_ok(0);

# Expected results (data loaded from @expect_vc in each case)
# @expect_vc -- VARCHAR (either way)
# @expect_ct -- CHAR with trailing blanks
# @expect_cn -- CHAR without trailing blanks
@expect_vc = ( "ABC", "ABC   ", "ABCDEFGHIJ" );
@expect_ct = ( "ABC       ", "ABC       ", "ABCDEFGHIJ" );
@expect_cn = ( "ABC", "ABC", "ABCDEFGHIJ" );	

sub test_trailing_blanks
{
	my ($type, @expect) = @_;
	my ($i) = 1;
	my ($ref, @row, $sth);

	&stmt_note("# Testing $type - ChopBlanks set to $dbh->{ChopBlanks}\n");
	&stmt_fail() unless $dbh->do("CREATE TEMP TABLE $tabname (Col01 INTEGER NOT NULL, Col02 $type(10) NOT NULL)");
	&stmt_fail() unless $ins = $dbh->prepare("INSERT INTO $tabname VALUES(?, ?)");
	for ($i = 0; $i < @expect_vc; $i++)
	{
		&stmt_fail() unless $ins->execute($i+1, $expect_vc[$i]);
	}
	&stmt_fail() unless $ins->finish();
	&stmt_ok();

	&stmt_fail() unless $sth = $dbh->prepare("SELECT Col01, Col02 FROM $tabname ORDER BY Col01");
	&stmt_fail() unless $sth->execute();;
	$i = 0;
	while ($ref = $sth->fetch())
	{
		@row = @{$ref};
		&stmt_note("# Actual $row[0] <<$row[1]>>\n");
		my($k) = $i + 1;
		&stmt_note("# Expect $k <<$expect[$i]>>\n");
		&stmt_fail() if ($row[0] != $k || $row[1] ne $expect[$i]);
		&stmt_ok();
		$i++;
	}
	&stmt_fail() unless $sth->finish();
	undef $sth;
	&stmt_fail() unless $dbh->do("DROP TABLE $tabname");
	&stmt_ok();
}

&stmt_note("# ChopBlanks set to $dbh->{ChopBlanks} at startup\n");

$dbh->{ChopBlanks} = 0;		# Preserve trailing blanks!
&test_trailing_blanks("CHAR   ", @expect_ct);
&test_trailing_blanks("VARCHAR", @expect_vc) if (defined $dbh->{ix_InformixOnLine});

$dbh->{ChopBlanks} = 1;		# Chop trailing blanks!
&test_trailing_blanks("CHAR   ", @expect_cn);
&test_trailing_blanks("VARCHAR", @expect_vc) if (defined $dbh->{ix_InformixOnLine});

&stmt_fail() unless ($dbh->disconnect);
&stmt_ok();

&all_ok;
