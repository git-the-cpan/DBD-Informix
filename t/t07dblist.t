#!/usr/bin/perl -w
#
# @(#)$Id: t07dblist.t,v 60.1 1998/07/30 22:37:24 jleffler Exp $ 
#
# (c)1996 Hermetica. Written by Alligator Descartes <descarte@hermetica.com>
#
# Portions Copyright (C) 1996,1997 Jonathan Leffler
#
# List of available databases:
#   @ary = $DBI->data_sources('Informix');

use DBD::InformixTest qw(stmt_ok stmt_fail stmt_note all_ok);

@ary = DBI->data_sources('Informix');

if (!defined @ary)
{
	print "1..1\n";
	&stmt_note("# Test: DBI->data_sources('Informix'):\n");
	&stmt_fail();
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
