#!/usr/bin/perl -w
#
# DBD::Informix Example 1 - fetchall_arrayref
#
# @(#)$Id: x01fetchall.pl,v 61.1 1998/10/27 19:14:59 jleffler Exp $
#
# Jonathan Leffler (j.leffler@acm.org)

use DBI;
$dbh = DBI->connect("DBI:Informix:stores7");
$sth = $dbh->prepare(q%SELECT Fname, Lname, Phone FROM Customer WHERE Customer_num > ?%);
$sth->execute(106);
$ref = $sth->fetchall_arrayref();
for $row (@$ref)
{
	print "Name: $$row[0] $$row[1], Phone: $$row[2]\n";
}
$dbh->disconnect;
