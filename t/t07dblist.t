#!/usr/bin/perl -w
#
#	@(#)$Id: t07dblist.t,v 100.9 2002/10/19 00:33:23 jleffler Exp $ 
#
#	List of available databases:
#	@ary = $DBI->data_sources('Informix');
#
#	Copyright 1996    Hermetica. Written by Alligator Descartes <descarte@hermetica.com>
#	Copyright 1996-99 Jonathan Leffler
#	Copyright 2000    Informix Software Inc
#	Copyright 2002    IBM
#

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
		print "1..0 # Skip: Test: DBI->data_sources('Informix'): skipped\n";
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
	$y = $x + 1;
	print "1..$y\n";
	# Note that there is not very much we can do to validate database list.
	&stmt_note("# Test: DBI->data_sources('Informix'):\n");
	&stmt_fail("# *** No databases to list? ***\n") if ($#ary < 0);
	$srv = 0;
	foreach $db (@ary)
	{
		&stmt_note("# Database: $db\n");
		($db =~ /^dbi:Informix:/) ? &stmt_ok(0) : &stmt_fail();
		$srv++ if ($db =~ /\@$ENV{INFORMIXSERVER}$/o);
	}
	&stmt_fail("# No databases match INFORMIXSERVER=$ENV{INFORMIXSERVER}\n") if ($srv == 0);
	&stmt_ok();
}

&all_ok();

exit 0;
