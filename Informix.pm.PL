#!/usr/bin/perl -w
#
#	Script to create annotated version of Informix.pm recording
#	default values of INFORMIXDIR and $INFORMIXSERVER during build.

use Config;
my $filename = $0;
$filename =~ s/\.PL$//;

my $dir = '/usr/informix';
my $server;
my $deflic = 'ACN#J334912';
my $licence = $deflic;
while (@ARGV and $ARGV[0] =~ /^-d(\w+)=(.*)/)
{
	my ($tag, $value) = ($1, $2);
	$tag eq 'INFORMIXDIR' and $dir = $value;
	$tag eq 'INFORMIXSERVER' and $server = $value;
	$tag eq 'INFORMIX_LICENCE' and $licence = $value;
	shift;
}

$licence =~ s/([A-Z][A-Z][A-Z])[@#]([A-Z]\d\d\d\d\d\d)/$1#$2/;
if ($licence !~ /[A-Z][A-Z][A-Z]#[A-Z]\d\d\d\d\d\d/)
{
	print STDERR "$0: invalid Informix licence number '$licence'\n";
	exit 1;
}
$licence .= " (default - no Tech Support available)"
	if ($licence eq $deflic);

open OUT,">$filename" or die "Can't create $filename: $!";
chmod(0755, $filename);

print "Extracting $filename from $0\n";
print " -- default INFORMIXDIR          = $ENV{INFORMIXDIR}\n";
print " -- default INFORMIXSERVER       = $ENV{INFORMIXSERVER})\n" if $server;
print " -- DBD::Informix Licence Number = $licence\n";

select(OUT);	# Set the default output file handle!

print qq%# Default value of INFORMIXDIR set when DBD::Informix was built.
# \$ENV{'INFORMIXDIR'} = qq[$dir]
%;
print qq%# Default value of INFORMIXSERVER set when DBD::Informix was built.
# \$ENV{'INFORMIXSERVER'} = qq[$server]
% if ($server);

while (<DATA>)
{
	s/:INFORMIX_LICENCE:/$licence/o if (m/:INFORMIX_LICENCE:/o);
	s/:INFORMIXDIR:/$dir/o          if (m/:INFORMIXDIR:/o);
	s/:INFORMIXSERVER:/$server/o    if (m/:INFORMIXSERVER:/o && $server);
	next if (m/:INFORMIXSERVER:/o && !$server);
	print "$_";
}

exit 0;

__END__

#	@(#)$Id: Informix.pm.PL version /main/2 2000-01-24 14:07:13 $
#
#   Portions Copyright (c) 1994-95   Tim Bunce
#   Portions Copyright (c) 1996-1999 Jonathan Leffler
#   Portions Copyright     2000      Informix Software Inc
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.

{
	package DBD::Informix;

	use DBI;
	use DynaLoader;
	@ISA = qw(DynaLoader);

	$VERSION          = "0.97002";
	$ATTRIBUTION      = 'Jonathan Leffler <j.leffler@acm.org>';
	$Revision         = '$Id: Informix.pm.PL version /main/2 2000-01-24 14:07:13 $';
	$INFORMIX_LICENCE = ":INFORMIX_LICENCE:";

	require_version DBI 1.02;	# Requires features from DBI 1.02 release

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
			foreach (qw(:INFORMIXDIR: /usr/informix /opt/informix))
			{
				# If Informix-Connect or Informix-ESQL/C is installed,
				# $INFORMIXDIR must have lib and msg sub-directories.
				if (-d "$_/lib" && -d "$_/msg")
				{
					$ENV{INFORMIXDIR} = $_;
					# warn "DBD::Informix - INFORMIXDIR set to $_\n";
					last;
				}
			}
			warn "INFORMIXDIR not set!\n" unless $ENV{INFORMIXDIR};
		}
		$ENV{INFORMIXSERVER} = ":INFORMIXSERVER:" unless ($ENV{INFORMIXSERVER});

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
			'Attribution'            => "$ATTRIBUTION",
			'ix_InformixLicence'     => "$INFORMIX_LICENCE",
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

	sub connect
	{
		my ($drh, $dbname, $dbuser, $dbpass, $dbattr) = @_;

		if ($ENV{DBD_INFORMIX_DEBUG_CONNATTR} && defined $dbattr)
		{
			my $attr;
			foreach $attr (keys %$dbattr)
			{
				print "# DBD::Informix::dr::connect",
						" - attribute: $attr => ${$dbattr}{$attr}\n";
			}
		}

		$dbname = "" unless(defined $dbname);
		$dbuser = "" unless(defined $dbuser);
		$dbpass = "" unless(defined $dbpass);

		# Create new database connection handle for driver
		my $dbh = DBI::_new_dbh($drh, {
				'Name' => $dbname,
				'User' => $dbuser,
				'Pass' => $dbpass
			});

		# Preset AutoCommit mode on $dbh.
		$dbattr = { AutoCommit => 1 } if (!defined $dbattr);
		${$dbattr}{AutoCommit} = 1 if (!defined ${$dbattr}{AutoCommit});
		DBD::Informix::db::preset($dbh, $dbattr);

		# Initialize database connection
		DBD::Informix::db::_login($dbh, $dbname, $dbuser, $dbpass)
			or return undef;

		$dbh;
	}
	1;
}

{
	package DBD::Informix::db; # ====== DATABASE ======
	use strict;

	sub prepare
	{
		my($dbh, $statement, $attr) = @_;

		my $sth = DBI::_new_sth($dbh, {
			'Statement' => $statement,
			});

		DBD::Informix::st::_prepare($sth, $statement, $attr)
			or return undef;

		$sth;
	}

	# -----------------------------------------------------------------
	# Use default implementation of do (which is DBD::_::db::do).  Although
	# EXECUTE IMMEDIATE was introduced in version 5.00 ESQL/C, allowing it
	# to be used means that we lose track of key operations such as BEGIN
	# WORK (as pointed out by Jason Bodnar <jcbodnar@mail.utexas.edu>).
	# So, DBD::Informix needs to use the full prepare, execute, finish
	# functions under all circumstances.  The default routine does that.
	# So use the default routine.
	# -----------------------------------------------------------------

	# -----------------------------------------------------------------
	# Override DBD::_::db::tables - it doesn't quote table owner names.
	# Mostly, this doesn't matter, unless you happen to be working with a
	# MODE ANSI database, where informix.systables and "informix".systables
	# are two very different tables, and the former does not usually exist!
	# Almost, but not quite, a copy of the function from DBI.pm.
	# NB: using double quotes around the name is correct even if DELIMIDENT
	# is set; using single quotes is OK unless DELIMIDENT is set.
	sub tables
	{
		my ($dbh, @args) = @_;
		my $sth = $dbh->table_info(@args);
		return () unless $sth;
		my ($row, @tables);
		while($row = $sth->fetch)
		{
			my $name = $row->[2];
			$name = qq{"$row->[1]".$name} if $row->[1];
			push @tables, $name;
		}
		return @tables;
	}
	# -----------------------------------------------------------------

	# -----------------------------------------------------------------
	# Utility functions: _tables and _columns
	# -----------------------------------------------------------------
	# SQL fragments to list tables, views and synonyms

	my %tables;
	$tables{'tables'}  =
		q{ SELECT T.Owner, T.TabName FROM 'informix'.SysTables T
			WHERE T.TabName NOT LIKE " %" };
	$tables{'user'}    = q{ AND T.Tabid >= 100 };
	$tables{'system'}  = q{ AND T.Tabid <  100 };
	$tables{'base'}    = q{ AND T.TabType = 'T' };
	$tables{'view'}    = q{ AND T.TabType = 'V' };
	$tables{'synonym'} =
		q{ AND (T.TabType = 'S' OR (T.TabType = 'P' AND T.Owner = USER)) };
	$tables{'order'}   = q{ ORDER BY T.Owner, T.TabName };

	sub _tables
	{
		my ($dbh, @info) = @_;
		my @result = ();
		my $i;
		# Build query string
		my $stmt = $tables{'tables'};
		for ($i = 0; $i <= $#info; $i++)
		{
			$i=~ tr/A-Z/a-z/;
			$stmt .= $tables{$info[$i]} unless $info[$i] eq 'tables';
		}
		$stmt .= $tables{'order'};
		# Only tidy the statement up if you're going to print it!
		# $stmt =~ s/^ //;
		# $stmt =~ s/ $//;
		# $stmt =~ s/  +/ /g;
		# print "$stmt\n";
		my $sth = $dbh->prepare($stmt);
		if (defined $sth)
		{
			return @result unless $sth->execute;
			my ($ref) = $sth->fetchall_arrayref;
			my (@arr) = @{$ref};
			my $i;
			my @row;
			for ($i = 0; $i <= $#arr; $i++)
			{
				@row = @{$arr[$i]};
				$result[$i] = qq('$row[0]'.$row[1]);
			}
			$sth->finish;
		}
		@result;
	}

	# -----------------------------------------------------------------
	#
	# Generating complete lists of columns for local tables, views, and
	# synonyms is hard!  For example, you need to do:
	#
	#-- Base Table Information
	# SELECT T.Owner, T.TabName, C.ColNo, C.ColName, C.ColType, C.ColLength
	#     FROM 'informix'.SysTables T, 'informix'.SysColumns C
	#     WHERE T.Tabid = C.Tabid
	#       AND T.TabType IN ('T', 'V')
	#       AND (T.TabName IN ('privsyn', 'pubsyn', 'tabcol') OR
	# 	 	     ((T.TabName = 'syscolumns' AND T.Owner = 'informix')))
	# UNION
	# -- Local Synonyms (PUBLIC and PRIVATE)
	# SELECT T.Owner, T.TabName, C.ColNo, C.ColName, C.ColType, C.ColLength
	#     FROM 'informix'.SysTables T, 'informix'.SysColumns C,
	#          'informix'.SysSynTable S
	#     WHERE T.Tabid = S.Tabid
	#       AND S.BTabid = C.Tabid
	#       AND ((T.TabType = 'P' AND T.Owner = USER) OR T.TabType =  'S')
	#       AND (T.TabName IN ('privsyn', 'pubsyn', 'tabcol') OR
	# 		     ((T.TabName = 'syscolumns' AND T.Owner = 'informix')))
	# -- Remote Synonyms are not handled!
	# ORDER BY 1, 2, 3;
	#
	# Mercifully, local synonyms cannot be built on top of other local
	# synonyms.  Adding support for remote synonyms doesn't bear thinking
	# about, as they can be chained through an arbitrary number of remote
	# sites.
	#
	# -----------------------------------------------------------------
	# SQL fragments to list columns
	# Note the re-use of $tables{'synonym'} from above!

	my %columns;
	$columns{'columns'}  =
		q{
	SELECT T.Owner, T.TabName, C.ColNo, C.ColName, C.ColType, C.ColLength
		FROM 'informix'.SysTables T, 'informix'.SysColumns C
		};
	$columns{'direct'}  =
		q{ WHERE T.Tabid = C.Tabid AND T.TabType IN ('T', 'V') };
	$columns{'synonym'} = qq{ , 'informix'.SysSynTable S
	WHERE T.Tabid = S.Tabid AND S.BTabid = C.Tabid
	$tables{'synonym'}
		};
	$columns{'order'}   = q{ ORDER BY 1, 2, 3 };

	sub _columns
	{
		my ($dbh, @tables) = @_;
		my @result = ();
		my $i;
		# Build query string
		my $s_list = "";
		my $s_pad = "";
		my $d_list = "";
		my $d_pad = "";
		for ($i = 0; $i <= $#tables; $i++)
		{
			my $tab = $tables[$i];
			if ($tab =~ /["'](.+)["']\.(.*)/)
			{
				$d_list .= "$d_pad (T.TabName = '$2' AND T.Owner = '$1') ";
				$d_pad = "OR";
			}
			else
			{
				$s_list .= "$s_pad '$tab'";
				$s_pad = ", ";
			}
		}
		$s_list = "T.TabName IN ($s_list)" if $s_list;
		my $cond = "";
		if ($d_list && $s_list)
		{
			$cond = " AND (($s_list) OR ($d_list))"
		}
		elsif ($s_list)
		{
			$cond = " AND ($s_list)" if $s_list;
		}
		elsif ($d_list)
		{
			$cond = " AND ($d_list)" if $d_list;
		}
		my $stmt  = "$columns{'columns'} $columns{'direct'} $cond";
		$stmt .= "UNION $columns{'columns'} $columns{'synonym'} $cond";
		$stmt .= " $columns{'order'}";
		# Only tidy the statement up if you're going to print it!
		#$stmt =~ s/^ //;
		#$stmt =~ s/ $//;
		#$stmt =~ s/  +/ /g;
		#print "$stmt\n";
		my $sth = $dbh->prepare($stmt);
		if (defined $sth)
		{
			return @result unless $sth->execute;
			my ($ref) = $sth->fetchall_arrayref;
			@result = @{$ref};
			$sth->finish;
		}
		@result;
	}

	#-----------------------------------------------------------------
	# table_info function - originally by David Bitseff <dbitsef@uswest.com>
	# NB: DBI spec says it needs: TABLE_QUALIFIER, TABLE_OWNER, TABLE_NAME,
	# TABLE_TYPE and TABLE_REMARKS in that order, possibly with extra data.
	# There's no explanation of what a TABLE_QUALIFIER is, so null (undef)
	# should be returned.  The table type is supposed to be one of:
	# "TABLE", "VIEW", "SYSTEM TABLE", "GLOBAL TEMPORARY", "LOCAL
	# TEMPORARY", "ALIAS", "SYNONYM" or a datasource-specific type.
	# Informix can't identify temporary tables;  there are no
	# ALIAS tables; there are private and public synonyms, so we'll return
	# the datasource specific 'PRIVATE SYNONYM' for them.
	# Note that the temp table cannot be dropped until the statement handle
	# is destroyed, but we don't know when the handle is destroyed, so we
	# either have to drop it and recreate it each time, or check whether
	# it has already been created and only create it if not.

	sub table_info
	{
		my($dbh) = @_;
		my($tab) = "dbd_ix_tabinfo_typ";
		my($msg);
		my($handler) = $SIG{__WARN__};
		$SIG{__WARN__} = sub { $msg = $_[0]; };
		my ($ok) = $dbh->do("CREATE TEMP TABLE $tab (tabtype CHAR(1) NOT NULL UNIQUE, typename CHAR(20) NOT NULL);");
		$SIG{__WARN__} = $handler;
		if ($ok)
		{
			$dbh->do("INSERT INTO $tab VALUES('T', 'TABLE');
					  INSERT INTO $tab VALUES('C', 'SYSTEM TABLE');
					  INSERT INTO $tab VALUES('V', 'VIEW');
					  INSERT INTO $tab VALUES('A', 'ALIAS');
					  INSERT INTO $tab VALUES('S', 'SYNONYM');
					  INSERT INTO $tab VALUES('P', 'PRIVATE SYNONYM');
					  INSERT INTO $tab VALUES('G', 'GLOBAL TEMPORARY');
					  INSERT INTO $tab VALUES('L', 'LOCAL TEMPORARY');
					 ") or return undef;
		}
		my $sth = $dbh->prepare(qq{
			SELECT
				'' AS TABLE_QUALIFIER,
				T.Owner AS TABLE_OWNER,
				T.TabName AS TABLE_NAME,
				I.TypeName AS TABLE_TYPE,
				'TabID: ' || T.TabID || ' Created: ' || EXTEND(T.Created, YEAR TO DAY) AS TABLE_REMARKS
			FROM "informix".systables T, $tab I
			WHERE (T.TabID >= 100 AND I.TabType = T.TabType)
			   OR (T.TabID < 100 AND T.TabType = 'T' AND I.TabType = 'C')
			ORDER BY TABLE_OWNER, TABLE_NAME
			}) or return undef;
		$sth->execute or return undef;
		$sth;
	}

  	# -----------------------------------------------------------------

	1;
}

{
	package DBD::Informix::st; # ====== STATEMENT ======

	1;
}

1;

# NB: the paragraphs in the following documentation should be formatted
#     using "fill -sl70".

__END__

=head1 NAME

DBD::Informix - Access to Informix Databases

=head1 SYNOPSIS

  use DBI;

=head1 DESCRIPTION

This document describes DBD::Informix version 0.97002.

You should also read the documentation for DBI as this document
qualifies what is stated there.
Note that this document was last updated for the DBI 0.85
specification, but the code requires features from the DBI 1.02
release or later.
Consequently, both this document and DBD::Informix are probably
considerably out of line with some of the new features and minor
details of the DBI specification.

This document still has a biassed view of how to use DBI and
DBD::Informix.
It covers parts of DBI and most of DBD::Informix.
Originally (say late 1996), the DBI documentation was in a parless
state.
It has improved with each release of DBI, and the DBI document's
comments about DBI and its drivers are a better indication of what
should happen, but this document may be a better reflection of the
actual behaviour of DBD::Informix.

Be aware that on occasion, the description in this document gets
complex because of differences between different versions of Informix
software and different types of Informix database.
The key factor is the version of ESQL/C used when building
DBD::Informix.
Basically, there are two groups of versions to worry about, the 5.0x
family of versions (5.00.UC1 through 5.10.UC1 at the moment), and the
6.0x and later family of versions (6.00.UE1 through 9.21.UC1 at the
moment).
All version families acquire extra versions on occasion.

Note that DBD::Informix does not work with 4.1x or earlier versions of
ESQL/C because it uses both SQL descriptors and strings for cursor
names and statement names, and these features were not available in
ESQL/C prior to version 5.00.

You should also read the Notes/Informix.Licence file which is
distributed with DBD::Informix for information about Informix
software.

There is a Japanese translation of a recent version of this
documentation (maintained by Kawai Takanori <kawai@nippon-rad.co.jp>) at
the web site:

http://member.nifty.ne.jp/hippo2000/perltips/DBD/informix.htm

=head1 USE OF DBD::Informix

=head2 Loading DBD::Informix

To use the DBD::Informix software, you need to load the DBI software.

    use DBI;

Under normal circumstances, you should then connect to your database
using the notation in the section "CONNECTING TO A DATABASE" which
calls DBI->connect().
Note that some of the DBD::Informix test code does not operate under
normal circumstances, and therefore uses the non-preferred techniques
in the section "Driver Attributes and Methods".

Note that you do not write:

    use DBD::Informix;      # !!BUGGY CODE!!

=head2 Driver Attributes and Methods

If you have a burning desire to do so, you can explicitly install the
Informix driver independently of connecting to any database using:

    $drh = DBI->install_driver('Informix');

This gives you a reference to the driver, aka the driver handle.
If the load fails, your program stops immediately (unless, perhaps,
you eval the statement).

Once you have the driver handle, you can interrogate the driver for
some basic information:

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
    # ProductName is the version of ESQL/C; it corresponds to
    # the first line of the output from "esql -V".
    print "    Product:               $drh->{ix_ProductName}\n";
    # ProductVersion is an integer version number such as 721
    # for ESQL/C version 7.21.UC1.
    print "    Product Version:       $drh->{ix_ProductVersion}\n";
    # MultipleConnections indicates whether the driver
    # supports multiple connections (1) or not (0).
    print "    Multiple Connections:  $drh->{ix_MultipleConnections}\n";
    # ActiveConnections identifies the number of open connections.
    print "    Active Connections:      $drh->{ix_ActiveConnections}\n";
    # CurrentConnection identifies the current connection.
    print "    Current Connections:     $drh->{ix_CurrentConnection}\n";

Once you have the driver loaded, you can connect to a database, or you
can sever all connections to databases with disconnect_all.

    $drh->disconnect_all;

You can find out which databases are available using the function:

    @dbnames = DBI->data_sources('Informix');

Note that you may be able to connect to still other databases using
other notations (eg, you can probably connect to "dbase@server" if
"server" appears in the sqlhosts file and the database "dbase" exists
on the server and the server is up and you have permission to use the
server and the database on the server and so on).
Also, you may not be able to connect to every one of the databases
listed if you have not been given connect permission on the database.
However, the list provided by the DBI->data_sources method certainly
exist and it is legitimate to try connecting to them.

You can test whether this worked with:

    if (defined @dbnames) { ...process array... }
    else                  { ...process error... }

See also test file "t/dblist.t".

=head1 CONNECTING TO A DATABASE

To connect to a database, you can use the connect function, which
yields a valid reference or database handle if it is successful.
If the driver itself cannot be loaded (by the DBI->install_driver()
method mentioned above), DBI aborts the script (and DBD::Informix can
do nothing about it because it wasn't loaded successfully).
Note that you get a warning if INFORMIXDIR is not set in the
environment.
If you don't want that warning, set INFORMIXDIR.

    $dbh = DBI->connect("dbi:Informix:$database");
    $dbh = DBI->connect("dbi:Informix:$database", $user, $pass);
    $dbh = DBI->connect("dbi:Informix:$database", $user, $pass, %attr);

The DBI connect method strips the 'dbi:' prefix from the first
argument, loads the DBD module identified by the next string (Informix
in this case).
The string following the second colon is all that is passed to the
DBD::Informix code.
With this format, you do not have to specify the username or password.
Note that if you specify the username but not the password,
DBD::Informix will silently ignore the username.
You can also specify certain attributes in the connect call.
These include:

    AutoCommit
    PrintError
    RaiseError

Note that you cannot specify ChopBlanks in this list.
DBD::Informix used to recognize the ix_AutoErrorReport attribute as a
synonym for the PrintError attribute, except that ix_AutoErrorReport
was not recognised in the connect call.
However, ix_AutoErrorReport is no longer functional (it generates a
warning message and is otherwise ignored) and you should upgrade any
code which uses it to use the DBI standard PrintError instead.
DBD::Informix will soon not recognize ix_AutoErrorReport at all.
Using the new style connect, you could therefore specify that the
database is not to operate in AutoCommit mode but errors should be
reported automatically by specifying:

    $dbh = DBI->connect("dbi:Informix:$database", '', '',
                        { AutoCommit => 0, PrintError => 1 });

Using this style of connection, the default value for AutoCommit is On
(or 1); this is a contrast to the old style where the default is Off
(or 0).
Also note that starting with the DBD::Informix 0.56 release, the
behaviour is not affected by the type of Informix database to which
you are connecting, except that you may get a warning if you try to
set AutoCommit Off when you connect to an UnLogged database.
See also the extensive notes in the TRANSACTION MANAGEMENT section
later in this document.

=head2 "Obsolescent Connection Method"

The older style of connection does not use the string "dbi:Informix:"
at the start of the first argument.
This style is strongly deprecated, notwithstanding the fact that one
of the tests uses it.

    $dbh = DBI->connect($database, $username, $password, 'Informix');

Note that if you omit the fourth argument ('Informix'), then DBI will
may load any driver it chooses, according to its rules -- the actual
driver loaded is not controlled by DBD::Informix.
If you omit the fourth argument, you can also omit the $password and
$username arguments if desired.
If you specify the fourth argument, you can leave the $password and
$username arguments empty and they will be ignored.

    $dbh = DBI->connect($database, $username, $password);
    $dbh = DBI->connect($database, $username);
    $dbh = DBI->connect($database);

=head2 "Informix Connection Semantics"

If you are using 5.0x versions of ESQL/C, then DBD::Informix ignores
the username and password data, and the statement is equivalent to
"EXEC SQL DATABASE :database;".
If you are using 6.0x or later versions of ESQL/C, then DBD::Informix
will only use the username and password if both are supplied, but it
is then equivalent to:

    EXEC SQL CONNECT TO :database AS :connection
        USER :username USING :password
        WITH CONCURRENT TRANSACTIONS

The connection is given a name by DBD::Informix.

For DBD::Informix, the database name is any valid format for the DATABASE
or CONNECT statements.

Examples include:

    dbase               # 'Local' database
    //machine1/dbase    # Database on remote machine
    dbase@server1       # Database on (remote) server (as defined in sqlhosts)
    @server1            # Connection to (remote) server but no database
    /some/where/dbase   # Connect to local SE database

No database name is supplied implicitly by DBD::Informix (though the
test code in InformixTest.pl does supply the names of test databases
implicitly).
Read the DBI driver documentation to see what, if any, defaults will
be supplied (eg check for the DBI_DRIVER and DBI_DSN environment
variables).
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
The ix_ServerVersion, ix_BlobSupport and ix_StoredProcedures
attributes are read-only attributes introduced in v0.95, mainly to
provide support for the XPS servers, which do not necessarily have
blob and stored procedure support, unlike other versions of Informix
OnLine.
Note that to determine these values, DBD::Informix interrogates the
system catalogue, which represents a (small) performance hit.

     print "Database Information\n";
     # Type is always 'db'
     print "    Type:                    $dbh->{Type}\n";
     # ix_ServerVersion is a number, just like ix_ProductVersion is a number.
     # Although version 5.10.UC7 SE servers correctly report a
     # version number, some earlier versions may report 0.
     print "    Server Version:          $dbh->{ix_ServerVersion}\n";
     # Name is the name of the database specified at connect
     print "    Original Database Name:  $dbh->{Name}\n";
     # ix_DatabaseName is the name of the current database
     print "    Current Database Name:   $dbh->{ix_DatabaseName}\n";
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
     # PrintError is 1 (true) if errors are reported when detected.
     print "    Print Errors:            $dbh->{PrintError}\n";
     # ix_InTransaction is 1 (true) if the database is in a transaction
     print "    Transaction Active:      $dbh->{ix_InTransaction}\n";
     # ix_BlobSupport is 1 (true) if the database supports blobs
     print "    Blob Support:            $dbh->{ix_BlobSupport}\n";
     # ix_StoredProcedures is 1 (true) if the database has stored procedures
     print "    Stored Procedures:       $dbh->{ix_StoredProcedures}\n";
     # ix_ConnectionName is the name of the ESQL/C connection.
     # Mainly applicable with Informix ESQL/C 6.00 and later.
     print "    Connection Name:         $dbh->{ix_ConnectionName}\n";

If $dbh->{PrintError} is true, then DBI will report each error
automatically on STDERR when it is detected.
The error is also available via the package variables $DBI::errstr and
$DBI::err.
Note that $DBI::errstr includes the SQL error number and the ISAM
error number if there is one.
The message may or may not extend over several lines, and is generally
formatted so that it will display neatly within 80 columns.
The last character of the message used be a newline, but (starting
with version 0.62) the trailing new line is omitted to improve the
automatic error reports from Perl.

If $dbh->{PrintError} is false, then DBI does not report any errors
when it detects them; it is up to the user to note that errors have
occurred and to report them.

If you connect using the DBI->connect() method, or if you have
forgotten the driver, you can discover it again using:

    $drh = $dbh->{Driver};

This allows you to access the driver methods and attributes described
previously.

Starting with version 0.60, the name of the database is now tracked
accurately when the DATABASE, CLOSE DATABASE, CREATE DATABASE,
ROLLFORWARD DATABASE and START DATABASE statements are used.
Note that you cannot prepare CONNECT statements, so they do not have
to be tracked.

=head2 METADATA

There are two methods which can be called using the DBI func() to get
at some basic Informix metadata relatively conveniently.

    @list = $dbh->func('_tables');
    @list = $dbh->func('user', '_tables');
    @list = $dbh->func('base', '_tables');
    @list = $dbh->func('user', 'base', '_tables');
    @list = $dbh->func('system', '_tables');
    @list = $dbh->func('view', '_tables');
    @list = $dbh->func('synonym', '_tables');

The lists of tables are all qualified as 'owner'.tablename, and may be
used in SQL statements without fear that the table is not present in
the database (unless someone deletes it behind your back).
The leading arguments qualify the list of names returned.
Private synonyms are only reported for the current user.

    @list = $dbh->func('_columns');
    @list = $dbh->func(@tables, '_columns');

The lists are each references to an array of values corresponding to
the owner name, table name, the column number, the column name, the
basic data type (ix_ColType value - see below) and data length
(ix_ColLength - see below).
If no tables are listed, then all columns in the database are listed.
This can be quite slow because handling synonyms properly requires a
UNION operation.
Further, although the '_tables' method report the names of remote
synonyms, the '_columns' method does not expand them (mainly because
it is very hard t do it properly).
See the examples in t/metadata.t for how these can be used.
Exercise for the reader: extend '_columns' so that it reports on the
columns in remote synonyms, including relocated remote synonyms where
the original referenced site now forwards the name to a third site!

=head2 DISCONNECTING FROM A DATABASE

You can also disconnect from the database:

    $dbh->disconnect;

This will rollback any uncommitted work.
Note that this does not destroy the database handle.
You need to do an explicit 'undef $dbh' to destroy the handle.
Any statements prepared using this handle are finished (see below) and
cannot be used again.
All space associated with the statements is released.

If you are using an Informix driver for which $drh->{ProductVersion}
>= 600, then you can have multiple concurrent connections.
This means that multiple calls to $drh->connect will give you
independent connections to one or more databases.

If you are using an Informix driver for which $drh->{ProductVersion} <
600, then you cannot have multiple concurrent connections.
If you make multiple calls to $drh->connect, you will achieve the same
effect as executing several database statements in a row.
This will generally switch databases successfully, but may invalidate
any statements previously prepared.
It may fail if the current database is not local, or if there is an
active transaction, etc.

=head2 SIMPLE STATEMENTS

Given a database connection, you can execute a variety of simple
statements using a variety of different calls:

    $dbh->commit;
    $dbh->rollback;

These two operations commit or rollback the current transaction.
If the database is unlogged, they do nothing.
If AutoCommit is set to 1, then they do nothing useful.
If AutoCommit is set to 0, then a new transaction is started
(implicitly for a database which is MODE ANSI, explicitly for a
database which is not MODE ANSI).

You can execute most preparable parameterless statements using:

    $dbh->do($stmt);

The statement should not be either SELECT (other than SELECT...INTO
TEMP) or EXECUTE PROCEDURE where the procedure returns data.

You can execute an arbitrary statement with parameters using:

    $dbh->do($stmt, undef, @parameters);
    $dbh->do($stmt, undef, $param1, $param2);

The 'undef' represents an undefined reference to a hash of attributes
(\%attr) which is documented in the DBI specification.
The 0.56 edition of this documentation omitted this argument, which
caused confusion.
Again, the statement must not be a SELECT or EXECUTE PROCEDURE which
returns data.
The values in @parameters (or the separate values) are bound to the
question marks in the statement string.

    $sth = $dbh->prepare($stmt);
    $sth->execute(@parameters);

The code in DBD::Informix versions 0.26 through 0.55 used handled the
'do' operation exclusively with its own code, and used the EXECUTE
IMMEDIATE statement when possible.
Releases prior to 0.26 and releases from 0.56 use the code from the
DBI package and do not use EXECUTE IMMEDIATE.

You can embed an arbitrary string inside a statement with any quote
marks correctly handled by invoking:

    $dbh->quote($string);

This method is provided by the DBI package implementation and is
inherited by the DBD::Informix package.
The string is enclosed in single quotes, and any embedded single
quotes are doubled up, which conforms to the SQL-92 standard.
This would typically be used in a context such as:

    $value = "Doesn't work unless quotes (\"'\" and '\"') are handled";

    $stmt = "INSERT INTO SomeTable(SomeColumn) " .
            "VALUES(" . $dbh->quote($value) . ")";

Doing this ensures that the data in $values will be interpreted
correctly, regardless of what quotes appear in $value (unless it
contains newline characters).
Note that the alternative assignment below does not work!

    $stmt = "INSERT INTO SomeTable(SomeColumn) VALUES($dbh->quote($value))";

=head2 CREATING STATEMENTS

You can also prepare a statement for multiple uses, and you can do
this for SELECT and EXECUTE PROCEDURE statements which return data
(cursory statements) as well as non-cursory statements which return no data.
You create a statement handle (another reference) using:

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

More typically, you need to do error checking, and this is achieved by
using:

    # Emphasizing the error handling
    die "Failed to prepare '$stmt'\n"
        unless ($sth = $dbh->prepare($stmt));

    # Emphasizing the SQL action
    $sth = $dbh->prepare($stmt) or die "Failed to prepare '$stmt'\n"

You can tell whether the statement is just executable or whether it is
a cursory (fetchable) statement by testing the (new with v0.95)
attribute ix_Fetchable.
It shouldn't really be an Informix-specific attribute; if DBI ever
adds such an attribute, ix_Fetchable will be deprecated.

Once the statement is prepared, you can execute it:

    $sth->execute;

For a non-cursory statement, this simply executes the statement.
If the statement is executed successfully, then the number of rows
affected will be returned.
If an error occurs, the returned value will be undef.
If the statement does not affect any rows, the string returned is
"0E0" which evaluates to true but also to zero.

For a cursory statement, it opens the cursor.
If the cursor is opened successfully, then it returns the value "0E0"
which evaluates to true but also to zero.
If an error occurs, the returned value will be undef.

Although the DBI 0.85 spec is silent on the issue, you can also
specify the input parameters for a statement using:

    $sth->execute(@parameters);

The first parameter will be supplied as the value for the first
place-holder question mark in the statement, the second parameter for
the second place-holder, etc.

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

Warning: later versions of DBI will specify methods to bind input
parameters for statements to Perl variables.
This is another area subject to change, therefore.

=back

For cursory statements, you can discover what the returned column
names, types, nullability, etc are.
You do this with:

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

Note: Informix uses '(expression)' in the array $sth->{NAME} for any
non-aliassed computed value in a SELECT list, and to describe the
return values from stored procedures, and so on.
This could be usefully improved.
There is also no guarantee that the names returned are unique.
For example, in "SELECT A.Column, B.Column FROM Table1 A, Table1 B
WHERE ...", both the return columns are described as 'column'.

=back

If the statement is a cursory statement, you can retrieve the values
in any of a number of ways, as described in the DBI specification.

    $ref = $sth->fetchrow_arrayref;
    $ref = $sth->fetch;                 # Alternative spelling...
    @row = @{$ref};

    @row = @{$sth->fetchrow_arrayref};  # Shorthand for above...

    @row = $sth->fetchrow_array;

    $ref = $sth->fetchall_arrayref;

As usual, you have to worry about whether this worked or not.
You would normally, therefore, use:

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

The returned data includes blobs mapped into strings.
Note that byte blobs might contain ASCII NUL '\0' characters.
Perl knows how long the strings are and does preserve NUL in the
middle of a byte blob.
However, you may need to be careful deciding how to handle this
string.

There is provision to specify how you want blobs handled.
You can set the attribute:

    $sth->{ix_BlobLocation} = 'InMemory';      # Default
    $sth->{ix_BlobLocation} = 'InFile';        # In a named file
    $sth->{ix_BlobLocation} = 'DummyValue';    # Return dummy values
    $sth->{ix_BlobLocation} = 'NullValue';     # Return undefined

The InFile mode returns the name of a file in the fetched array, and
that file can be accessed by Perl using normal file access methods.
The DummyValue mode returns "<<TEXT VALUE>>" for text blobs or "<<BYTE
VALUE>>" for byte (binary) blobs.
The NullValue mode returns undefined (meaning that Perl's "defined"
operator would return false) values.
Note that these two options do not necessarily prevent the Server from
returning the data to the application, but the user does not get to
see the data -- this depends on the internal implementation of the
ESQL/C FETCH operation in conjunction with SQL descriptors.

You can also set the ix_BlobLocation attribute on the database,
overriding it at the statement level.

=over 4

BUG: ix_BlobLocation is not handled properly.

=back

When you have fetched as many rows as required, you close the cursor using:

    $sth->finish;

You do not have to finish a cursor explicitly if you executed a fetch
which failed to retrieve any data.

Doing $sth->finish simply closes the cursor; it does not free the cursor or the statement.
That is done when you destroy (undef) the statement handle:

    undef $sth;

You can also implicitly rebind a statement handle to a new statement
by simply using the same variable again.
This does not cause any memory leaks.

You can retrieve use the ix_StatementText attribute to (re)discover
the text of a statement:

    $txt = $sth->{ix_StatementText};

The ix_StatementText attribute has been superseded by the DBI
attribute Statement.
It will be deprecated, starting with v0.95.

=head2 CURSORS FOR UPDATE

You can use the attribute $sth->{CursorName} to retrieve the name of a
cursor.
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

You can access the SQLCA record via either a database handle or a
statement handle.

    $sqlcode = $sth->{ix_sqlcode};
    $sqlerrm = $sth->{ix_sqlerrm};
    $sqlerrp = $sth->{ix_sqlerrp};
    @sqlerrd = @{$sth->{ix_sqlerrd}};
    @sqlwarn = @{$sth->{ix_sqlwarn}};

Note that the warning information is treated as an array (as in
Informix 4GL) rather than as a bunch of separate fields (as in
Informix ESQL/C).
However, the array is indexed from zero (as in ESQL/C, C, Perl etc),
rather than from one (as in Informix 4GL).
Also note that both $sth->{ix_sqlerrd} and $sth->{ix_sqlwarn} return a
reference to an array.
Inspect the code in the print_sqlca() function in InformixTest.pl for
more ideas on the use of these.
You cannot set the sqlca record.

The sqlerrd array has the following useful columns:

        $sth->{ix_sqlerrd}[1] - serial value after insert or ISAM error code
        $sth->{ix_sqlerrd}[3] - estimated cost
        $sth->{ix_sqlerrd}[4] - offset of the error into the SQL statement
        $sth->{ix_sqlerrd}[5] - rowid of the last row processed

=head2 OBTAINING THE VALUE INSERTED FOR A SERIAL COLUMN

The following example is a very useful and important technique with Informix.
However, it is also not portable to other databases (because they do not have
the SERIAL data type).

        # insert a row into a table with a primary key that is a SERIAL
        $stmt = $dbh->do("insert into table (serial_id, number) values(0, 10)");
        print "the new row has a serial_id of $sth->{ix_sqlerrd}[1]\n";

For more information, you can read the "Informix ESQL/C Programmer's
Manual" or "Informix Guide to SQL: Reference Manual".
The exact chapter and verse varies depending on which version you are
using.

=head1 TRANSACTION MANAGEMENT

Transaction management changed in the DBD::Informix 0.56 release, in
part because the DBI specification has changed.
You should read this section carefully.
If you find a deviation between what is documented and what actually
occurs, please report it.
The problem may be in the documentation or in the code (or both).

Previously, the type of Informix database had an affect on the default
AutoCommit attribute.
Now the AutoCommit attribute (which can be set in the DBI->connect()
call) controls the AutoCommit behaviour exclusively.

=head2 The Interactions of AutoCommit with Informix Databases

There are 3 types of Informix database to consider: MODE ANSI, Logged,
UnLogged.
Although MODE ANSI databases also have a transaction log, the category
of Logged databases specifically excludes MODE ANSI databases.
In OnLine, this refers to databases created WITH LOG or WITH BUFFERED
LOG; in SE, to databases created WITH LOG IN "/some/file/name".

There are 2 AutoCommit modes to consider: On, Off.

There are 2 possible transaction states: In-TX (In transaction), No-TX
(Outside transaction).

There are at least 13 types of statement (in 4 groups and 9 sub-groups) to
consider:

=over 2

    $drh->connect('xyz');                   # Group 1A
    $dbh->do('DATABASE xyz');               # Group 1B
    $dbh->do('CREATE DATABASE xyz');        # Group 1B
    $dbh->do('ROLLFORWARD DATABASE xyz');   # Group 1B
    $dbh->do('START DATABASE xyz');         # Group 1B
    $dbh->disconnect();                     # Group 2A
    $dbh->do('CLOSE DATABASE');             # Group 2B
    $dbh->commit();                         # Group 3A
    $dbh->rollback();                       # Group 3A
    $dbh->do('BEGIN WORK');                 # Group 3B
    $dbh->do('ROLLBACK WORK');              # Group 3C
    $dbh->do('COMMIT WORK');                # Group 3C
    $dbh->prepare('SELECT ...');            # Group 4A
    $dbh->prepare('UPDATE ...');            # Group 4B

=back

The Group 1 statements establish connections to databases.
The type of database to which you are connected has no effect on the
AutoCommit mode.
Group 1A is the primary means of connecting to a database; the Group
1B statements can change the current database.
The Group 1B statements cannot be executed except on the ".DEFAULT."
connection if you are using ESQL/C 6.00 or later.

For all types of database, the default AutoCommit mode is On.
With a MODE ANSI or a Logged database, the value of AutoCommit can be
set to Off, which automatically starts a transaction (explicitly if
the database is Logged, implicitly if the database is MODE ANSI).
For an UnLogged database, the AutoCommit mode cannot be changed.
Any attempt to change AutoCommit mode to Off with an UnLogged database
generates a non-fatal warning.

The Group 2 statements sever the connection to a database.
The Group 2A statement renders the database handle unusable; no
further operations are possible except 'undef' or re-assigning with a
new connection.
The Group 2B statement means that no operations other than those in
Group 1B or 'DROP DATABASE' are permitted on the handle.
As with the Group 1B statements, the Group 2B statement can only be
used on a ".DEFAULT." connection.
The value of AutoCommit is irrelevant after the database is closed,
but is not altered by DBD::Informix.

The Group 3 & 4 statements interact in many complicated ways, but the
new style of operation simplifies the interactions considerably.
One side-effect of the changes is that BEGIN WORK is completely
marginalized, and will generally cause an error.
Although UPDATE is cited in Group 4B, it represents any statement
which is not a SELECT statement.
Note that 'SELECT...INTO TEMP' is a Group 4B statement because it
returns no data to the program.
An 'EXECUTE PROCEDURE' statement is in Group 4A if it returns data,
and in Group 4B if it does not, and you cannot tell which of the two
groups applies until after the statement is prepared.

=head2 MODE ANSI Databases

Previously, MODE ANSI databases were regarded as being in a
transaction at all times, but this is not the only way to view the way
these databases work.
However, it is more satisfactory to regard the state immediately after
a database is opened, or immediately after a COMMIT WORK or ROLLBACK
WORK operation as being in the No-TX state.
Any statement other than a disconnection statement (Group 2) or a
commit or rollback (Groups 3A or 3C) takes the databases into the
In-TX state.

In a MODE ANSI database, you can execute BEGIN WORK successfully.
However, if AutoCommit is On, the transaction is immediately
committed, so it does you no good.

If the user elects to switch to AutoCommit On, things get trickier.
All cursors need to be declared WITH HOLD so that Group 4B statements
being committed do not close the active cursors.
Whenever a Group 4B statement is executed, the statement needs to be
committed.
With OnLine (and theoretically with SE), if the statement fails there
is no need to do a rollback -- the statement failing did the rollback
anyway.
As before, the code does ROLLBACK WORK before disconnecting, though it
should not actually be necessary.

=head2 Logged Databases

Previously, there were some big distinctions between Logged and MODE
ANSI databases.
One major advantage of the changes is that there is now essentially no
distinction between the two.

Note that executing BEGIN WORK does not buy you anything; you have to
switch AutoCommit mode explicitly to get any useful results.

=head2 UnLogged Databases

The transaction state is No-TX and AutoCommit is On, and this cannot
be changed.
Any attempt to set AutoCommit to Off generates a non-fatal warning but
the program will continue; setting it to On generates neither a
warning nor an error.
Both $dbh->commit and $dbh->rollback succeed but do nothing.
Executing any Group 3B or 3C statement will generate an error.

Ideally, if you attempt to connect to an UnLogged database with
AutoCommit Off, you would get a connect failure.
There are problems implementing this because of the way DBI 0.85
behaves when failures occur, so this is not actually implemented.

=head1 ATTRIBUTE NAME CHANGES

In early releases of DBD::Informix, some of the Informix-specific
attributes had names which did not start 'ix_', but these old-style
attribute names are no longer recognised and an error message is
generated (by DBI).

Unrecognized attributes starting with 'ix_' will generate a warning
message.

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

If you use a 6.00 (or, maybe, 7.20) or later version of Informix
ESQL/C and do not have both the environment variables CLIENT_LOCALE
and DB_LOCALE set, then ESQL/C may set one or both of them during the
connect operation.
When it does so, it makes Perl emit a "Bad free()" error if you
subsequently modify the %ENV hash in the Perl script.
This is nasty, but there is no easy solution.
If you need to establish what values you should set, arrange for the
compilation to define DBD_IX_DEBUG_ENVIRONMENT is defined; the code
in dbdimp.ec will then call the function dbd_ix_printenv() in
dbd_ix_db_login() which will help you identify what has been changed.

=item *

Blobs cannot yet be updated by DBD::Informix (mainly because ESQL/C does
not readily provide the information needed for updating blobs).

=back

=head1 AUTHOR

At various times:

=over 2

=item *
Tim Bunce (Tim.Bunce@ig.co.uk)

=item *
Alligator Descartes (descarte@hermetica.com) # Obsolete email address

=item *
Alligator Descartes (descarte@arcana.co.uk) # Obsolete email address

=item *
Alligator Descartes (descarte@symbolstone.org)

=item *
Jonathan Leffler (johnl@informix.com) # Obsolete email address

=item *
Jonathan Leffler (jleffler@visa.com) # Obsolete email address

=item *
Jonathan Leffler (j.leffler@acm.org)

=item *
Jonathan Leffler (jleffler@informix.com)

=back

With contributions from many other people who should all be mentioned in the
ChangeLog file.

=head1 SEE ALSO

perl(1), perldoc for DBI.

=cut
