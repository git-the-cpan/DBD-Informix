#!/usr/bin/perl -w
#
# DBD::Informix Example 2 - fetchrow_array
#
# @(#)$Id: x07fetchrow_array.pl,v 61.1 1998/10/29 18:11:26 jleffler Exp $
#
# Jonathan Leffler (j.leffler@acm.org)

use DBI;
printf("DEMO1 Sample DBD::Informix Program running.\n");
printf("Variant 5: using fetchrow_array() into variable list\n");
my($dbh) = DBI->connect("DBI:Informix:stores7") or die;
my($sth) = $dbh->prepare(q%
	SELECT fname, lname FROM customer WHERE lname < 'C'%) or die;
$sth->execute() or die;
my($fname, $lname);
while (($fname, $lname) = $sth->fetchrow_array())
{
  printf("%s %s\n", $fname, $lname);
}
undef $sth;
$dbh->disconnect();
printf("\nDEMO1 Sample Program over.\n\n");

