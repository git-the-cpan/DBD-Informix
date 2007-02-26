#!/bin/perl -w
#
# @(#)$Id: t98pod.t,v 2003.2 2007/02/25 19:33:33 jleffler Exp $
#
# Check the POD files for DBD::Informix

use Test::Pod tests => 10;

my $prefix = "./blib/lib";

my @podlist = (
	"Bundle/DBD/Informix.pm",
	"DBD/Informix.pm",
	"DBD/Informix/Configure.pm",
	"DBD/Informix/Defaults.pm",
	"DBD/Informix/GetInfo.pm",
	"DBD/Informix/Metadata.pm",
	"DBD/Informix/Summary.pm",
	"DBD/Informix/TechSupport.pm",
	"DBD/Informix/TestHarness.pm",
	"DBD/Informix/TypeInfo.pm"
);

foreach $name (@podlist)
{
	my $file = "$prefix/$name";
	my $test = $name;
	$test =~ s%/%::%go;
	$test =~ s%\.pm$%%o;
	pod_file_ok($file, "POD for $test");
}
