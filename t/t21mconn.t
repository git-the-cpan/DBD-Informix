#!/usr/bin/perl -w
#
#	@(#)$Id: t/t21mconn.t version /main/20 2000-01-20 11:43:55 $ 
#
#	Test Multiple Connections for DBD::Informix
#
#	Portions Copyright (C) 1996-99 Jonathan Leffler
#	Portions Copyright (C) 2000    Informix Software Inc

BEGIN { require "perlsubs/InformixTest.pl"; require "perlsubs/shmconn.pl"; }

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

if (&is_shared_memory_connection($dbase1) &&
	&is_shared_memory_connection($dbase2))
{
	&stmt_note("1..0\n");
	&stmt_note("# Two shared memory connections - test skipped\n");
	exit(0);
}

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

# Test connections...

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
	&stmt_note("1..0\n");
	&stmt_note("# Multiple connections are not supported\n");
	&all_ok();
}

&stmt_note("1..22\n");
&stmt_ok();

&print_dbinfo($dbh1);
&info_usertables($dbh1);

&stmt_note("# Connect to: $dbase2\n");
&stmt_fail() unless ($dbh2 = DBI->connect("DBI:Informix:$dbase2", $user2, $pass2));
&stmt_ok();

&print_dbinfo($dbh2);
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
