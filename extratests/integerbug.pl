#!/usr/bin/perl -w
#
# (c)1996 Hermetica. Written by Alligator Descartes <descarte@hermetica.com>
#
# To use:
#
# 1) Create a table called 'test' with 1 field called 'id' of type INTEGER
# 2) Insert some test data, preferably longer than 4 digits
# 3) Change the connect string to suit

use DBI;

$drh = DBI->install_driver( 'Informix' ) || die "Cannot load driver: $!\n";
$dbh = $drh->connect( 'dbhost', 'test', 'blah', 'blah' );
if ( !defined $dbh ) {
    die "Cannot connect to database: $DBI::errstr\n";
  }

$sth = $dbh->prepare( "
    SELECT id
    FROM test" );
if ( !defined $sth ) {
    die "Cannot prepare sth: $DBI::errstr\n":
  }

$sth->execute;

while ( ( $id ) = $sth->fetchrow ) {
    print "Row: $id\n";
  }

$sth->finish;
undef $sth;

$dbh->disconnect;

exit;
