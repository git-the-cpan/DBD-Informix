#!/usr/bin/perl -w
#
#	@(#)$Id: t/t99clean.t version /main/7 2000-01-27 16:22:03 $ 
#
#	Clean up DBD::Informix testing debris from the test database
#   NB: Running with AutoCommit on.
#
#	Copyright (C) 1998-99 Jonathan Leffler
#	Copyright (C) 2000    Informix Software Inc
#	Copyright (C) 2002    IBM

use DBD::Informix::TestHarness;

my ($dbh) = &connect_to_test_database();

&stmt_note("1..1\n");

&cleanup_database($dbh);

$dbh->disconnect;

# Now, what about the dbd_ix_db database?!!!

&stmt_ok();

&all_ok();
