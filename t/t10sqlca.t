#!/usr/bin/perl -w
#
#	@(#)$Id: t10sqlca.t,v 100.3 2002/02/08 22:50:36 jleffler Exp $ 
#
#	Test SQLCA Record Handling for DBD::Informix
#
#	Copyright 1997,1999 Jonathan Leffler
#	Copyright 2000      Informix Software Inc
#	Copyright 2002      IBM

use DBD::Informix::TestHarness;

# Test install...
$dbh = &connect_to_test_database();
print_sqlca($dbh);

&stmt_note("1..7\n");
&stmt_ok();
$table = "dbd_ix_sqlca";

# Create table for testing
stmt_test $dbh, qq{
CREATE TEMP TABLE $table
(
	Col01	SERIAL(1000) NOT NULL,
	Col02	CHAR(20) NOT NULL,
	Col03	DATE NOT NULL,
	Col04	DATETIME YEAR TO FRACTION(5) NOT NULL,
	Col05   DECIMAL NOT NULL
)
};
print_sqlca($dbh);

# Insert a row of nulls.
stmt_test $dbh, qq{
INSERT INTO $table VALUES(0, 'Some Value', TODAY, CURRENT, 3.14159)
};

print_sqlca($dbh);

$select = "SELECT * FROM $table";

# Check that there is now one row of data
select_some_data $dbh, 1, $select;

# Insert a row of values.
$sth = $dbh->prepare("INSERT INTO $table VALUES(0, ?, ?, ?, ?)");
&stmt_fail() unless $sth;
&stmt_ok;
print_sqlca $sth;
&stmt_fail() unless $sth->execute('Another value', 'today', '1997-02-28 00:11:22.55555', 2.8128);
&stmt_ok;
print_sqlca $sth;

# Check that there are now two rows of data
select_some_data $dbh, 2, $select;

&all_ok();
