#!/usr/bin/perl -w
#
#	@(#)$Id: t99clean.t,v 62.1 1999/09/19 21:18:32 jleffler Exp $ 
#
#	Clean up DBD::Informix testing debris from the test database
#   NB: Running with AutoCommit on.
#
#	Copyright (C) 1998-99 Jonathan Leffler

BEGIN { require "perlsubs/InformixTest.pl"; }

my ($dbh) = &connect_to_test_database();

&stmt_note("1..1\n");

&cleanup_database($dbh);

$dbh->disconnect;

# Now, what about the dbd_ix_db database?!!!

&stmt_ok();

&all_ok();
