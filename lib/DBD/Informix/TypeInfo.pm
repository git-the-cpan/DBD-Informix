#   @(#)$Id: TypeInfo.pm,v 2003.4 2003/03/22 00:40:43 jleffler Exp $
#
#   @(#)DBD::Informix::TypeInfo
#
#   Derived using a version of DBI::DBD::TypeInfo::write_typeinfo (for
#   DBI v1.33 and a modified version of DBD::ODBC 1.01 compiled to use
#   the Informix CLI (ODBC) v3.81.0000 driver distributed with ClientSDK
#   2.80.UC1 on Solaris 7.
#
#   Copyright 2002 IBM
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#-------------------------------------------------------------------------
# Code and explanations follow for DBD::Informix
# (IBM Informix Database Driver for Perl DBI Version 2005.01 (2005-03-14))
#-------------------------------------------------------------------------

# The %type_info_all hash was automatically generated by
# DBI::DBD::TypeInfo::write_typeinfo v1.00.

package DBD::Informix::TypeInfo;

{
    require Exporter;
    require DynaLoader;
    @ISA = qw(Exporter DynaLoader);
    @EXPORT = qw(type_info_all);
    use DBI qw(:sql_types);

	my
	$VERSION = "2005.01";
	$VERSION = "2003.00" if $VERSION =~ m/[:]VERSION[:]/;

    # our $type_info_all = [ # Except 'our' is not acceptable to Perl 5.005_03
    $type_info_all = [
        {
            TYPE_NAME          =>  0,
            DATA_TYPE          =>  1,
            COLUMN_SIZE        =>  2,
            LITERAL_PREFIX     =>  3,
            LITERAL_SUFFIX     =>  4,
            CREATE_PARAMS      =>  5,
            NULLABLE           =>  6,
            CASE_SENSITIVE     =>  7,
            SEARCHABLE         =>  8,
            UNSIGNED_ATTRIBUTE =>  9,
            FIXED_PREC_SCALE   => 10,
            AUTO_UNIQUE_VALUE  => 11,
            LOCAL_TYPE_NAME    => 12,
            MINIMUM_SCALE      => 13,
            MAXIMUM_SCALE      => 14,
            SQL_DATA_TYPE      => 15,
            SQL_DATETIME_SUB   => 16,
            NUM_PREC_RADIX     => 17,
            INTERVAL_PRECISION => 18,
        },
        [ "MULTISET",                            -109,                          4,          "'",    "'",   "'",               1, 0, 2, 1, 0, 0, "MULTISET",                            undef, undef, -109,              undef, undef, undef ],
        [ "SET",                                 -108,                          4,          "'",    "'",   "'",               1, 0, 2, 1, 0, 0, "SET",                                 undef, undef, -108,              undef, undef, undef ],
        [ "LIST",                                -107,                          4,          "'",    "'",   "'",               1, 0, 2, 1, 0, 0, "LIST",                                undef, undef, -107,              undef, undef, undef ],
        [ "ROW",                                 -105,                          4,          "'",    "'",   "'",               1, 0, 2, 1, 0, 0, "ROW",                                 undef, undef, -105,              undef, undef, undef ],
        [ "CLOB",                                -103,                          2147483647, undef,  undef, undef,             1, 0, 0, 1, 0, 0, "CLOB",                                undef, undef, -103,              undef, undef, undef ],
        [ "BLOB",                                -102,                          2147483647, undef,  undef, undef,             1, 0, 0, 1, 0, 0, "BLOB",                                undef, undef, -102,              undef, undef, undef ],
        [ "BOOLEAN",                             SQL_BIT,                       1,          undef,  undef, undef,             1, 0, 2, 0, 0, 0, "BOOLEAN",                             0,     0,     SQL_BIT,           undef, 2,     undef ],
        [ "INT8",                                -5,                            20,         undef,  undef, undef,             1, 0, 2, 0, 0, 0, "INT8",                                0,     0,     -5,                undef, 10,    undef ],
        [ "SERIAL8",                             -5,                            20,         undef,  undef, undef,             0, 0, 2, 0, 0, 1, "SERIAL8",                             0,     0,     -5,                undef, 10,    undef ],
        [ "BYTE",                                SQL_LONGVARBINARY,             2147483647, undef,  undef, undef,             1, 0, 0, 1, 0, 0, "BYTE",                                undef, undef, SQL_LONGVARBINARY, undef, undef, undef ],
        [ "TEXT",                                SQL_LONGVARCHAR,               2147483647, "'",    "'",   undef,             1, 0, 0, 1, 0, 0, "TEXT",                                undef, undef, SQL_LONGVARCHAR,   undef, undef, undef ],
        [ "CHAR",                                SQL_CHAR,                      32767,      "'",    "'",   "length",          1, 1, 3, 1, 0, 0, "CHAR",                                undef, undef, SQL_CHAR,          undef, undef, undef ],
        [ "DECIMAL",                             SQL_DECIMAL,                   32,         undef,  undef, "precision,scale", 1, 0, 2, 0, 0, 0, "DECIMAL",                             0,     32,    SQL_DECIMAL,       undef, 10,    undef ],
        [ "MONEY",                               SQL_DECIMAL,                   32,         undef,  undef, "precision,scale", 1, 0, 2, 0, 1, 0, "MONEY",                               0,     32,    SQL_DECIMAL,       undef, 10,    undef ],
        [ "INTEGER",                             SQL_INTEGER,                   10,         undef,  undef, undef,             1, 0, 2, 0, 0, 0, "INTEGER",                             0,     0,     SQL_INTEGER,       undef, 10,    undef ],
        [ "SERIAL",                              SQL_INTEGER,                   10,         undef,  undef, undef,             0, 0, 2, 0, 0, 1, "SERIAL",                              0,     0,     SQL_INTEGER,       undef, 10,    undef ],
        [ "SMALLINT",                            SQL_SMALLINT,                  5,          undef,  undef, undef,             1, 0, 2, 0, 0, 0, "SMALLINT",                            0,     0,     SQL_SMALLINT,      undef, 10,    undef ],
        [ "SMALLFLOAT",                          SQL_REAL,                      7,          undef,  undef, undef,             1, 0, 2, 0, 0, 0, "SMALLFLOAT",                          undef, undef, SQL_REAL,          undef, 10,    undef ],
        [ "FLOAT",                               SQL_DOUBLE,                    15,         undef,  undef, undef,             1, 0, 2, 0, 0, 0, "FLOAT",                               undef, undef, SQL_DOUBLE,        undef, 10,    undef ],
        [ "VARCHAR",                             SQL_VARCHAR,                   255,        "'",    "'",   "max,length",      1, 1, 3, 1, 0, 0, "VARCHAR",                             undef, undef, SQL_VARCHAR,       undef, undef, undef ],
        [ "LVARCHAR",                            SQL_VARCHAR,                   2048,       "'",    "'",   undef,             1, 1, 3, 1, 0, 0, "LVARCHAR",                            undef, undef, SQL_VARCHAR,       undef, undef, undef ],
        [ "DATE",                                SQL_TYPE_DATE,                 10,         "DATETIME(",  ") YEAR TO DAY",  undef,             1, 0, 2, 1, 0, 0, "DATE",                                undef, undef, SQL_DATE,          1,     undef, undef ],
        [ "DATETIME HOUR TO SECOND",             SQL_TYPE_TIME,                 8,          "'",    "'",   undef,             1, 0, 2, 1, 0, 0, "DATETIME HOUR TO SECOND",             0,     0,     SQL_DATE,          2,     undef, undef ],
        [ "DATETIME YEAR TO FRACTION(5)",        SQL_TYPE_TIMESTAMP,            25,         "'",    "'",   undef,             1, 0, 2, 1, 0, 0, "DATETIME YEAR TO FRACTION(5)",        5,     5,     SQL_DATE,          3,     undef, undef ],
        [ "INTERVAL YEAR(%d) TO YEAR",           SQL_INTERVAL_YEAR,             9,          "'",    "'",   "precision",       1, 0, 2, 0, 0, 0, "INTERVAL YEAR(%d) TO YEAR",           0,     0,     SQL_TIME,          1,     undef, 9     ],
        [ "INTERVAL MONTH(%d) TO MONTH",         SQL_INTERVAL_MONTH,            9,          "'",    "'",   "precision",       1, 0, 2, 0, 0, 0, "INTERVAL MONTH(%d) TO MONTH",         0,     0,     SQL_TIME,          2,     undef, 9     ],
        [ "INTERVAL DAY(%d) TO DAY",             SQL_INTERVAL_DAY,              9,          "'",    "'",   "precision",       1, 0, 2, 0, 0, 0, "INTERVAL DAY(%d) TO DAY",             0,     0,     SQL_TIME,          3,     undef, 9     ],
        [ "INTERVAL HOUR(%d) TO HOUR",           SQL_INTERVAL_HOUR,             9,          "'",    "'",   "precision",       1, 0, 2, 0, 0, 0, "INTERVAL HOUR(%d) TO HOUR",           0,     0,     SQL_TIME,          4,     undef, 9     ],
        [ "INTERVAL MINUTE(%d) TO MINUTE",       SQL_INTERVAL_MINUTE,           9,          "'",    "'",   "precision",       1, 0, 2, 0, 0, 0, "INTERVAL MINUTE(%d) TO MINUTE",       0,     0,     SQL_TIME,          5,     undef, 9     ],
        [ "INTERVAL SECOND(%d) TO SECOND",       SQL_INTERVAL_SECOND,           9,          "'",    "'",   "precision",       1, 0, 2, 0, 0, 0, "INTERVAL SECOND(%d) TO SECOND",       0,     0,     SQL_TIME,          6,     undef, 9     ],
        [ "INTERVAL SECOND(%d) TO FRACTION(%d)", SQL_INTERVAL_SECOND,           15,         "'",    "'",   "precision",       1, 0, 2, 0, 0, 0, "INTERVAL SECOND(%d) TO FRACTION(%d)", 5,     5,     SQL_TIME,          6,     undef, 9     ],
        [ "INTERVAL FRACTION TO FRACTION(%d)",   SQL_INTERVAL_SECOND,           6,          "'",    "'",   "precision",       1, 0, 2, 0, 0, 0, "INTERVAL FRACTION TO FRACTION(%d)",   5,     5,     SQL_TIME,          6,     undef, 0     ],
        [ "INTERVAL YEAR(%d) TO MONTH",          SQL_INTERVAL_YEAR_TO_MONTH,    12,         "'",    "'",   "precision",       1, 0, 2, 0, 0, 0, "INTERVAL YEAR(%d) TO MONTH",          0,     0,     SQL_TIME,          7,     undef, 9     ],
        [ "INTERVAL DAY(%d) TO HOUR",            SQL_INTERVAL_DAY_TO_HOUR,      12,         "'",    "'",   "precision",       1, 0, 2, 0, 0, 0, "INTERVAL DAY(%d) TO HOUR",            0,     0,     SQL_TIME,          8,     undef, 9     ],
        [ "INTERVAL DAY(%d) TO MINUTE",          SQL_INTERVAL_DAY_TO_MINUTE,    15,         "'",    "'",   "precision",       1, 0, 2, 0, 0, 0, "INTERVAL DAY(%d) TO MINUTE",          0,     0,     SQL_TIME,          9,     undef, 9     ],
        [ "INTERVAL DAY(%d) TO SECOND",          SQL_INTERVAL_DAY_TO_SECOND,    18,         "'",    "'",   "precision",       1, 0, 2, 0, 0, 0, "INTERVAL DAY(%d) TO SECOND",          0,     0,     SQL_TIME,          10,    undef, 9     ],
        [ "INTERVAL DAY(%d) TO FRACTION(%d)",    SQL_INTERVAL_DAY_TO_SECOND,    24,         "'",    "'",   "precision",       1, 0, 2, 0, 0, 0, "INTERVAL DAY(%d) TO FRACTION(%d)",    5,     5,     SQL_TIME,          10,    undef, 9     ],
        [ "INTERVAL HOUR(%d) TO MINUTE",         SQL_INTERVAL_HOUR_TO_MINUTE,   12,         "'",    "'",   "precision",       1, 0, 2, 0, 0, 0, "INTERVAL HOUR(%d) TO MINUTE",         0,     0,     SQL_TIME,          11,    undef, 9     ],
        [ "INTERVAL HOUR(%d) TO SECOND",         SQL_INTERVAL_HOUR_TO_SECOND,   15,         "'",    "'",   "precision",       1, 0, 2, 0, 0, 0, "INTERVAL HOUR(%d) TO SECOND",         0,     0,     SQL_TIME,          12,    undef, 9     ],
        [ "INTERVAL HOUR(%d) TO FRACTION(%d)",   SQL_INTERVAL_HOUR_TO_SECOND,   21,         "'",    "'",   "precision",       1, 0, 2, 0, 0, 0, "INTERVAL HOUR(%d) TO FRACTION(%d)",   5,     5,     SQL_TIME,          12,    undef, 9     ],
        [ "INTERVAL MINUTE(%d) TO SECOND",       SQL_INTERVAL_MINUTE_TO_SECOND, 12,         "'",    "'",   "precision",       1, 0, 2, 0, 0, 0, "INTERVAL MINUTE(%d) TO SECOND",       0,     0,     SQL_TIME,          13,    undef, 9     ],
        [ "INTERVAL MINUTE(%d) TO FRACTION(%d)", SQL_INTERVAL_MINUTE_TO_SECOND, 18,         "'",    "'",   "precision",       1, 0, 2, 0, 0, 0, "INTERVAL MINUTE(%d) TO FRACTION(%d)", 5,     5,     SQL_TIME,          13,    undef, 9     ],
    ];

    1;
}

__END__

=head1 NAME

DBD::Informix::TypeInfo - Repository for type_info_all data

=head1 SYNOPSIS

require DBD::Informix::TypeInfo;

=head1 DESCRIPTION

This file is only loaded when needed, which is when the type_info_all or
type_info methods are invoked.
It contains and exports only a single hash with the correct
initializations for Informix.

Note that this was generated with a prototype of the
DBI::DBD::TypeInfo::write_typeinfo method.
The data for DATE, TIME, TIMESTAMP was amended slightly.

=head1 SEE ALSO

DBI

DBD::Informix

=head1 AUTHOR

Jonathan Leffler E<lt>jleffler@us.ibm.comE<gt>

=cut
