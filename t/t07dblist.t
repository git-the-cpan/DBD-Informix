#!/usr/bin/perl -w
#
# @(#)$Id: t/t07dblist.t version /main/12 2000-02-03 15:53:57 $ 
#
# Portions Copyright 1996    Hermetica. Written by Alligator Descartes <descarte@hermetica.com>
# Portions Copyright 1996-99 Jonathan Leffler
# Portions Copyright 2000    Informix Software Inc
#
# List of available databases:
#   @ary = $DBI->data_sources('Informix');

use DBD::Informix::TestHarness;

@ary = DBI->data_sources('Informix');

if (!defined @ary)
{
	if ($ENV{DBD_INFORMIX_USERNAME} && $ENV{DBD_INFORMIX_PASSWORD} && $DBI::err == -951)
	{
		# Problem is with default connection and sqgetdbs().
		print "1..0\n";
		&stmt_note("# Test: DBI->data_sources('Informix'): skipped\n");
	}
	else
	{
		print "1..1\n";
		&stmt_note("# Test: DBI->data_sources('Informix'): failed\n");
		&stmt_fail();
	}
}
else
{
	$x = @ary;
	print "1..$x\n";
	&stmt_note("# Test: DBI->data_sources('Informix'):\n");
	foreach $db (@ary)
	{
		&stmt_note("# Database: $db\n");
		($db =~ /^dbi:Informix:/) ? &stmt_ok(0) : &stmt_fail();
	}
}

&all_ok();

exit 0;
