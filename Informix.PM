#	@(#)Informix.PM	25.8 96/12/09 16:17:55
#
#   Portions Copyright (c) 1994,1995 Tim Bunce
#   Portions Copyright (c) 1996      Jonathan Leffler
#
#   $Derived-From: Informix.pm,v 1.18 1995/08/15 05:31:30 timbo Archaic $
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.

{
	package DBD::Informix;

	use DBI;
	use DynaLoader;
	@ISA = qw(DynaLoader);

	my $VERSION             = "<<DBD::Informix Version>>";
	my $PRODUCTNAME         = "<<Product Name>>";
	my $PRODUCTVERSION      = "<<Product Version>>";
	my $MultipleConnections = "<<Multiple Connections>>";
	my $ATTRIBUTION         = 'By Alligator Descartes and Jonathan Leffler';
	my $Revision            = substr(q@(#)Informix.PM 25.8 (96/12/09)@, 3);

	require_version DBI 0.69;

	bootstrap DBD::Informix $VERSION;

	$err = 0;		# holds error code   for DBI::err
	$errstr = "";	# holds error string for DBI::errstr
	$drh = undef;	# holds driver handle once initialised

	# Multiple connections not supported!
	$MultipleConnections = 0;

	sub driver
	{
		#if ($MultipleConnections == 0)
		#{
			# Reuse driver (no multiple connections)!
			return $drh if $drh;
		#}

		my($class, $attr) = @_;

		unless ($ENV{'INFORMIXDIR'})
		{
			foreach(qw(/usr/informix /opt/informix /opt/Informix)){
				if (-d "$_/lib")
				{
					$ENV{'INFORMIXDIR'}=$_;
					last;
				}
			}
			my $msg = ($ENV{INFORMIXDIR}) ? "set to $ENV{INFORMIXDIR}" : "not set!";
			warn "INFORMIXDIR $msg\n";
		}

		$class .= "::dr";
		$Attributes = {
			'Name'                => 'Informix',
			'Version'             => $VERSION,
			'ProductName'         => $PRODUCTNAME,
			'ProductVersion'      => $PRODUCTVERSION,
			'MultipleConnections' => $MultipleConnections,
			'Err'                 => \$DBD::Informix::err,
			'Errstr'              => \$DBD::Informix::errstr,
			'Attribution'         => $ATTRIBUTION,
		};

		#if ($MultipleConnections)
		#{
		#	my $drh = DBI::_new_drh($class, $Attributes);
		#}
		#else
		#{
			# not a 'my' since we use it above to prevent multiple drivers
			$drh = DBI::_new_drh($class, $Attributes);
		#}

		# Initialize driver data
		DBD::Informix::dr::driver_init($drh);

		$drh;
	}

	1;
}

{
	package DBD::Informix::dr; # ====== DRIVER ======
	use strict;

	sub errstr
	{
		DBD::Informix::errstr(@_);
	}

	sub connect
	{
		my($drh, $dbname, $user, $pass)= @_;

		# Create new database connection handle for driver
		my $dbh = DBI::_new_dbh($drh, {
				'Name' => $dbname,
				'User' => $user,
				'Pass' => $pass
			});

		# Initialize database connection
		DBD::Informix::db::_login($dbh, $dbname, $user, $pass)
			or return undef;

		$dbh;
	}

}

{
	package DBD::Informix::db; # ====== DATABASE ======
	use strict;

	sub errstr
	{
		DBD::Informix::errstr(@_);
	}

	sub prepare
	{
		my($dbh, $statement)= @_;

		my $sth = DBI::_new_sth($dbh, {
			'Statement' => $statement,
			});

		DBD::Informix::st::_prepare($sth, $statement)
			or return undef;

		$sth;
	}

	# Override default implementation of do (which is DBD::_::db::do)
	# NB: EXECUTE IMMEDIATE does not allow parameters, so if they are
	# provided, use the default function which handles them correctly.
	sub do
	{
		my($dbh, $statement, $attrib, @params) = @_;

		if ($dbh->{Driver}->{ProductVersion} >= 500 && @params == 0)
		{
			DBD::Informix::db::immediate($dbh, $statement);
		}
		else
		{
			DBD::_::db::do($dbh, $statement, $attrib, @params);
		}
	}


}

{
	package DBD::Informix::st; # ====== STATEMENT ======
	use strict;

	sub errstr
	{
		DBD::Informix::errstr(@_);
	}
}

1;

__END__

=head1 NAME

DBD::Informix - Access to Informix Databases

=head1 SYNOPSIS

  use DBD::Informix;

=head1 DESCRIPTION

This document describes DBD::Informix version 0.25 and later.

It has a biassed view on how to use DBI and DBD::Informix.  Because there
is no better documentation of how to use DBI, this covers both DBI and
DBD::Informix.  The extant documentation on DBI suggests that things should
be done differently, but gives no solid examples of how it should be done
differently or why it should be done differently.

Be aware that on occasion, it gets complex because of differences between
different versions of Informix software.  The key factor is the version of
ESQL/C used when building DBD::Informix.  Basically, there are two groups of
versions to worry about, the 5.0x family of versions (5.00.UC1 through
5.08.UC1 at the moment), and the 6.0x and later family of versions (6.00.UE1
through 7.21.UC1 at the moment).  All version families acquire extra versions
on occasion.

Note that DBD::Informix does not work with 4.1x or earlier versions of ESQL/C
because it uses SQL descriptors and these are not available prior to version
5.00.

=head1 USE OF DBD::Informix

=head2 Loading DBD::Informix

To use the DBD::Informix software, you need to load the DBI software
and then install the Informix driver:

	use DBI;
	$drh = DBI->install_driver('Informix');

This gives you a reference to the driver, aka the driver handle.  If the
load fails, your program stops immediately (unless, perhaps, you eval the
statement).

Once you have the driver handle, you can interrogate the driver for some
basic information:

	print "Driver Information\n";
	# Type is always 'dr'.
	print "    Type:                  $drh->{Type}\n";
	# Name is always 'Informix'.
	print "    Name:                  $drh->{Name}\n";
	# Version is the version of DBD::Informix (eg 0.25).
	print "    Version:               $drh->{Version}\n";
	# The ProductName is the version of ESQL/C; it corresponds to
	# the first line of the output from "esql -V".
	print "    Product:               $drh->{ProductName}\n";
	# The ProductVersion is an integer version number such as 721
	# for ESQL/C version 7.21.UC1.
	print "    Product Version:       $drh->{ProductVersion}\n";
	# The Attribution identifies the culprits who provided you
	# with this software.
	print "    Attribution:           $drh->{Attribution}\n";
	# The MultipleConnections indicates whether the driver
	# supports multiple connections (1) or not (0).
	print "    Multiple Connections:  $drh->{MultipleConnections}\n";

	# -- Not implemented in DBD::Informix 0.25 --
	# ActiveConnections identifies the number of open connections.
	print "    Active Connections:      $drh->{ActiveConnections}\n";
	# CurrentConnection identifies the current connection.
	print "    Current Connections:     $drh->{CurrentConnection}\n";

Once you have the driver loaded, you can connect to a database, or you
can (in theory) sever all connections to databases with disconnect_all,
but this has not been implemented in 0.25b2.

	$drh->disconnect_all;

=over 4

BUG: DBD::Informix does not implement disconnect_all.

= back

There is also an unofficial function which can be called using:

	@dbnames = $drh->func('_ListDBs');

You can test whether this worked with:

	if (defined @dbnames) { ...process array... }
	else                  { ...process error... }

=head2 CONNECTING TO A DATABASE

To connect to a database, you can specify:

	$dbh = $drh->connect($database, $username, $password);

This yields a valid reference or database handle if it is successful.
The username and password data is ignored by the 5.0x versions, and the
statement is equivalent to: EXEC SQL DATABASE :database;

The 6.0x versions only use the username and password if both are supplied,
but it is equivalent to:

    EXEC SQL CONNECT TO :database AS :connection
        USER :username USING :password
        WITH CONCURRENT TRANSACTIONS

The connection is given a name by DBD::Informix.

For Informix, the database name is any valid format for the DATABASE or
CONNECT statements.  Examples include:

	dbase				# 'Local' database
	//machine1/dbase	# Database on remote machine
	dbase@server1		# Database on (remote) server (as defined in sqlhosts)
	@server1			# Connection to (remote) server but no database
	/some/where/dbase	# Connect to local SE database

The database name is not supplied implicitly.  Contrary to some other
documentation, it does not default to the value in %ENV{PERL_DBI_DATABASE}.

Once you have a database handle, you can interrogate it for some basic
information about the database, etc.

	 print "Database Information\n";
	 # Type is always 'db'
	 print "    Type:                    $dbh->{Type}\n";
	 # Name is the name of the database specified at connect
	 print "    Database Name:           $dbh->{Name}\n";
	 # InformixOnLine is 1 (true) if the handle is connected to an
	 # Informix-OnLine server.
	 print "    Informix-OnLine:         $dbh->{InformixOnLine}\n";
	 # LoggedDatabase is 1 (true) if the database has
	 # transactions.
	 print "    Logged Database:         $dbh->{LoggedDatabase}\n";
	 # ModeAnsiDatabase is 1 (true) if the database is MODE ANSI.
	 print "    Mode ANSI Database:      $dbh->{ModeAnsiDatabase}\n";
	 # AutoCommit is 1 (true) if the database commits each
	 # statement.
	 print "    AutoCommit:              $dbh->{AutoCommit}\n";
	 # AutoErrorReport is 1 (true) if errors are reported as they
	 # are detected.
	 print "    AutoErrorReport:         $dbh->{AutoErrorReport}\n";

If $dbh->{AutoErrorReport} is true, then DBD::Informix will report each
error automatically on STDERR when it is detected.  The error is also
available via the package variables $DBI::errstr and $DBI::err.  Note that
$DBI::errstr includes the SQL error number and the ISAM error number if
there is one, and ends with a newline.  The message may or may not extend
over several lines, and is generally formatted so that it will display
neatly within 80 columns.

If $dbh->{AutoErrorReport} is false, then DBD::Informix does not report any
errors when it detects them; it is up to the user to note that errors have
occurred and to report them.

If you have forgotten the driver, you can discover it again using:

	$drh = $dbh->{Driver};

=over 4

BUG: the name of the database should be tracked more carefully via
the DATABASE, CLOSE DATABASE, CREATE DATABASE and START DATABASE statements.
Note that you cannot prepare CONNECT statements, so they do not have to be
tracked.  This is not fixed in 0.25.

BUG: AutoCommit is not handled correctly in 0.25.

= back

=head2 DISCONNECTING FROM A DATABASE

You can also disconnect from the database:

	$dbh->disconnect;

This will rollback any uncommitted work.

=over 4

BUG: no rollback occurs in 0.25.

= back

Note that this does not destroy the database handle.  You need to do an
explicit 'undef $dbh' to destroy the handle.

If you are using an Informix driver for which $drh->{ProductVersion} >= 600,
then you can have multiple concurrent connections.  This means that multiple
calls to $drh->connect will give you independent connections to one or more
databases.

If you are using an Informix driver for which $drh->{ProductVersion} < 600,
then you cannot have multiple concurrent connections.  If you make multiple
calls to $drh->connect, you will achieve the same effect as executing several
database statements in a row.  This will generally switch databases
successfully, but will invalidate any statements previously prepared.  It may
fail if the current database is not local, or if there is an active
transaction, etc.

=over 4

BUG: Multiple connections do not work in 0.25.

BUG: You get memory leaks in version 0.25 if you do:

	$dbh = $drh->connect('database1'):
	$dbh = $drh->connect('database2'):

= back

=head2 SIMPLE STATEMENTS

Given a database connection, you can execute a variety of simple statements
using a variety of different calls:

	$dbh->commit;
	$dbh->rollback;

These two operations commit or rollback the current transaction. If the
database is unlogged, they do nothing.  If the database is not MODE ANSI
and AutoCommit is set to 0 then a new transaction is automatically
started.  If the database is not MODE ANSI and AutoCommit is set to 1 (the
default), then no explicit transaction is started.

You can execute an arbitrary parameterless statement using:

	$dbh->do($stmt);

The statement must not be either SELECT (other than SELECT...INTO TEMP) or
EXECUTE PROCEDURE where the procedure returns data.  This will use the
ESQL/C EXECUTE IMMEDIATE statement.

You can execute an arbitrary statement with parameters using:

	$dbh->do($stmt, @parameters);
	$dbh->do($stmt, $param1, $param2);

Again, the statement must not be a SELECT or EXECUTE PROCEDURE which
returns data.  The values in @parameters (or the separate values) are bound
to the question marks in the statement string.  However, this cannot use
EXECUTE IMMEDIATE because it does not accept parameters.

	$sth = $dbh->prepare($stmt);
	$sth->execute(@parameters);

In DBD::Informix v0.25, this part of the functionality of $dbh->do() is
provided by the DBI package implementation.  This is likely to be handled
exclusively by DBD::Informix in the next release.

=over 4

BUG: the code in DBI uses $dbh->rows to work out whether everything worked
or not, and this is not implemented in DBD::Informix.  DBD::Informix should
implement $dbh->do for both forms of call.

BUG: If the statement you run is a SELECT, then it is prepared, and the
cursor is declared, opened (potentially expensive, if the statement uses
ORDER BY etc), and then closed and freed without fetching any data.  A more
robust version would generate an error condition.

= back

You can embed an arbitrary string inside a statement with any quote marks
correctly handled by invoking:

	$dbh->quote($string);

This method is provided by the DBI package implementation and is inherited
by the DBD::Informix package.  The string is enclosed in singel quotes, and
any embedded single quotes are doubled up, which conforms to the SQL-92
standard.

=head2 CREATING STATEMENTS

You can also prepare a statement for multiple uses, and you can do this for
SELECT and EXECUTE PROCEDURE statements which return data (cursory
statements) as well as non-cursory statements which return no data.  You
create a statement handle (another reference) using:

	$sth = $dbh->prepare($stmt);

If the statement is a SELECT which returns data (not SELECT...INTO TEMP) or
an EXECUTE PROCEDURE for a procedure which returns values, then a cursor is
declared for the prepared statement.

Note: in versions of DBD::Informix prior to 0.25, preparing a statement
also executed non-cursory statements and opened the cursor for cursory
statements.

More typically, you need to do error checking, and this is achieved by
using:

	die "Failed to prepare '$stmt'\n"
		unless ($sth = $dbh->prepare($stmt));

=over 4

BUG: There is no way to tell whether the statement is just executable or
whether it is a cursory (fetchable) statement.  You are assumed to know.

= back

Once the statement is prepared, you can execute it:

	$sth->execute;

For a non-cursory statement, this simply executes the statement.  For a
cursory statement, it opens the cursor.  You can also specify the
parameters for a statement using:

	$sth->execute(@parameters);

The first parameter will be supplied as the value for the first
place-holder question mark in the statement, the second parameter for the
second place-holder, etc.

=over 4

Issue: At the moment, there is no checking by DBD::Informix on how many
parameters are supplied and how many are needed.
This needs to be resolved.
Also, the Informix engines give no support for determining the types of
those parameters except in the VALUES clause of an INSERT statement.
This means that DBD::Informix v0.25 cannot handle blobs in the SET clause
of an UPDATE statement.

BUG: The various bind routines defined by DBI (primarily to support
DBD::Oracle) are not implemented in DBD::Informix because there are no
clearly documented semantics associated with the calls.

= back

For cursory statements, you can discover what the returned column names, types,
nullability, etc are.  You do this with:

	@name = @{$sth->{NAME}};		# Column names
	@null = @{$sth->{NULLABLE}};	# True => accepts nulls
	@type = @{$sth->{TYPE}};		# Data types with qualifiers
	@prec = @{$sth->{PRECISION}};	# Numeric length from SysColumns.Collength
	@scal = @{$sth->{SCALE}};		# Same as PRECISION

=over 4

BUG: PRECISION is not clearly defined, and neither is SCALE.  It isn't
clear which types should have a these attributes.  There should, probably,
be $sth->{ColLength} to do what $sth->{PRECISION} and $sth->{SCALE} do, and
the precision and scale should be defined for FLOAT, SMALLFLOAT, DECIMAL,
MONEY types and their synonyms.  It is not clear whether the various types
of integer values should be given precision and scale values, though it is
relatively easy to define valid values for them.  It is not clear how
floating point numbers are represented in SCALE.  It is not clear whether
the various CHAR types should be given a PRECISION corresponding to their
length.  Etc... This is one point where the DBI specification is badly in need
of definition.

BUG: You might be able to do the same with INSERT statements, except that
some internal machinations mean that it probably does not work in 0.25.

= back

If the statement is a cursory statement, you can retrieve the values in either
of two ways:

	$ref = $sth->fetch;
	@row = @{$ref};

	@row = @{$sth->fetch};	# Shorthand for above...

	@row = $sth->fetchrow;

As usual, you have to worry about whether this worked or not.  You would
normally, therefore, use:

	while ($ref = $sth->fetch)
	{
		# We know we got some data here
		...
	}
	# Investigate whether an error occurred or the SELECT had nothing more to
	# return.
	if ($sth->{sqlcode} < 0)
	{
		# Process error...
	}

The returned data includes blobs mapped into strings.  Note that byte blobs
might contain ASCII NUL '\0' characters.  Perl knows how long the strings
are and does preserve NUL in the middle of a byte blob.  However, you may
need to be careful deciding how to handle this string.

There is provision to specify how you want blobs handled.  You can set the
attribute:

	$sth->{BlobLocation} = 'InMemory';		# Default
	$sth->{BlobLocation} = 'InFile';		# In a named file
	$sth->{BlobLocation} = 'DummyValue';	# Return dummy values
	$sth->{BlobLocation} = 'NullValue';		# Return undefined

The InFile mode returns the name of a file in the fetched array, and that
file can be accessed by Perl using normal file access methods.  The
DummyValue mode returns "<<TEXT VALUE>>" for text blobs or "<<BYTE VALUE>>"
for byte (binary) blobs.  The NullValue mode returns undefined (meaning
that Perl's "defined" operator would return false) values.  Note that these
two options do not necessarily prevent the Server from returning the data
to the application, but the user does not get to see the data -- this
depends on the internal implementation of the ESQL/C FETCH operation in
conjunction with SQL descriptors.

You can also set the BlobLocation attribute on the database, overriding it
at the statement level.

=over 4

BUG: In version 0.25, BlobLocation is not honoured.  When questioning
BlobLocation, you get a numeric answer rather than a string answer, and the
numeric answer is not acceptable as input.  Both items need to be fixed.

= back

When you have fetched as many rows as required, you close the cursor using:

	$sth->finish;

This simply closes the cursor; it does not free the cursor or the statement.
That is done when you destroy (undef) the statement handle:

	undef $sth;

You can also implicitly rebind a statement handle to a new statement by
simply using the same variable again.  This does not cause any memory leaks.

=head1 KNOWN RESTRICTIONS

=over 2

=item *
Multiple connections are not supported.

=item *
AutoCommit is not properly supported.

=item *
Blobs can only be located in memory (reliably).

=item *
DisconnectAll is not properly supported.

=item *
Some driver attributes (notably CurrentConnection and 
ActiveConnections) cannot be queried.

=back

=head1 AUTHOR

At various times:

=over 2

=item *
Tim Bunce (Tim.Bunce@ig.co.uk)

=item *
Alligator Descartes (descartes@hermetica.com)

=item *
Jonathan Leffler (johnl@informix.com)

=back

=head1 SEE ALSO

perl(1).

=cut
