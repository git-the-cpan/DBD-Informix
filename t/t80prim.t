#!/usr/bin/perl -w
#
# @(#)$Id: t/t80prim.t version /main/13 2000-01-27 16:21:49 $ 
#
# (c)1996 Hermetica. Written by Alligator Descartes <descarte@hermetica.com>
#
# Portions Copyright (C) 1996-99 Jonathan Leffler
# Portions Copyright (C) 2002    IBM
#
# Exercises the returning of error codes in ESQL/C intermediate step failure

use strict;
use DBD::Informix::TestHarness;

my ($dbh, $cursor, @row);

print("1..8\n");
$dbh = connect_to_test_database();
stmt_ok;
print "# Installed and connected\n";

stmt_test $dbh, "CREATE TEMP TABLE DBD_IX_Test (x DATETIME YEAR TO SECOND)", 0;
stmt_test $dbh, "INSERT INTO DBD_IX_Test VALUES (CURRENT YEAR TO SECOND)", 0;

stmt_fail unless ($cursor = $dbh->prepare("SELECT x FROM DBD_IX_Test"));
stmt_ok;
print "# Prepared\n";

stmt_fail unless ($cursor->execute);
stmt_ok;
print "# Executed\n";

stmt_fail unless (@row = $cursor->fetchrow);
stmt_ok;
print "# @row\n";
print "# Fetched\n";

stmt_fail unless ($cursor->finish);
stmt_ok;
print "# Finished\n";

undef $cursor;

stmt_fail unless ($dbh->disconnect);
stmt_ok;
print "# Disconnected\n";
all_ok;
