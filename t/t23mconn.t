#!/usr/bin/perl -w
#
#	@(#)$Id: t/t23mconn.t version /main/24 2000-02-24 15:50:52 $ 
#
#	Test abuse of statements after DISCONNECT ALL for DBD::Informix
#
#	Portions Copyright 1996-99 Jonathan Leffler
#	Portions Copyright 2000    Informix Software Inc
#	Portions Copyright 2002    IBM

use DBD::Informix::TestHarness;

my ($dbase1, $user1, $pass1) = &primary_connection();
my ($dbase2, $user2, $pass2) = &secondary_connection();

if (&is_shared_memory_connection($dbase1) &&
	&is_shared_memory_connection($dbase2))
{
	&stmt_note("1..0\n");
	&stmt_note("# Two shared memory connections - test skipped\n");
	exit(0);
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
	&stmt_note("1..0\n");
	&stmt_note("# Multiple connections are not supported\n");
	&all_ok();
}

&stmt_note("1..12\n");
&stmt_ok();

&print_dbinfo($dbh1);

print "# Connection Information\n";
print "#     Active Connections:      $dbh1->{ix_ActiveConnections}\n";
print "#     Current Connection:      $dbh1->{ix_CurrentConnection}\n";
print "#\n";

&stmt_fail() unless $dbh1->{ix_ActiveConnections} == 1;
&stmt_fail() unless $dbh1->{ix_CurrentConnection} eq $dbh1->{ix_CurrentConnection};

&stmt_note("# Connect to: $dbase2\n");
&stmt_fail() unless ($dbh2 = DBI->connect("DBI:Informix:$dbase2", $user2, $pass2));
&stmt_ok();

&print_dbinfo($dbh2);

print "# Connection Information\n";
print "#     Active Connections:      $dbh1->{ix_ActiveConnections}\n";
print "#     Current Connection:      $dbh1->{ix_CurrentConnection}\n";
print "#\n";
&stmt_fail() unless $dbh1->{ix_ActiveConnections} == 2;
&stmt_fail() unless $dbh1->{ix_CurrentConnection} eq $dbh1->{ix_CurrentConnection};

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
	last LOOP unless (@row1 = $st1->fetchrow_array);
	last LOOP unless ($row2 = $st2->fetchrow_arrayref);
	print "# 1: $row1[0]\n";
	print "# 2: ${$row2}[0]\n";
	print "# 2: ${$row2}[1]\n";
}
&stmt_ok();

&stmt_note("# Test DISCONNECT ALL.\n");
&stmt_fail() unless ($dbh1->{Driver}->disconnect_all);
&stmt_ok();

print "# Connection Information\n";
print "#     Active Connections:      $dbh1->{ix_ActiveConnections}\n";
print "#     Current Connection:      $dbh1->{ix_CurrentConnection}\n";

# Turn off automatic error reporting...
$st1->{PrintError} = 0;
$st2->{PrintError} = 0;

# Resume as if nothing had happened (see t21mconn.t)
while (@row1 = $st1->fetchrow_array)
{
	# Should not be able to fetch successfully!
	&stmt_fail("Fetch succeeded but should have failed\n");
}
&stmt_fail("SQLCODE non-negative (unexpectedly)\n") unless ($st1->{ix_sqlcode} < 0);
&stmt_ok();

while ($row2 = $st2->fetchrow_arrayref)
{
	# Should not be able to fetch successfully!
	&stmt_fail("Fetch succeeded but should have failed\n");
}
&stmt_fail("SQLCODE non-negative (unexpectedly)\n") unless ($st2->{ix_sqlcode} < 0);
&stmt_ok();

undef $st2;
undef $st1;

# These should disconnect smoothly
&stmt_note("# Testing: \$dbh1->disconnect()\n");
&stmt_fail() unless ($dbh1->disconnect);
&stmt_ok();

undef $dbh1;

&stmt_note("# Testing: \$dbh2->disconnect()\n");
&stmt_fail() unless ($dbh2->disconnect);
&stmt_ok();

undef $dbh2;

&all_ok();
