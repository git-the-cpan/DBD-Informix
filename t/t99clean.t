#!/usr/bin/perl -w
#
#	@(#)$Id: t99clean.t,v 100.3 2002/02/08 22:51:15 jleffler Exp $ 
#
#	Clean up DBD::Informix testing debris from the test database
#	NB: Running with AutoCommit on.
#
#	Copyright 1998-99 Jonathan Leffler
#	Copyright 2000    Informix Software Inc
#	Copyright 2002    IBM

use DBD::Informix::TestHarness;

my ($dbh) = &connect_to_test_database();

&stmt_note("1..1\n");

&cleanup_database($dbh);

$dbh->disconnect;

# Now, what about the dbd_ix_db database?!!!

&stmt_ok();

&all_ok();
