#!/usr/bin/perl -w
#
# @(#)dblist.t	51.1 97/02/25 19:43:02
#
# (c)1996 Hermetica. Written by Alligator Descartes <descarte@hermetica.com>
#
# Portions Copyright (C) 1996,1997 Jonathan Leffler
#
# List of available databases:
#   @ary = $drh->func('_ListDBs');

use DBD::InformixTest qw(stmt_ok stmt_fail stmt_note all_ok);

$drh = DBI->install_driver('Informix');

@ary = $drh->func('_ListDBs');
if (!defined @ary)
{
	print "1..1\n";
	&stmt_note("# Test: \$drh->func('_ListDBs'):\n");
	&stmt_fail();
}
else
{
	$x = @ary;
	print "1..$x\n";
	&stmt_note("#Test: \$drh->func('_ListDBs'):\n");
	foreach $db (@ary)
	{
		&stmt_note("# Database: $db\n");
		&stmt_ok(0);
	}
}

&all_ok();

exit 0;
