#!/usr/bin/perl -w
#
#	@(#)multiconn02.t	53.1 97/03/06 20:37:32
#
#	Test DISCONNECT ALL for DBD::Informix
#
#	Copyright (C) 1996,1997 Jonathan Leffler

use DBD::InformixTest;

$dbase1 = $ENV{DBD_INFORMIX_DATABASE};
$dbase1 = "stores" unless ($dbase1);
$dbase2 = $ENV{DBD_INFORMIX_DATABASE2};
$dbase2 = "stores" unless ($dbase2);

# Test install...
&stmt_note("# Testing: DBI->install_driver('Informix')\n");
$drh = DBI->install_driver('Informix');

print "# Driver Information\n";
print "#     Name:                  $drh->{Name}\n";
print "#     Version:               $drh->{Version}\n";
print "#     Product:               $drh->{ProductName}\n";
print "#     Product Version:       $drh->{ProductVersion}\n";
print "#     Multiple Connections:  $drh->{MultipleConnections}\n";
print "# \n";

if ($drh->{MultipleConnections} == 0)
{
	&stmt_note("1..1\n");
	&stmt_note("# Multiple connections are not supported\n");
	&stmt_ok(0);
	&all_ok();
}

&stmt_note("1..9\n");
&stmt_ok();

&stmt_fail() unless ($dbh1 = $drh->connect($dbase1));
&stmt_ok();

print "# Database Information\n";
print "#     Database Name:           $dbh1->{Name}\n";
print "#     AutoCommit:              $dbh1->{AutoCommit}\n";
print "#     Informix-OnLine:         $dbh1->{ix_InformixOnLine}\n";
print "#     Logged Database:         $dbh1->{ix_LoggedDatabase}\n";
print "#     Mode ANSI Database:      $dbh1->{ix_ModeAnsiDatabase}\n";
print "#     AutoErrorReport:         $dbh1->{ix_AutoErrorReport}\n";
print "#     Transaction Active:      $dbh1->{ix_InTransaction}\n";
print "#\n";

&stmt_fail() unless ($dbh2 = $drh->connect($dbase2));
&stmt_ok();

print "# Database Information\n";
print "#     Database Name:           $dbh2->{Name}\n";
print "#     AutoCommit:              $dbh2->{AutoCommit}\n";
print "#     Informix-OnLine:         $dbh2->{ix_InformixOnLine}\n";
print "#     Logged Database:         $dbh2->{ix_LoggedDatabase}\n";
print "#     Mode ANSI Database:      $dbh2->{ix_ModeAnsiDatabase}\n";
print "#     AutoErrorReport:         $dbh2->{ix_AutoErrorReport}\n";
print "#     Transaction Active:      $dbh2->{ix_InTransaction}\n";
print "#\n";

$stmt1 =
	"SELECT TabName FROM 'informix'.SysTables" .
	" WHERE TabID >= 100 AND TabType = 'T'" .
	" ORDER BY TabName";

$stmt2 =
	"SELECT ColName, ColType FROM 'informix'.SysColumns" .
	" WHERE TabID = 1 ORDER BY ColName";

&stmt_fail() unless ($st1 = $dbh1->prepare($stmt1));
&stmt_ok();
&stmt_fail() unless ($st2 = $dbh2->prepare($stmt2));
&stmt_ok();

&stmt_fail() unless ($st1->execute);
&stmt_ok();
&stmt_fail() unless ($st2->execute);
&stmt_ok();

LOOP: while (1)
{
	# Yes, these are intentionally different!
	last LOOP unless (@row1 = $st1->fetchrow);
	last LOOP unless ($row2 = $st2->fetch);
	print "# 1: $row1[0]\n";
	print "# 2: ${$row2}[0]\n";
	print "# 2: ${$row2}[1]\n";
}
&stmt_ok();

&stmt_fail() unless ($drh->disconnect_all);
&stmt_ok();

&all_ok();
