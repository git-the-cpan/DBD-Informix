#	@(#)$Id: InformixTest.pl,v 95.1 1999/12/04 23:53:22 jleffler Exp $ 
#
# Pure Perl Test facilities to help the user/tester of DBD::Informix
#
#   Copyright (c) 1996-98 Jonathan Leffler
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.

# Exploit this by saying:
# require "perlsubs/InformixTest.pl";

use DBI;
require_version DBI 1.02;

# Report on the connect command and any attributes being set.
sub print_connection
{
	my ($str, $attr) = @_;
	&stmt_note("# DBI->connect($str);\n");
	if (defined $attr)
	{
		my ($key);
		foreach $key (keys %$attr)
		{
			&stmt_note("#\tConnect Attribute: $key => $$attr{$key}\n");
		}
	}
}

sub connect_to_test_database
{
	my ($attr) = @_;
	# This section may need rigging for some versions of Informix.
	# It will should be OK for 6.0x and later versions of OnLine.
	# You may run into problems with SE and 5.00 systems.
	# If you do, send details to the maintenance team.
	my ($dbname, $dbuser, $dbpass) =
		($ENV{DBD_INFORMIX_DATABASE},
		 $ENV{DBD_INFORMIX_USERNAME}, $ENV{DBD_INFORMIX_PASSWORD});

	# Do not print out actual password!
	$dbpass = "" unless ($dbpass);
	$dbuser = "" unless ($dbuser);
	my ($xxpass) = 'X' x length($dbpass); 

	$dbname = "stores" if (!$dbname);

	my ($part2) = "'$dbuser', '$xxpass'";
	my ($dbh) = "";
	&print_connection("'dbi:Informix:$dbname', $part2", $attr);
	$dbh = DBI->connect("dbi:Informix:$dbname", $dbuser, $dbpass, $attr);

	&stmt_fail() unless (defined $dbh);
	# Unconditionally chop trailing blanks.
	# Override in test cases as necessary.
	$dbh->{ChopBlanks} = 1;
	$dbh;
}

sub print_dbinfo
{
	my ($dbh) = @_;
	print  "# Database Information\n";
	print  "#     Database Name:           $dbh->{Name}\n";
	printf "#     AutoCommit:              %d\n", $dbh->{AutoCommit};
	printf "#     PrintError:              %d\n", $dbh->{PrintError};
	printf "#     RaiseError:              %d\n", $dbh->{RaiseError};
	printf "#     Informix-OnLine:         %d\n", $dbh->{ix_InformixOnLine};
	printf "#     Logged Database:         %d\n", $dbh->{ix_LoggedDatabase};
	printf "#     Mode ANSI Database:      %d\n", $dbh->{ix_ModeAnsiDatabase};
	printf "#     Transaction Active:      %d\n", $dbh->{ix_InTransaction};
	print  "#\n";
}

sub print_sqlca
{
	my ($sth) = @_;
	print "# Testing SQLCA handling\n";
	print "#     SQLCA.SQLCODE    = $sth->{ix_sqlcode}\n";
	print "#     SQLCA.SQLERRM    = '$sth->{ix_sqlerrm}'\n";
	print "#     SQLCA.SQLERRP    = '$sth->{ix_sqlerrp}'\n";
	my ($i) = 0;
	my @errd = @{$sth->{ix_sqlerrd}};
	for ($i = 0; $i < @errd; $i++)
	{
		print "#     SQLCA.SQLERRD[$i] = $errd[$i]\n";
	}
	my @warn = @{$sth->{ix_sqlwarn}};
	for ($i = 0; $i < @warn; $i++)
	{
		print "#     SQLCA.SQLWARN[$i] = '$warn[$i]'\n";
	}
	print "# SQLSTATE             = '$DBI::state'\n";
	my ($rows) = $sth->rows();
	print "# ROWS                 = $rows\n";
}

my $ok_counter = 0;
sub stmt_err
{
	# NB: error messages $DBI::errstr no longer end with a newline.
	my ($str) = @_;
	my ($err, $state);
	$str = "Error Message" unless ($str);
	$err = (defined $DBI::errstr) ? $DBI::errstr : "<<no error string>>";
	$state = (defined $DBI::state) ? $DBI::state : "<<no state string>>";
	$str .= ":\n${err}\nSQLSTATE = ${state}\n";
	$str =~ s/^/# /gm;
	&stmt_note($str);
}

sub stmt_ok
{
	my ($warn) = @_;
	$ok_counter++;
	&stmt_note("ok $ok_counter\n");
	&stmt_err("Warning Message") if ($warn);
}

sub stmt_fail
{
	my ($warn) = @_;
	&stmt_note($warn) if ($warn);
	$ok_counter++;
	&stmt_note("not ok $ok_counter\n");
	&stmt_err("Error Message");
	die "!! Terminating Test !!\n";
}

sub all_ok
{
	&stmt_note("# *** Testing of DBD::Informix complete ***\n");
	&stmt_note("# ***     You appear to be normal!      ***\n");
	exit(0);
}

sub stmt_note
{
	print STDOUT @_;
}

sub stmt_test
{
	my ($dbh, $stmt, $ok, $test) = @_;
	$test = "Test" unless $test;
	&stmt_note("# $test: do('$stmt'):\n");
	if ($dbh->do($stmt)) { &stmt_ok(0); }
	elsif ($ok)          { &stmt_ok(1); }
	else                 { &stmt_fail(); }
}

sub stmt_retest
{
	my ($dbh, $stmt, $ok) = @_;
	&stmt_test($dbh, $stmt, $ok, "Retest");
}

sub select_some_data
{
	my ($dbh, $num, $stmt) = @_;
	my ($count, $st2) = (0);
	my (@row);

	&stmt_note("# $stmt\n");
	# Check that there is some data
	&stmt_fail() unless ($st2 = $dbh->prepare($stmt));
	&stmt_fail() unless ($st2->execute);
	while  (@row = $st2->fetchrow)
	{
		my($pad, $i) = ("# ", 0);
		for ($i = 0; $i < @row; $i++)
		{
			&stmt_note("$pad$row[$i]");
			$pad = " :: ";
		}
		&stmt_note("\n");
		$count++;
	}
	&stmt_fail() unless ($count == $num);
	&stmt_fail() unless ($st2->finish);
	undef $st2;
	&stmt_ok();
}

# Check that there is no data
sub select_zero_data
{
	&select_some_data($_[0], 0, $_[1]);
}

# Check that both the ESQL/C and the database server are IUS-aware
# Return database handle if all is OK.
sub test_for_ius
{
	my $dbase1 = $ENV{DBD_INFORMIX_DATABASE};
	my $user1 = $ENV{DBD_INFORMIX_USERNAME};
	my $pass1 = $ENV{DBD_INFORMIX_PASSWORD};

	$dbase1 = "stores" unless ($dbase1);
	$user1 = "" if (! defined $user1);
	$pass1 = "" if (! defined $pass1);

	my $drh = DBI->install_driver('Informix');
	print "# Driver Information\n";
	print "#     Name:                  $drh->{Name}\n";
	print "#     Version:               $drh->{Version}\n";
	print "#     Product:               $drh->{ix_ProductName}\n";
	print "#     Product Version:       $drh->{ix_ProductVersion}\n";
	if ($drh->{ix_ProductVersion} < 900)
	{
		&stmt_note("1..0\n");
		&stmt_note("# IUS data types are not supported by $drh->{ix_ProductName}\n");
		exit(0);
	}

	my ($dbh, $sth, $numtabs);
	&stmt_note("# Connect to: $dbase1\n");
	&stmt_fail() unless ($dbh = DBI->connect("DBI:Informix:$dbase1", $user1, $pass1));
	&stmt_fail() unless ($sth = $dbh->prepare(q%
		SELECT COUNT(*) FROM "informix".SysTables WHERE TabID < 100
		%));
	&stmt_fail() unless ($sth->execute);
	&stmt_fail() unless (($numtabs) = $sth->fetchrow_array);
	if ($numtabs < 40)
	{
		&stmt_note("1..0\n");
		&stmt_note("# IUS data types are not supported by database server.\n");
		$dbh->disconnect;
		exit(0);
	}
	&stmt_note("# IUS data types can be tested!\n");
	return $dbh;
}

# Remove test debris created by DBD::Informix tests
sub cleanup_database
{
	my ($dbh) = @_;
	my ($old_p) = $dbh->{PrintError};
	my ($old_r) = $dbh->{RaiseError};
	my ($type);

	# Do not report any errors.
	$dbh->{PrintError} = 0;
	$dbh->{RaiseError} = 0;

	# Clean up from any previous runs.
	foreach $type ('view', 'synonym', 'base')
	{
		my $kw = $type;
		$kw =~ s/base/table/;
		my @names = grep /\.dbd_ix_/i, $dbh->func($type, '_tables');
		foreach (@names)
		{
			&stmt_note("# drop $kw $_\n");
			$dbh->do(qq% drop $kw $_ %);
		}
	}

	# IUS test debris!
	$dbh->do(q% DROP TABLE dbd_ix_maker %);
	$dbh->do(q% DROP TABLE dbd_ix_location %);
	$dbh->do(q% DROP ROW TYPE dbd_ix_location RESTRICT %);
	$dbh->do(q% DROP TYPE dbd_ix_percent RESTRICT %);

	# Reinstate original error handling
	$dbh->{PrintError} = $old_p;
	$dbh->{RaiseError} = $old_r;
	1;
}

1;

__END__

=head1 NAME

Test Harness for DBD::Informix

=head1 SYNOPSIS

  require "perlsubs/InformixTest.pl";

=head1 DESCRIPTION

This document describes the InformixTest.pl collection of subroutines
for testing DBD::Informix version 0.62 and later.  This is pure Perl
code which exploits DBI and DBD::Informix to make it easier to write
tests.  Most notably, it provides a simple mechanism to connect to the
user's chosen test database and a uniform set of reporting mechanisms.

=head2 Loading the InformixTest Subroutines

To use the InformixTest software, you need to load the DBI software
and then install the Informix driver:

    require "perlsubs/InformixTest.pl";

=head2 Connecting to test database

    $dbh = &connect_to_test_database({ AutoCommit => 0 });

This gives you a reference to the database connection handle, aka the
database handle.
If the load fails, your program stops immediately.
The functionality available from this handle is documented in the
DBD::Informix manual page.
This function does not report success when it succeeds because the
test scripts for blobs, for example, need to know whether they are
working with an OnLine system before reporting how many tests will be
run.

This code exploits 3 environment variables:

    DBD_INFORMIX_DATABASE
    DBD_INFORMIX_USERNAME
    DBD_INFORMIX_PASSWORD

The database variable can be simply the name of the database, or it
can be 'database@server', or it can be one of the SE notations such
as '/opt/dbase' or '//hostname/dbase'.
If INFORMIXSERVER is not set, then you had better be on a 5.0x
system as otherwise the connection will fail.
With 6.00 and above, you can optionally specify a user name and
password in the environment.
This is horribly insecure -- do not use it for production work.
The test scripts do not print the password.

=head2 Using cleanup_database

If the test needs a clean database to work with, the cleanup_database
method removes any tables, views, synonyms (or IUS types) created by the
DBD::Informix test suite.
These are all identified by the 'dbd_ix_' prefix.

	&cleanup_database($dbh);

This is not used in all tests by any stretch of the imagination.
Whereever possible, tests should use temporary tables.

=head2 Using test_for_ius

If the test explicitly requires Informix Universal Server (IUS)
or IDS/UDO (Informix Dynamic Server with Universal Data Option --
essentially the product as IUS, but with a longer, more recent,
name), then the mechanism to use is:

	my ($dbh) = &test_for_ius();

If this returns, then the ESQL/C is capable of handling IUS data
types, the database connection worked, and the database server is
capable of handling IUS data types.

=head2 Using stmt_test

Once you have a database connection, you can execute simple statements (those
which do not return any data) using &stmt_test():

    &stmt_test($dbh, $stmt, $flag, $tag);

The first argument is the database handle.  The second is a string
containing the statement to be executed.  The third is optional and is a
boolean.  If it is 0, then the statement must execute without causing an
error or the test will terminate.  If it is set to 1, then the statement
may fail and the error will be reported but the test will continue.  The
fourth argument is an optional string which will be used as a tag before
the statement when it is printed.  If omitted, it defaults to "Test".

=head2 Using stmt_retest

The &stmt_retest() function takes three arguments, which have the same meaning
as the first three arguments of &stmt_test():

    &stmt_retest($dbh, $stmt, $flag);

It calls:

    &stmt_test($dbh, $stmt, 0, "Retest");

=head2 Using print_sqlca

The &print_sqlca() function takes a single argument which can be either a
statement handle or a database handle and prints out the current values of
the SQLCA record.

    &print_sqlca($dbh);
    &print_sqlca($sth);

=head2 Using print_dbinfo

The &print_dbinfo() function takes a single argument which should be a database
handle and prints out salient information about the database.

    &print_dbinfo($dbh);

=head2 Using all_ok

The &all_ok() function can be used at the end of a test script to report
that everything was OK.  It exits with status 0.

    &all_ok();

=head2 Using stmt_ok

This routine adds 'ok N' to the end of a line.  The N increments
automatically each time &stmt_ok() or &stmt_fail() is called.  If called
with a non-false argument, it prints the contents of DBI::errstr as a
warning message too.  This routine is used internally by stmt_test() but is
also available for your use.

    &stmt_ok(0);

=head2 Using stmt_fail

This routine adds 'not ok N' to the end of a line, then reports the
error message in DBI::errstr, and then dies.  The N is incremented
automatically, as with &stmt_ok().  This routine is used internally by
stmt_test() but is also available for your use.  It takes an optional
string as an argument, which is printed as well.

    &stmt_fail();
    &stmt_fail("Reason why test failed");

=head2 Using stmt_err

This routines prints a caption (defaulting to 'Error Message') and the
contents of DBI::errstr, ensuring that each line is prefixed by "# ".
This routine is used internally by the InformixTest module, but is
also available for your use.

	&stmt_err('Warning Message');

=head2 Using stmt_note

This routine writes a string (without any newline unless you include it).
This routine is used internally by stmt_test() but is also available for
your use.

    &stmt_note("Some string or other");

=head2 Using select_some_data

This routine takes three arguments:

    &select_some_data($dbh, $nrows, $stmt);

The first argument is the database handle.  The second is the number of
rows that should be returned.  The third is a string containing the SELECT
statement to be executed.  It prints all the data returned with a '#'
preceding the first field and two colons separating the fields.  It reports
OK if the select succeeds and the correct number of rows are returned; it
fails otherwise.

=head2 Using select_zero_data

This routine takes a database handle and a SELECT statement and invokes
&select_some_data with 0 rows expected.

    &select_zero_data($dbh, $stmt);

=head2 Note

All these routines can also be used without parentheses or the &, so that
the following is also valid:

    select_zero_data $dbh, $stmt;

=head1 AUTHOR

At various times:

=over 2

=item *
Jonathan Leffler (johnl@informix.com)

=item *
Jonathan Leffler (j.leffler@acm.org)

=back

=head1 SEE ALSO

perl(1), DBD::Informix

=cut
