#!/usr/bin/perl -w
#
# DBD::Informix Example 2 - fetchrow_array
#
# @(#)$Id: x02fetchrow_array.pl,v 61.1 1998/10/27 19:14:59 jleffler Exp $
#
# Jonathan Leffler (j.leffler@acm.org)

use DBI;
printf("DEMO1 Sample DBD::Informix Program running.\n");
printf("Variant 1: using fetchrow_array()\n");
my($dbh) = DBI->connect("DBI:Informix:stores7") or die;
my($sth) = $dbh->prepare(q%
	SELECT fname, lname FROM customer WHERE lname < 'C'%) or die;
$sth->execute() or die;
my(@row);
while (@row = $sth->fetchrow_array())
{
  printf("%s %s\n", $row[0], $row[1]);
}
undef $sth;
$dbh->disconnect();
printf("\nDEMO1 Sample Program over.\n\n");

