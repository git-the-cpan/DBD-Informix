#!/usr/bin/perl -w
#
#	@(#)$Id: t22mconn.t,v 62.2 1999/09/19 21:18:32 jleffler Exp $ 
#
#	Test DISCONNECT ALL for DBD::Informix
#
#	Copyright (C) 1996-99 Jonathan Leffler

BEGIN { require "perlsubs/InformixTest.pl"; }

$dbase1 = $ENV{DBD_INFORMIX_DATABASE};
$dbase1 = "stores" unless ($dbase1);
$dbase2 = $ENV{DBD_INFORMIX_DATABASE2};
$user1 = $ENV{DBD_INFORMIX_USERNAME};
$user2 = $ENV{DBD_INFORMIX_USERNAME2};
$pass1 = $ENV{DBD_INFORMIX_PASSWORD};
$pass2 = $ENV{DBD_INFORMIX_PASSWORD2};

$user1 = "" if (! defined $user1);
$pass1 = "" if (! defined $pass1);

if (!$dbase2)
{
	$dbase2 = $dbase1;
	$user2 = $user1;
	$pass2 = $pass1;
}

&stmt_note("# Connect to: $dbase1\n");
&stmt_fail() unless ($dbh1 = DBI->connect("DBI:Informix:$dbase1", $user1, $pass1));

print "# Driver Information\n";
print "#     Name:                  $dbh1->{Driver}->{Name}\n";
print "#     Version:               $dbh1->{Driver}->{Version}\n";
print "#     Product:               $dbh1->{ix_ProductName}\n";
print "#     Product Version:       $dbh1->{ix_ProductVersion}\n";
print "#     Multiple Connections:  $dbh1->{ix_MultipleConnections}\n";
print "# \n";

if ($dbh1->{ix_MultipleConnections} == 0)
{
	&stmt_note("1..1\n");
	&stmt_note("# Multiple connections are not supported\n");
	&stmt_ok(0);
	&all_ok();
}

&stmt_note("1..8\n");
&stmt_ok();

&print_dbinfo($dbh1);

&stmt_note("# Connect to: $dbase2\n");
&stmt_fail() unless ($dbh2 = DBI->connect("DBI:Informix:$dbase2", $user2, $pass2));
&stmt_ok();

&print_dbinfo($dbh2);

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

&stmt_fail() unless ($dbh1->{Driver}->disconnect_all);
&stmt_ok();

&all_ok();
