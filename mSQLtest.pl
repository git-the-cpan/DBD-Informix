#!/usr/bin/perl -w
#
# test2.pl: Written by Alligator Descartes <descarte@mcqueen.com>
#
# Modification History:
# By:		Date:		Description:
#

use DBI;

my( $driver ) = 'mSQL';
$drh = DBI->install_driver( $driver );

DBI->internal->{DebugDispatch} = 0;
#DBI->internal->debug(2);

$dbhost = 'fruitbat';
$dbname = 'Test';

$ENV{MINERVA_DEBUG}= 'error';

print "** Connecting to first instance....\n";

$dbh =
    $drh->connect( $dbhost, $dbname );

print "** Disconnecting from first instance....\n";

$dbh->disconnect;

print "** Connecting to second instance.....\n";

$dbh =
    $drh->connect( $dbhost, $dbname );

print "**** Trying cursor returning rows as list.....\n";

$sth =
    $dbh->prepare( "SELECT * FROM pants2" );
die "Cannot prepare sth ($DBI::err): $DBI::errstr\n"
    unless $sth;

$sth->execute || die "Cannot execute sth ($DBI::err): $DBI::errstr\n";

while ( ( @kak ) = $sth->fetchrow ) {
    print "     ReturnRow: @kak\n";
  }

$sth->finish;

print "**** Re-doing the cursor but fetching fields separately.....\n";

$sth = 
    $dbh->prepare ( "SELECT * from pants2" );
die "Cannot prepare sth ($DBI::err): $DBI::errstr\n"
    unless $sth;

$sth->execute;

while ( ( $id, $name ) = $sth->fetchrow ) {
    print "     Id: $id\tName: $name\n";
  }

$sth->finish;

print "**** Trying an INSERT now.......\n";

$sth =
    $dbh->prepare( "INSERT INTO pants2 VALUES ( 3, 'Rubbish Guy1' )" );
die "Cannot prepare sth ($DBI::err): $DBI::errstr\n"
    unless $sth;

$sth->execute;

$sth->finish;

print "**** Re-doing the cursor but fetching fields separately.....\n";

$sth =
    $dbh->prepare ( "SELECT * from pants2" );
die "Cannot prepare sth ($DBI::err): $DBI::errstr\n"
    unless $sth;

$sth->execute;

while ( ( $id, $name ) = $sth->fetchrow ) {
    print "     Id: $id\tName: $name\n";
  }

$sth->finish;

print "**** Trying a CREATE statement......\n";

$sth =
    $dbh->prepare( "CREATE TABLE pants3 ( id int, name char(64) )" );
die "Cannot prepare sth ($DBI::err): $DBI::errstr\n"
    if !defined $sth;

$sth->execute if $sth;

$sth->finish if $sth;

print "**** Inserting some rows.....\n";

$sth =
    $dbh->prepare( "INSERT INTO pants3 VALUES ( 1, 'Rubbish' )" );
die "Cannot prepare sth ($DBI::err): $DBI::errstr\n"
    unless $sth;

$sth->execute;

$sth->finish;

print "**** Re-doing the cursor but fetching fields separately.....\n";

$sth =
    $dbh->prepare ( "SELECT * from pants3" );
die "Cannot prepare sth ($DBI::err): $DBI::errstr\n"
    unless $sth;

$sth->execute;

while ( ( $id, $name ) = $sth->fetchrow ) {
    print "     Id: $id\tName: $name\n";
  }

$sth->finish;

print "** Disconnecting from second instance....\n";

$dbh->disconnect;
