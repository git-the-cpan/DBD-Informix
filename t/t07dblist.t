#!/usr/bin/perl -w
#
# @(#)$Id: t/t07dblist.t version /main/13 2000-02-08 17:06:44 $ 
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
	if ($ENV{DBD_INFORMIX_USERNAME} && $ENV{DBD_INFORMIX_PASSWORD} && ($DBI::err == -951 || $DBI::err == -956)) 
	{
		# Problem is with default connection and sqgetdbs().
		# -951	User username is not known on the database server.
		# -956	Client client-name or user is not trusted by the database server.
		# There could be other errors which should cause test to be skipped.
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
	# Note that there is not very much we can do to validate database list.
	&stmt_note("# Test: DBI->data_sources('Informix'):\n");
	&stmt_fail("# *** No databases to list? ***\n") if ($#ary < 0);
	foreach $db (@ary)
	{
		&stmt_note("# Database: $db\n");
		($db =~ /^dbi:Informix:/) ? &stmt_ok(0) : &stmt_fail();
	}
}

&all_ok();

exit 0;
