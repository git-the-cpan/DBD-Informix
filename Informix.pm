#	@(#)Informix.pm	55.1 97/05/19 13:28:29
#
#   Portions Copyright (c) 1994,1995 Tim Bunce
#   Portions Copyright (c) 1996,1997 Jonathan Leffler
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

	$VERSION     = "0.55";
	$ATTRIBUTION = 'By Jonathan Leffler';
	$Revision    = substr(q@(#)Informix.pm 55.1 (97/05/19)@, 3);

	require_version DBI 0.81;	# Requires ChopBlanks, introduced in 0.81

	bootstrap DBD::Informix $VERSION;

	$err = 0;		# holds error code   for DBI::err
	$errstr = "";	# holds error string for DBI::errstr
	$state = "";    # holds error string for DBI::state

	my $drh = undef;	# holds driver handle once initialized

	sub driver
	{
		if (defined $drh && !defined $drh->{ix_MultipleConnections})
		{
			# Reuse driver (no multiple connections)!
			return $drh;
		}

		my($class, $attr) = @_;

		unless ($ENV{INFORMIXDIR})
		{
			foreach(qw(/usr/informix))
			{
				if (-d "$_/lib")
				{
					$ENV{INFORMIXDIR} = $_;
					warn "INFORMIXDIR set to $_\n";
					last;
				}
			}
			warn "INFORMIXDIR not set!\n" unless $ENV{INFORMIXDIR};
		}

		$class .= "::dr";

		# Create new driver handle.
		# The ix_ProductName, ix_ProductVersion, ix_MultipleConnections
		# ix_CurrentConnection and ix_ActiveConnections attributes are
		# handled by the driver's FETCH_attrib function.
		$drh = DBI::_new_drh($class, {
			'Name'                   => 'Informix',
			'Version'                => $VERSION,
			'Err'                    => \$DBD::Informix::err,
			'Errstr'                 => \$DBD::Informix::errstr,
			'State'                  => \$DBD::Informix::state,
			'Attribution'            => $ATTRIBUTION,
			%{$attr}
		});

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
		my ($drh, $dbname, $dbuser, $dbpass) = @_;

		$dbname = "" unless(defined $dbname);
		$dbuser = "" unless(defined $dbuser);
		$dbpass = "" unless(defined $dbpass);

		# Create new database connection handle for driver
		my $dbh = DBI::_new_dbh($drh, {
				'Name' => $dbname,
				'User' => $dbuser,
				'Pass' => $dbpass
			});

		# Initialize database connection
		DBD::Informix::db::connect($dbh, $dbname, $dbuser, $dbpass)
			or return undef;

		$dbh;
	}
	1;
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

		DBD::Informix::st::prepare($sth, $statement)
			or return undef;

		$sth;
	}

	# Override default implementation of do (which is DBD::_::db::do)
	# EXECUTE IMMEDIATE was introduced in version 5.00 ESQL/C.
	# NB: EXECUTE IMMEDIATE does not allow parameters, so if they are
	# provided, use the prepare, execute and finish functions which
	# handle them correctly.  Note that the attributes are ignored
	# unless the statement has parameters (and are actually ignored
	# even then, but they are ignored at a lower level).
	sub do
	{
		my($dbh, $statement, $attrib, @params) = @_;
		my($pv) = DBD::Informix::dr::FETCH($dbh->{Driver},'ix_ProductVersion');

		if ($pv >= 500 && @params == 0)
		{
			DBD::Informix::db::immediate($dbh, $statement);
		}
		else
		{
			my ($sth) = DBD::Informix::st::prepare($dbh, $statement, $attrib);
			$sth->execute(@params) if ($sth);
			$sth->finish() if ($sth);
		}
	}
	1;
}

{
	package DBD::Informix::st; # ====== STATEMENT ======
	use strict;

	sub errstr
	{
		DBD::Informix::errstr(@_);
	}
	1;
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

To use the DBD::Informix software, you need to load the DBI software.

    use DBI;

Under normal circumstances, you should then connect to your database
using the notation in the section "CONNECTING TO A DATABASE" which
calls DBI->connect().
Note that the DBD::Informix test code does not operate under normal
circumstances, and therefore uses the non-preferred techniques in the
section "Driver Attributes and Methods".

=head2 Driver Attributes and Methods

If you have a burning desire to do so, you can explicitly install the
Informix driver independently of connecting to any database using:

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
    # Version is the version of DBD::Informix (eg 0.51).
    print "    Version:               $drh->{Version}\n";
    # The Attribution identifies the culprits who provided you
    # with this software.
    print "    Attribution:           $drh->{Attribution}\n";
    # The ProductName is the version of ESQL/C; it corresponds to
    # the first line of the output from "esql -V".
    print "    Product:               $drh->{ix_ProductName}\n";
    # The ProductVersion is an integer version number such as 721
    # for ESQL/C version 7.21.UC1.
    print "    Product Version:       $drh->{ix_ProductVersion}\n";
    # The MultipleConnections indicates whether the driver
    # supports multiple connections (1) or not (0).
    print "    Multiple Connections:  $drh->{ix_MultipleConnections}\n";

    # -- Not implemented in DBD::Informix yet --
    # ActiveConnections identifies the number of open connections.
    print "    Active Connections:      $drh->{ix_ActiveConnections}\n";
    # CurrentConnection identifies the current connection.
    print "    Current Connections:     $drh->{ix_CurrentConnection}\n";

Once you have the driver loaded, you can connect to a database, or you
can sever all connections to databases with disconnect_all.

    $drh->disconnect_all;

There is also an unofficial function which can be called using:

    @dbnames = $drh->func('_ListDBs');

You can test whether this worked with:

    if (defined @dbnames) { ...process array... }
    else                  { ...process error... }

=over 4

Item: since ODBC recognizes DataSources, and Informix databases listed
by _ListDBs correspond rather closely to data sources, there is an
argument which says that DBI should have a method

	@sources = $drh->DataSources();

=back

=head1 CONNECTING TO A DATABASE

To connect to a database, you can use the connect function, which
yields a valid reference or database handle if it is successful.
If the driver itself cannot be loaded (by the DBI->install_driver()
method mentioned above), DBI aborts the script (and DBD::Informix can
do nothing about it because it wasn't loaded successfully).

    $dbh = DBI->connect($database, $username, $password, 'Informix');

Note that if you omit the fourth argument ('Informix'), then DBI will
load the driver specified by $ENV{DBI_DRIVER}.
If you omit the fourth argument, you can also omit the $password and
$username arguments if desired.
If you specify the fourth argument, you can leave the $password and
$username arguments empty and they will be ignored.

    $dbh = DBI->connect($database, $username, $password);
    $dbh = DBI->connect($database, $username);
    $dbh = DBI->connect($database);

The 5.0x versions ignore the username and password data, and the
statement is equivalent to "EXEC SQL DATABASE :database;".
The 6.0x versions only use the username and password if both are
supplied, but it is then equivalent to:

    EXEC SQL CONNECT TO :database AS :connection
        USER :username USING :password
        WITH CONCURRENT TRANSACTIONS

The connection is given a name by DBD::Informix.

For Informix, the database name is any valid format for the DATABASE or
CONNECT statements.  Examples include:

    dbase               # 'Local' database
    //machine1/dbase    # Database on remote machine
    dbase@server1       # Database on (remote) server (as defined in sqlhosts)
    @server1            # Connection to (remote) server but no database
    /some/where/dbase   # Connect to local SE database

The database name is not supplied implicitly by DBD::Informix, but the
DBI driver will supply the value in $ENV{DBI_DBNAME} if the
environment variable is set and no database name is supplied in the
connect call.
If DBD::Informix sees an empty string, then it makes no connection to
any database with ESQL/C 5.0x, and it makes a default connection with
ESQL/C 6.00 and later.
There is an additional string, ".DEFAULT.", which can be specified
explicitly as the database name and which will be interpreted as a
request for a default connection.
Note that this is not a valid Informix database name, so there can be
no confusion.

Once you have a database handle, you can interrogate it for some basic
information about the database, etc.

     print "Database Information\n";
     # Type is always 'db'
     print "    Type:                    $dbh->{Type}\n";
     # Name is the name of the database specified at connect
     print "    Database Name:           $dbh->{Name}\n";
     # AutoCommit is 1 (true) if the database commits each statement.
     print "    AutoCommit:              $dbh->{AutoCommit}\n";

     # ix_InformixOnLine is 1 (true) if the handle is connected to an
     # Informix-OnLine server.
     print "    Informix-OnLine:         $dbh->{ix_InformixOnLine}\n";
     # ix_LoggedDatabase is 1 (true) if the database has
     # transactions.
     print "    Logged Database:         $dbh->{ix_LoggedDatabase}\n";
     # ix_ModeAnsiDatabase is 1 (true) if the database is MODE ANSI.
     print "    Mode ANSI Database:      $dbh->{ix_ModeAnsiDatabase}\n";
     # ix_AutoErrorReport is 1 (true) if errors are reported as they
     # are detected.
     print "    AutoErrorReport:         $dbh->{ix_AutoErrorReport}\n";
     # ix_InTransaction is 1 (true) if the database is in a transaction
     print "    Transaction Active:      $dbh->{ix_InTransaction}\n";
     # ix_ConnectionName is the name of the ESQL/C connection.
     # Mainly applicable with Informix-ESQL/C 6.00 and later.
     print "    Connection Name:         $dbh->{ix_ConnectionName}\n";

If $dbh->{ix_AutoErrorReport} is true, then DBD::Informix will report each
error automatically on STDERR when it is detected.  The error is also
available via the package variables $DBI::errstr and $DBI::err.  Note that
$DBI::errstr includes the SQL error number and the ISAM error number if
there is one, and ends with a newline.  The message may or may not extend
over several lines, and is generally formatted so that it will display
neatly within 80 columns.

If $dbh->{ix_AutoErrorReport} is false, then DBD::Informix does not report any
errors when it detects them; it is up to the user to note that errors have
occurred and to report them.

If you connect using the DBI->connect() method, or if you have
forgotten the driver, you can discover it again using:

    $drh = $dbh->{Driver};

This allows you to access the driver methods and attributes described
previously.

=over 4

BUG: The name of the database should be tracked more carefully via the
DATABASE, CLOSE DATABASE, CREATE DATABASE, ROLLFORWARD DATABASE and
START DATABASE statements.
Note that you cannot prepare CONNECT statements, so they do not have
to be tracked.

=back

=head2 DISCONNECTING FROM A DATABASE

You can also disconnect from the database:

    $dbh->disconnect;

This will rollback any uncommitted work.
Note that this does not destroy the database handle.
You need to do an explicit 'undef $dbh' to destroy the handle.
Any statements prepared using this handle are finished (see below) and
cannot be used again.
All space associated with the statements is released.

If you are using an Informix driver for which $drh->{ProductVersion} >= 600,
then you can have multiple concurrent connections.  This means that multiple
calls to $drh->connect will give you independent connections to one or more
databases.

If you are using an Informix driver for which $drh->{ProductVersion} < 600,
then you cannot have multiple concurrent connections.  If you make multiple
calls to $drh->connect, you will achieve the same effect as executing several
database statements in a row.  This will generally switch databases
successfully, but may invalidate any statements previously prepared.  It may
fail if the current database is not local, or if there is an active
transaction, etc.

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

You can execute most preparable parameterless statements using:

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

Unlike previous releases, which used some code from the DBI package,
DBD::Informix v0.26, now handles the 'do' operation exclusively with its
own code.

=over 4

BUG: If the statement you run is a SELECT, then it is prepared, and the
cursor is declared, opened (potentially expensive, if the statement uses
ORDER BY etc), and then closed and freed without fetching any data.  A more
robust version would generate an error condition without declaring the
cursor, etc.

=back

You can embed an arbitrary string inside a statement with any quote marks
correctly handled by invoking:

    $dbh->quote($string);

This method is provided by the DBI package implementation and is inherited
by the DBD::Informix package.  The string is enclosed in single quotes, and
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

According to the DBI specification, the prepare call accepts an
optional attributes parameter which is a reference to a hash.
At the moment, no parameters are recognized.
It would be reasonable to add, for example, {ix_CursorWithHold => 1} to
specify that the cursor should be declared WITH HOLD.
Similarly, you could add {ix_BlobLocation => 'InFile'} to support
per-statement blob location, and {ix_ScrollCursor => 1} to support
scroll cursors.

Note: in versions of DBD::Informix prior to 0.25, preparing a statement
also executed non-cursory statements and opened the cursor for cursory
statements.
This no longer occurs.

More typically, you need to do error checking, and this is achieved by
using:

    die "Failed to prepare '$stmt'\n"
        unless ($sth = $dbh->prepare($stmt));

=over 4

BUG: There is no way to tell whether the statement is just executable or
whether it is a cursory (fetchable) statement.  You are assumed to know.
An attribute such as {ix_IsCursory} could be added to povide this key piece
of information, and it shouldn't really be Informix-specific.

=back

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

Issue: At the moment, there is no checking by DBD::Informix on how
many input parameters are supplied and how many are needed.
Note that the Informix engines give no support for determining the
number of input parameters except in the VALUES clause of an INSERT
statement.
This needs to be resolved.

Issue: The Informix engines give no support for determining the types
of input parameters except in the VALUES clause of an INSERT
statement.
This means that DBD::Informix cannot handle blobs in the SET clause of
an UPDATE statement.
The only known way to deal with this is to use a SELECT to retrieve
the old data, a DELETE to remove it, and an INSERT to replace it with
the modified data.
Not nice, but it works.

BUG: The various bind routines defined by DBI (primarily to support
DBD::Oracle) are not implemented in DBD::Informix because there are no
clearly documented semantics associated with the calls.

=back

For cursory statements, you can discover what the returned column names, types,
nullability, etc are.  You do this with:

    @name = @{$sth->{NAME}};        # Column names
    @null = @{$sth->{NULLABLE}};    # True => accepts nulls
    @type = @{$sth->{TYPE}};        # ODBC Data Type numbers
    @prec = @{$sth->{PRECISION}};   # ODBC PRECISION numbers (or undef)
    @scal = @{$sth->{SCALE}};       # ODBC SCALE numbers (or undef)

    # Native (Informix) type equivalents
    @tnam = @{$sth->{ix_NativeTypeName}};# Type name
    @tnum = @{$sth->{ix_ColType}};       # Type number from SysColumns.ColType
    @tlen = @{$sth->{ix_ColLength}};     # Type length from SysColumns.ColLength

=over 4

BUG: $sth->{TYPE} currently returns the Native (Informix) Type Names.

BUG: $sth->{PRECISION} returns the value of SysColumns.ColLength.

BUG: $sth->{SCALE} returns the value of SysColumns.ColLength.

Note: Informix uses '(expression)' in the array $sth->{NAME} for any
non-aliassed computed value in a SELECT list, and to describe the
return values from stored procedures, and so on.
This could be usefully improved.
There is also no guarantee that the names returned are unique.
For example, in "SELECT A.Column, B.Column FROM Table1 A, Table1 B
WHERE ...", both the return columns are described as 'column'.

=back

If the statement is a cursory statement, you can retrieve the values in either
of two ways:

    $ref = $sth->fetch;
    @row = @{$ref};

    @row = @{$sth->fetch};  # Shorthand for above...

    @row = $sth->fetchrow;

As usual, you have to worry about whether this worked or not.  You would
normally, therefore, use:

    while ($ref = $sth->fetch)
    {
        # We know we got some data here
        ...
    }
    # Investigate whether an error occurred or the SELECT
    # simply had nothing more to return.
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

    $sth->{BlobLocation} = 'InMemory';      # Default
    $sth->{BlobLocation} = 'InFile';        # In a named file
    $sth->{BlobLocation} = 'DummyValue';    # Return dummy values
    $sth->{BlobLocation} = 'NullValue';     # Return undefined

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

BUG: BlobLocation is not honoured.

=back

When you have fetched as many rows as required, you close the cursor using:

    $sth->finish;

This simply closes the cursor; it does not free the cursor or the statement.
That is done when you destroy (undef) the statement handle:

    undef $sth;

You can also implicitly rebind a statement handle to a new statement
by simply using the same variable again.
This does not cause any memory leaks.

=head2 CURSORS FOR UPDATE

With DBD::Informix v0.51 and later, you can use the attribute
$sth->{CursorName} to retrieve the name of a cursor.
If the statement for $sth is actually a SELECT, and the cursor is in a
MODE ANSI database or is declared with the 'FOR UPDATE [OF col,...'
tag, then you can use the cursor name in a 'DELETE...WHERE CURRENT OF'
or 'UPDATE...WHERE CURRENT OF' statement.

    $st1 = $dbh->prepare("SELECT * FROM SomeTable FOR UPDATE");
    $wc = "WHERE CURRENT OF $st1->{CursorName}";
    $st2 = $dbh->prepare("UPDATE SomeTable SET SomeColumn = ? $wc");
    $st3 = $dbh->prepare("DELETE FROM SomeTable $wc");
    $st1->execute;
    $row = $st1->fetch;
    $st2->execute("New Value");
    $row = $st1->fetch;
    $st3->execute();

=head2 ACCESSING THE SQLCA RECORD

You can access the SQLCA record via either a database handle or a statement
handle.

    $sqlcode = $sth->{ix_sqlcode};
    $sqlerrm = $sth->{ix_sqlerrm};
    $sqlerrp = $sth->{ix_sqlerrp};
    @sqlerrd = $sth->{ix_sqlerrd};
    @sqlwarn = $sth->{ix_sqlwarn};

Note that the warning information is treated as an array (as in Informix-4GL)
rather than as a bunch of separate fields (as in Informix-ESQL/C).  Inspect
the code in the print_sqlca() function in InformixTest.pm for more ideas on
the use of these.  You cannot set the sqlca record.

=head1 TRANSACTION MANAGEMENT

=head2 The Interactions of AutoCommit with Informix Databases

There are 3 types of Informix database to consider: MODE ANSI, Logged,
UnLogged.  Although MODE ANSI databases also have a transaction log, the
category of Logged databases specifically excludes MODE ANSI databases.  In
OnLine, this refers to databases created WITH LOG or WITH BUFFERED LOG; in
SE, to databases created WITH LOG IN "/some/file/name".

There are 2 AutoCommit modes to consider: On, Off.

There are 2 possible transaction states: In-TX (In transaction), No-TX
(Outside transaction).

There are at least 13 types of statement (in 4 groups and 9 sub-groups) to
consider:

=over 2

=item *
    $drh->connect('xyz');                   # Group 1A

=item *
    $dbh->do('DATABASE xyz');               # Group 1B

=item *
    $dbh->do('CREATE DATABASE xyz');        # Group 1B

=item *
    $dbh->do('ROLLFORWARD DATABASE xyz');   # Group 1B

=item *
    $dbh->do('START DATABASE xyz');         # Group 1B

=item *
    $dbh->disconnect();                     # Group 2A

=item *
    $dbh->do('CLOSE DATABASE');             # Group 2B

=item *
    $dbh->commit();                         # Group 3A

=item *
    $dbh->rollback();                       # Group 3A

=item *
    $dbh->do('BEGIN WORK');                 # Group 3B

=item *
    $dbh->do('ROLLBACK WORK');              # Group 3C

=item *
    $dbh->do('COMMIT WORK');                # Group 3C

=item *
    $dbh->prepare('SELECT ...');            # Group 4A

=item *
    $dbh->prepare('UPDATE ...');            # Group 4B

=back

The Group 1 statements establish the default AutoCommit mode for a database
handle.  Group 1A is the primary means of connecting to a database; the
Group 1B statements can change the default AutoCommit mode by virtue of
changing the current database.

For a MODE ANSI database, the default AutoCommit mode is Off.
For a Logged database, the default AutoCommit mode is On.
For an UnLogged database, the default AutoCommit mode is On and it
cannot be changed.
Any attempt to change AutoCommit mode to Off with an UnLogged database
generates a non-fatal warning.

The Group 2 statements sever the connection to a database.  The Group 2A
statement renders the database handle unusable; no further operations are
possible except 'undef' or re-assigning with a new connection.  The Group 2B
statement means that no operations other than those in Group 1B or 'DROP
DATABASE' are permitted.  The value of AutoCommit is irrelevant after the
database is closed.

The Group 3 & 4 statements interact in many complicated ways.  Although
UPDATE is cited in Group 4B, it represents any statement which is not a
SELECT statement.  Note that 'SELECT ...  INTO TEMP' is a Group 4B
statement because it returns no data to the program.  An 'EXECUTE
PROCEDURE' statement is in Group 4A if it returns data, and in Group 4B if
it does not, and you cannot tell which of the two groups applies until after
the statement is prepared.

=head2 MODE ANSI Databases

By default, a MODE ANSI database operates with AutoCommit Off.  When the
connection is established, a transaction is started implicitly, and the
program will be inside a transaction (In-TX) at all times.  Whenever either
of the group 3A functions is used, a new transaction is automatically (but
implicitly) started.  The DBD::Informix code does not do an explicit
BEGIN WORK because the user is entitled to write their own BEGIN WORK
immediately after COMMIT WORK or ROLLBACK WORK (and hence $dbh->commit or
$dbh->rollback), and if DBD::Informix did this, the user would get an
unwarranted error.  Before disconnecting, the code does ROLLBACK
WORK to ensure that the disconnect can occur cleanly.

If the user elects to switch to AutoCommit On, things get trickier.  All
cursors need to be declared WITH HOLD so that Group 4B statements being
committed do not close the active cursors.  Whenever a Group 4B statement
is executed, the statement needs to be committed.  With OnLine (and
theoretically with SE, I think), if the statement fails there is no need to
do a rollback -- the statement failing did the rollback anyway.  And the
commit will automatically start a new transaction.  As before, the code can
do ROLLBACK WORK before disconnecting, though it should not actually be
necessary.

=over 4

BUG: DBD::Informix does not create WITH HOLD cursors for MODE ANSI databases
when AutoCommit mode is On.

=back

=head2 Logged Databases

Unlike MODE ANSI databases, Logged databases can be in either one of two
transaction states -- In-TX and No-TX.

AutoCommit is set to On when the connection is established, and the
transaction state is No-TX.  No further action is required by DBD::Informix
in this state.  Neither $dbh->commit nor $dbh->rollback should be used in
this state -- there is no transaction for them to work on.  If they are
called, the effect will be a no-op; all previous operations were already
committed or rolled back, so they will succeed.  Note that cursors
established in this state are not declared WITH HOLD.  If the user executes
$dbh->do('BEGIN WORK') or equivalent, then the AutoCommit functionality is
suspended and the transaction state is In-TX until the transaction is
terminated.  If a Group 3A function is executed, a new transaction is not
started explicitly and the transaction state is once more No-TX, and the
user can execute BEGIN WORK as required.  If the state at $dbh->disconnect
is In-TX, then DBD::Informix does a rollback before attempting to
disconnect.  If the user attempts to close the database (or open a new one)
while in the In-TX state, an error will be generated by Informix.

If the user sets AutoCommit off explicitly, DBD::Informix does an explicit
BEGIN WORK to start a transaction and the transaction state is In-TX (and
will stay like that until AutoCommit is set to On).  Cursors declared while
AutoCommit is off do not need to be declared WITH HOLD either, so cursors
in Logged databases are not WITH HOLD regardless of AutoCommit.  However,
it might be a good option to allow $dbh->{CursorsWithHold} to indicate that
they are to be declared WITH HOLD.  When the user executes a Group 3A
function, a new transaction is started explicitly (meaning that the user
cannot successfully execute BEGIN WORK) and the transaction state is In-TX.

=head2 UnLogged Databases

The transaction state is No-TX and AutoCommit is On, and this cannot
be changed.
Any attempt to set AutoCommit to Off generates a non-fatal warning but
the program will continue; setting it to On generates neither a
warning nor an error.
Both $dbh->commit and $dbh->rollback succeed but do nothing.
Executing any Group 3B or 3C statement will generate an error.

=head1 ATTRIBUTE NAME CHANGES

Note that most (theoretically all) of the Informix-specific attributes
have been renamed so that they start "ix_" (eg:
$dbh->{ix_AutoErrorReport}), and the old names which do not have this
systematic prefix are now officially deprecated.
An additional attribute, $dbh->{ix_Deprecated} was invented which
could be set to 0 to suppress the warning reports in earlier
(0.51..0.53) releases when a deprecated attribute was used.
The deprecated form {Deprecated} is also supported.

In this release (0.55), the deprecated warnings will alert you to
the fact that the old style attributes did not achieve anything, and
there will be no mechanism to switch the warnings off.
In the next release (0.56), using the old-style attribute names
will generate an error.
In the release after that (0.57), using the old-style attribute names
will do nothing silently.
The exact time scale for these releases is not clear (but will
probably be completed in Q3 of 1997 (give or take a year or two), so
if you don't upgrade for a few releases, you could run into problems
unexpectedly.

Note that some names may retain the form with no prefix if they are
accepted by the larger DBD/DBD community.
Two of the prime candidates for not having to change are ProductName
and ProductVersion.

=head1 MAPPING BETWEEN ESQL/C AND DBD::INFORMIX

A crude form of the mapping between DBD::Informix functions and ESQL/C
equivalents follows -- there are a number of ways in which it isn't quite
precise (eg the influence of AutoCommit), but it is accurate enough for
most purposes.

	DBI->connect            => DATABASE in 5.0x
	$dbh->disconnect        => CLOSE DATABASE in 5.0x

	DBI->connect            => CONNECT in 6.0x and later
	$dbh->disconnect        => DISCONNECT in 6.0x and later

	$dbh->commit            => COMMIT WORK (+BEGIN WORK)
	$dbh->rollback          => ROLLBACK WORK (+BEGIN WORK)

	$dbh->do                => EXECUTE IMMEDIATE
	$dbh->prepare           => PREPARE, DESCRIBE (DECLARE)
	$sth->execute           => EXECUTE or OPEN
	$sth->fetch             => FETCH
	$sth->fetchrow          => FETCH
	$sth->finish            => CLOSE

	undef $sth              => FREE cursor, FREE statement, etc

=head1 KNOWN RESTRICTIONS

=over 2

=item *
Blobs can only be located in memory (reliably).

=item *
Some driver attributes (notably CurrentConnection and
ActiveConnections) cannot be queried.

=item *
The new DBI spec (version 1.64) from Tim Bunce has not been assimilated
into the 0.52 version of DBD::Informix.

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

perl(1), perldoc for DBI.

=cut
