#!/usr/bin/perl -w
#
#	@(#)multiconn01.t	51.1 97/02/25 19:43:06
#
#	Test Multiple Connections for DBD::Informix
#
#	Copyright (C) 1996,1997 Jonathan Leffler

use DBD::InformixTest;

$dbase1 = $ENV{DBD_INFORMIX_DATABASE};
$dbase1 = "stores" unless ($dbase1);
$dbase2 = $ENV{DBD_INFORMIX_DATABASE2};
$dbase2 = "stores" unless ($dbase2);

sub info_usertables
{
	my ($dbh) = @_;
	my ($sth);
	my ($row);

	my ($stmt) =
		"SELECT TabName FROM 'informix'.SysTables" .
		" WHERE TabID >= 100 AND TabType = 'T'" .
		" ORDER BY TabName";
	&stmt_fail() unless ($sth = $dbh->prepare($stmt));
	&stmt_ok();
	&stmt_fail() unless ($sth->execute());
	&stmt_ok();
	$n = 0;
	while ($row = $sth->fetch())
	{
		@row = @{$row};
		print "# $n: $row[0]\n";
		$n++;
	}
	&stmt_fail() unless ($sth->finish());
	&stmt_ok();
}

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

&stmt_note("1..23\n");
&stmt_ok();

&stmt_fail() unless ($dbh1 = $drh->connect($dbase1));
&stmt_ok();

print "# Database Information\n";
print "#     Database Name:           $dbh1->{Name}\n";
print "#     Informix-OnLine:         $dbh1->{InformixOnLine}\n";
print "#     Logged Database:         $dbh1->{LoggedDatabase}\n";
print "#     Mode ANSI Database:      $dbh1->{ModeAnsiDatabase}\n";
print "#     AutoCommit:              $dbh1->{AutoCommit}\n";
print "#     AutoErrorReport:         $dbh1->{AutoErrorReport}\n";
print "#     Transaction Active:      $dbh1->{InTransaction}\n";
print "#\n";

&info_usertables($dbh1);

&stmt_fail() unless ($dbh2 = $drh->connect($dbase2));
&stmt_ok();

print "# Database Information\n";
print "#     Database Name:           $dbh2->{Name}\n";
print "#     Informix-OnLine:         $dbh2->{InformixOnLine}\n";
print "#     Logged Database:         $dbh2->{LoggedDatabase}\n";
print "#     Mode ANSI Database:      $dbh2->{ModeAnsiDatabase}\n";
print "#     AutoCommit:              $dbh2->{AutoCommit}\n";
print "#     AutoErrorReport:         $dbh2->{AutoErrorReport}\n";
print "#     Transaction Active:      $dbh2->{InTransaction}\n";
print "#\n";

&info_usertables($dbh2);

# Demonstrate that previous database is still accessible...
&info_usertables($dbh1);

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

while (@row1 = $st1->fetchrow)
{
	print "# 1: $row1[0]\n";
}
&stmt_fail() unless ($st1->finish);
&stmt_ok();

while ($row2 = $st2->fetch)
{
	print "# 2: ${$row2}[0]\n";
	print "# 2: ${$row2}[1]\n";
}
&stmt_fail() unless ($st2->finish);
&stmt_ok();

&stmt_note("# Testing: \$dbh1->disconnect()\n");
&stmt_fail() unless ($dbh1->disconnect);
&stmt_ok();

&info_usertables($dbh2);

&stmt_note("# Testing: \$dbh2->disconnect()\n");
&stmt_fail() unless ($dbh2->disconnect);
&stmt_ok();

&all_ok();