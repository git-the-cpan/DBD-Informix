#!/usr/bin/perl -w
#
#	@(#)$Id: t/t57tables.t version /main/5 2000-01-27 16:21:26 $ 
#
#	Test tables
#
#	Copyright (C) 1999 Jonathan Leffler

use DBD::Informix::TestHarness;
use strict;

&stmt_note("1..5\n");

my $dbh = connect_to_test_database();
&stmt_ok;

$dbh->{PrintError} = 1;

&cleanup_database($dbh);

# How do you verify the table list?
# With difficulty, since there are different numbers of system tables
# in different versions of Informix, and you don't know what's in the
# user-defined portion of the database.  So, create our own table, view,
# synonym, etc, and check that SysTables and SysColumns turn up in the list.

my ($tbname) = "dbd_ix_table";
$dbh->do("CREATE TABLE $tbname (col01 CHAR(10), col02 CHAR(20))") or &stmt_fail;
my ($vwname) = "dbd_ix_view";
$dbh->do("CREATE VIEW $vwname AS SELECT Col01 FROM $tbname") or &stmt_fail;
my ($pbname) = "dbd_ix_pubsyn";
$dbh->do("CREATE SYNONYM $pbname FOR $vwname") or &stmt_fail;
my ($prname) = "dbd_ix_prvsyn";
my ($snexp) = 1;
if ($dbh->{ix_ModeAnsiDatabase} == 0)
{
	$dbh->do("CREATE PRIVATE SYNONYM $prname FOR $tbname") or &stmt_fail;
	$snexp++;
}
&stmt_ok;

my @tables = $dbh->tables or &stmt_fail;
&stmt_ok;

my $table;

my ($cnt, $systab, $syscol, $tbcnt, $vwcnt, $sncnt) = (0, 0, 0, 0, 0, 0);
foreach $table (@tables)
{
	print "$table\n";
	$systab++ if ($table =~ /systables/i);
	$syscol++ if ($table =~ /syscolumns/i);
	$tbcnt++  if ($table =~ /$tbname/i);
	$vwcnt++  if ($table =~ /$vwname/i);
	$sncnt++  if ($table =~ /$pbname/i || $table =~ /$prname/i);
	$cnt++;
}

# Check multiple uses!
@tables = $dbh->tables or &stmt_fail;
my ($chk) = 0;
foreach $table (@tables)
{
	$chk++;
}
&stmt_fail unless $chk == $cnt;

# Clean up (dropping table drops views and synonyms!)
$dbh->do("DROP TABLE $tbname") or &stmt_fail;
&stmt_ok;

&stmt_fail unless $systab == 1 && $syscol == 1 && $tbcnt == 1 && $vwcnt == 1 && $sncnt == $snexp;
&stmt_fail unless $cnt > 10;
&stmt_ok;

$dbh->disconnect or &stmt_fail;

&all_ok;

