#!/usr/bin/perl -sw
#
# @(#)$Id: Makefile.PL,v 2003.6 2003/03/04 18:51:14 jleffler Exp $
#
# Configuration script for DBD::Informix
# (IBM Informix Database Driver for Perl Version 2003.04 (2003-03-05))
#
# Copyright 1996-99 Jonathan Leffler
# Copyright 1996    Alligator Descartes
# Copyright 2000    Informix Software Inc
# Copyright 2002-03 IBM
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the Perl README file.

#TABSTOP=4

########################
### AUTOINSTALL CODE ###
########################

# If the ExtUtils::AutoInstall code causes you angst, place comment
# markers at the start of the lines between each pair of lines marked
# with #-HERE-# and #-AND-HERE-#
# In vi:  :g/^#-HERE-#$/.+1,/#-AND-HERE#$/-1s/^/#-EU-AI-#/

#-HERE-#
# ExtUtils::AutoInstall Bootstrap Code, version 5.
BEGIN{my$p='ExtUtils::AutoInstall';my$v=0.40;eval"use $p $v;1
"or do{my$e=$ENV{PERL_EXTUTILS_AUTOINSTALL};(!defined($e)||$e
!~m/--(?:default|skip|testonly)/and-t STDIN or eval"use Ext".
"Utils::MakeMaker;WriteMakefile('PREREQ_PM'=>{'$p',$v});1"and
exit)and print"==> $p $v required. Install it from CPAN? [Y".
"/n] "and<STDIN>!~/^n/i and print"*** Installing $p\n"and do{
eval{require CPANPLUS;CPANPLUS::install $p};eval"use $p $v;1"
or eval{require CPAN;CPAN::install$p};eval"use $p $v;1"or die
"*** Please install $p $v manually from cpan.org first.\n"}}}
#-AND-HERE-#

# postamble handler; generates a string to be appended to Makefile.
# DBI::DBD::dbd_postamble() returns standardised code to generate
# Informix.xs from Informix.xsi and the template from DBI (Driver.xst).
# dbd_informix_postamble() does a similar job for ESQL/C.
sub MY::postamble
{
#-HERE-#
    return &ExtUtils::AutoInstall::postamble .
#-AND-HERE-#
           &DBI::DBD::dbd_postamble .
           &dbd_informix_postamble;
}

#-HERE-#
# The MY::postamble handler must be defined before this BEGIN block.
BEGIN
{
	require ExtUtils::AutoInstall;
	# Pre-install the DBI module.
	ExtUtils::AutoInstall->install([], 'DBI' => '1.33');
}
use DBI 1.33;

ExtUtils::AutoInstall->import(
	-version        => '0.43',
	-config         => {
		make_args   => '--hello',   # Suppress hello message from CPAN
	},
	-core           => [
		'DBI'         => '1.33',    # DBI version 1.30 or later would do
	],
	'High Resolution Timing' => [
		-default      => 1,         # Install Time::HiRes by default
		-tests        => [ "t/t66insert.t" ],	# Disable this test if no Time::HiRes
		'Time::HiRes' => '',
	],
);
#-AND-HERE-#

###############################
### END OF AUTOINSTALL CODE ###
###############################

# A sufficiently recent version of Perl and DBI must be installed before we
# can build the DBD module.  The code in DBD::Informix needs the features
# present in Perl 5.005 and DBI 1.33.
use 5.005;
use strict;
use Config;
use lib 'lib';
use ExtUtils::MakeMaker;    # Only needed if ExtUtils::AutoInstall is disabled
use DBI 1.33;               # Only needed if ExtUtils::AutoInstall is disabled
use DBI::DBD;               # dbd_postamble()
use DBD::Informix::Configure;

$| = 1;     # Ensure that Perl output is interleaved with test output.

# Configure for Unix vs Windows 95/NT
my $objext = $Config{obj_ext};
my $split = $Config{path_sep};
my $NTConfiguration = $Config{archname} =~ /MSWin32/;

if ($NTConfiguration)
{
	# NT configuration...
	print &nlt(q{
	This is a semi-experimental version of Makefile.PL with Win32 (NT)
	support.  Previous versions have been tested on NT, but there could
	still be bugs in this code.  Please help save the world by trying
	to debug the NT code and reporting the results back to the DBI
	Users mailing list.

	Thanks!

	});
}

my $dbd_ix = "2003.04";
# Hack for handling builds directly in Atria Clearcase view.
$dbd_ix = "2003.00.0000" unless $dbd_ix =~ /^\d+\.\d+/;

my $dbd_ix_pm_dir = "lib/DBD/Informix";

my %opts = (
	NAME         => 'DBD::Informix',
	VERSION      => "$dbd_ix",
	EXE_FILES    => [ 'InformixTechSupport' ],
	clean        => { FILES        => "Informix.xsi esqlinfo.h esqlvrsn.h t/decgen.sql t/dtgen.sql $dbd_ix_pm_dir/Defaults.pm" },
	realclean    => { FILES        => 'esql' },
	dist         => { DIST_DEFAULT => 'clean distcheck disttest tardist',
					  PREOP        => '$(MAKE) -f Makefile.old distdir',
					  COMPRESS     => 'gzip -v9',
					  SUFFIX       => 'gz'
					},
	'PREREQ_PM'  =>	{ 'DBI' => 1.33,
					  'Time::HiRes' => 0
					},
	'PM'         =>	{
					  'Informix.pm'                   => '$(INST_LIBDIR)/Informix.pm',
					  "$dbd_ix_pm_dir/Configure.pm"   => '$(INST_LIBDIR)/Informix/Configure.pm',
					  "$dbd_ix_pm_dir/Defaults.pm"    => '$(INST_LIBDIR)/Informix/Defaults.pm',
					  "$dbd_ix_pm_dir/GetInfo.pm"     => '$(INST_LIBDIR)/Informix/GetInfo.pm',
					  "$dbd_ix_pm_dir/Metadata.pm"    => '$(INST_LIBDIR)/Informix/Metadata.pm',
					  "$dbd_ix_pm_dir/Summary.pm"     => '$(INST_LIBDIR)/Informix/Summary.pm',
					  "$dbd_ix_pm_dir/TechSupport.pm" => '$(INST_LIBDIR)/Informix/TechSupport.pm',
					  "$dbd_ix_pm_dir/TestHarness.pm" => '$(INST_LIBDIR)/Informix/TestHarness.pm',
					  "$dbd_ix_pm_dir/TypeInfo.pm"    => '$(INST_LIBDIR)/Informix/TypeInfo.pm',
					  "lib/Bundle/DBD/Informix.pm"    => 'blib/lib/Bundle/DBD/Informix.pm',
					}
		   );

print qq%
Configuring IBM Informix Database Driver for Perl Version 2003.04 (2003-03-05) (aka $opts{NAME})
        You are using DBI version $DBI::VERSION and Perl version $]
Remember to actually read the README file!

%;

# log key platform information to help me help you quickly
print "Perl:     perl$] @Config{qw(archname dlsrc)}\n";
print "System:   @Config{qw(myuname)}\n";
my @compiler = map { defined $_ ? $_ : "" } @Config{qw(cc optimize ccflags)};
print "Compiler: @compiler\n";
print "Loader:   $Config{ld}\n"
	if ($Config{ld} !~ /cc$/ && $Config{ld} ne $Config{cc});

# Sometimes the 'use' commands above enforce the same restriction as
# these two lines below.
&did_not_read("Perl is out of date") unless ($] >= 5.005);
&did_not_read("DBI is out of date") unless ($DBI::VERSION >= 1.33);

# Assorted hints - these should be move to a hints subdirectory.
print "\nSee notes about SPARCompiler on Solaris in Notes/solaris\n"
	if ($Config{osname} eq 'solaris' and &which($Config{cc}) =~ m%/SUNWspro/%);
print "\n";

# Compare installed version of DBI with version which DBD::Informix was
# last tested with.
# The required and reference versions are the same for this release.
my $dbi_ref_ver = "1.13";
warn "*** Ideally, you should upgrade to DBI version $dbi_ref_ver.\n\n"
	unless ($DBI::VERSION >= $dbi_ref_ver);

my ($ID, $esqlprog) = &find_informixdir_and_esql($NTConfiguration);
my ($epp) = "$ID/bin/$esqlprog";

my $auxincl = "";
$auxincl = " -I$ID/incl/tools" if ($esqlprog =~ /\bc4gl\b/);

my ($infversion, $vernum) = &get_esqlc_version($esqlprog);
print "Using $infversion from $ID\n";

# --- Check whether Informix is installed OK for us.
my $warning = qq{
Beware: $opts{NAME} is not yet aware of all the new IUS data types.

};

# NB: If using ESQL/C 4.xy, use -I$ID/incl, not -I$ID/incl/esql!
# However, you've got other major work to do to handle 4.xy ESQL/C.
# Also, it appears that NT ESQL/C 5.x used -I$ID/incl, too.
my $INC1 = "-I$ID/incl/esql$auxincl";

my $esql = "$esqlprog";
my $esqlc_flags = "";
my $vercode = "esqlc_v6";
my $multiconn = 1;
if ($vernum < 100)
{
	die &nlt(qq{
	The ESQL/C version information found was: <<$infversion>>
	$opts{NAME} failed to find a version number ($vernum).
	Please report this to the $opts{NAME} maintenance team.
	});
}
elsif ($vernum >= 100 && $vernum < 500)
{
	die &nlt(qq{
	$infversion does not support string-named cursors.
	This version of $opts{NAME} requires this facility.
	There are no longer any plans to back-port $opts{NAME}
	to such old and obsolete versions of ESQL/C.
	Please investigate upgrading your software.
	If all else fails, try installing DBD::Informix4 instead.
	});
}
elsif ($vernum >= 500 && $vernum < 510)
{
	die &nlt(qq%
			This version of ESQL/C ($infversion) is obsolete.
			It is also not considered Y2K-safe by Informix.
			Please upgrade to ESQL/C version 5.10 or later.
			%);
}
elsif ($vernum >= 510 && $vernum < 600)
{
	$vercode = "esqlc_v5";
	$multiconn = 0;
	if ($NTConfiguration)
	{
		# NT configuration
		# We have to assume that ESQL/C will use the correct C compiler
		$opts{DEFINE} .= " -DWINNT -Dfar=";
		$INC1 = "-I$ID/incl";
	}
	else
	{
		# Unix configuration
		print &nlt(qq%
			You need to use a customized ESQL/C compiler script
			which recognizes the INFORMIXC environment variable.
			I will create a local version and ensure that we use it.\n
			%);
		$esql = "./esql";
		&customize_esql($epp, $esql, $opts{NAME});
	}
	print &nlt(qq%
		You may run into problems creating a shared object version of
		$opts{NAME}.  If so, try creating a statically linked version
		instead.  Read the Notes/static.build file.\n
		%);
}
elsif ($vernum >= 600 && $vernum < 724)
{
	die &nlt(qq%
			This version of ESQL/C ($infversion) is obsolete.
			Please upgrade to ESQL/C version 7.24 or ClientSDK.
			%);
}
elsif ($vernum >= 724 && $vernum < 800)
{
	# 7.2x is already released.  There should not be an ESQL/C version
	# 7.3x.  The 7.3x server is Informix Dynamic Server, IDS.  You use
	# ClientSDK 2.x to access IDS, and the ESQL/C version numbers for
	# ClientSDK are currently 9.xy numbers, not 7.3x (see below).
	# Note that the IUS tests take into account both the version of
	# ESQL/C and the version of the database engine you are using
	# before trying to run any IUS data type testing.
	# Set $esqlc_flags to try and ensure shared library linking.
	# Officially, the default should be shared library linking, but
	# by report, some versions have reverted to static linking as the
	# default.  Use the -shared flag to force shared library linking.
	# Provide DBD_INFORMIX_ESQLC_LINKAGE to override the default.
	# NB: Informix 4GL is regarded as having ESQL/C version 731.
	my $esql = (defined $ENV{ESQL}) ? $ENV{ESQL} : "esql";
	if ($esql =~ m%(.*/)?c4gl$%)
	{
		warn &nlt(qq%
				This version of Informix 4GL should be upgraded to version 7.32 or later.
		%) if ($vernum < 730);
		warn &nlt(qq%
			$opts{NAME} will not support builds with Informix 4GL in the future.
			%);
	}
	$esqlc_flags .= &set_esqlc_linkage("-shared", $NTConfiguration);
	&fix_b102265($epp, $esql, $opts{NAME})
		if ($Config{osname} eq "hpux" && &grep_for_statopt_staticonly($epp));
}
elsif ($vernum >= 800 && $vernum < 900)
{
	# Informix XPS.  Versions 8.00 through 8.2x probably use ESQL/C 8.xy.
	# Starting with XPS version 8.30, you are expected to use ClientSDK,
	# normally.  We finally have some feedback from a real user (Robert E
	# Wyrick <rob@wyrick.org>), so we can say we support 8.x at last.
	warn &nlt(qq%
		$opts{NAME} is still learning about XPS, so please report
		your experience installing $opts{NAME} with XPS.  Thanks!
		This version of ESQL/C will not be supported in the future.
		%);
	$esqlc_flags .= &set_esqlc_linkage("-shared", $NTConfiguration);
}
elsif ($vernum >= 900 && $vernum < 916)
{
	# ESQL/C 9.0x and 9.10 or 9.11 were pre-releases of the ESQL/C for
	# the Informix Universal Server (IUS) - since renamed several times.
	# ESQL/C 9.12 was released as ESQL/C 9.12.
	# ESQL/C 9.13 was released as DevSDK 2.00
	# ESQL/C 9.14 was released as ClientSDK 2.01
	# ESQL/C 9.15 was released as ClientSDK 2.02
	# All of these are long obsolete and are no longer supported.
	die &nlt(qq%
			This version of ESQL/C ($infversion) is obsolete.
			Please upgrade to ClientSDK version 2.70 or later.
			%);
}
elsif ($vernum >= 916 && $vernum < 1000)
{
	# ESQL/C 9.16 was released as ClientSDK 2.10
	# ESQL/C 9.20 was released as ClientSDK 2.20
	# ESQL/C 9.21 was released as ClientSDK 2.30
	# ESQL/C 9.30 was released as ClientSDK 2.40
	# ESQL/C 9.40 was released as ClientSDK 2.50
	# ESQL/C 9.50 was released as ClientSDK 2.60
	# ESQL/C 9.51 was released as ClientSDK 2.70
	# ESQL/C 9.52 was released as ClientSDK 2.80
	print &nlt(qq%
			The tests in t/t31nulls.t and t/t32nulls.t will probably fail.
		%) if ($vernum == 914);
	print &nlt(qq%
			Please upgrade to a more recent version of ClientSDK.
		%) if ($vernum < 940);
	print $warning;
	$esqlc_flags .= &set_esqlc_linkage("-shared", $NTConfiguration);
}
else
{
	die &nlt(qq{
	$opts{NAME} does not know anything about $infversion.
	Please report this to the $opts{NAME} maintenance team.
	However, there is a fair chance that $opts{NAME} will work if
	you modify the code in Makefile.PL which contains this message
	to recognize your version.

	Since you appear to have 10.0x or later, there is likely to be a lot
	of functionality in the database which $opts{NAME} does not know
	how to handle, but you should try treating it like version 9.2x.
	You should modify the code in Makefile.PL to handle your version
	number correctly -- find this error message and look at the code
	above it to see what you might need to alter.

	Please report your experiences to the $opts{NAME} maintenance team.
	});
}

# -- Configure the make process

# Define the version of ESQL/C for the object code.
$opts{DEFINE} = " -DESQLC_VERSION=$vernum";

# Disable assertions by default; override by setting DBD_INFORMIX_ENABLE_ASSERT.
if (defined($ENV{DBD_INFORMIX_ENABLE_ASSERT}))
{
	$opts{DEFINE} .= " -DDBD_INFORMIX_ENABLE_ASSERT";
	print "** Warning ** assert macro is enabled!\n\n";
}
else
{
	print "Assert macro will be disabled!\n\n";
	$opts{DEFINE} .= " -DNDEBUG";
}

print "** Warning ** you will build $opts{NAME} for a relocatable INFORMIXDIR!\n\n"
	if (defined($ENV{DBD_INFORMIX_RELOCATABLE_INFORMIXDIR}));

$opts{INC} = " ";

&Write_DBD_Informix_Defaults();

# The ESQL/C script does not handle options with spaces and quotes, dammit!
# Hence, create $versionfile to contain ESQLC_VERSION_STRING.
{
my $versionfile = "esqlvrsn.h";
unlink $versionfile;
die "Unable to open $versionfile for writing\n"
	unless open(VERSION, ">$versionfile");
print VERSION "/* File $versionfile generated by $opts{NAME} $dbd_ix for $infversion */\n";
print VERSION "#define ESQLC_VERSION_STRING \"$infversion\"\n";
close VERSION or die "Failed to write $versionfile\n";
print "$versionfile written OK\n";
}

# The ESQL/C preprocessors do not handle conditional compilation
# of #ifdef blocks, so such code has to be handled with $include
# and $ifdef and so on.  Ugh!!!  Necessary for IUS support.
{
my $infofile = "esqlinfo.h";
unlink $infofile;
die "Unable to open $infofile for writing\n"
	unless open(ESQLINFO, ">$infofile");
print ESQLINFO "/* File $infofile generated by $opts{NAME} $dbd_ix for $infversion */\n";
printf ESQLINFO "%s%s IUS_DATA_TYPES;\n", '$', (($vernum >= 900) ? "define" : "undef");
printf ESQLINFO "%s%s BEGIN_WORK_WITHOUT_REPLICATION;\n", '$', (($vernum >= 914) ? "define" : "undef");
close ESQLINFO or die "Failed to write $infofile\n";
print "$infofile written OK\n\n";
}

# Add extra definitions to compile the code under GCC if DBD_INFORMIX_DEBUG_GCC set.
# Perl configuration headers contain lots of /* inside comments (-Wno-comment)
#$opts{DEFINE} .= ' -Wall -pedantic -Wno-comment -Wpointer-arith -Wcast-align'
#	    . ' -Wconversion -Wtraditional -Wcast-qual'
$opts{DEFINE} .= ' -Wall -pedantic -Wno-comment'
	if $Config{cc} eq 'gcc' and $ENV{DBD_INFORMIX_DEBUG_GCC};

# Ensure that __STDC__ is defined under CenterLine CC
$opts{DEFINE} .= ' -Xa'
	if $Config{cc} eq 'clcc';

# We need to add -Ae on HP-UX to ensure that prototypes are accepted,
# but only if using the native HP-UX compiler (GCC does not accept -Ae,
# for example).
$opts{DEFINE} .= " -Ae"
	if $Config{osname} eq "hpux" and $Config{ccflags} !~ /-A[ea]/ and
		$Config{cc} eq 'cc';

# Extra definitions under Alpha cc to get __STDC__ defined
$opts{DEFINE} .= ' -std1'
	if (($Config{cc} eq 'cc') && ($Config{osname} eq 'dec_osf'));

# Ensure that __STDC__ is defined for SUNWspro compilers on Solaris.
$opts{DEFINE} .= ' -Xa'
	if ($Config{osname} eq 'solaris' and &which($Config{cc}) =~ m%/SUNWspro/%);

# Ensure that __STDC__ is defined for cc on AIX (ie if Perl was not
# compiled with xlc); reported by Joachim Schrod <jschrod@acm.org> in
# January 1998.
$opts{DEFINE} .= ' -qlanglvl=ansi'
        if ($Config{osname} eq 'aix' and $Config{cc} eq 'cc');

# Workaround Informix bug B08223 (aka B14937, and other numbers too)
# AIX localedef31.h defines a loc_t and is used by some system headers.
# Informix locator.h also defines a loc_t.  The workaround is to prevent
# the localedef31.h declaration from being included.
$opts{DEFINE} .= " -D__H_LOCALEDEF"
	if ($Config{osname} eq 'aix');

# Some versions of the Informix headers do not generate function
# prototypes; the esqlc.h header is provided to remedy this problem.  Some
# versions of the Informix headers only generate function prototypes if
# __STDC__ is defined.  Without function prototypes, we are often passing
# pointers to _iqxyz() functions that the compiler thinks are ints.  This
# causes incorrect code to be generated on a 64-bit DEC Alpha with any
# optimization level greater than -O1.  So, if the C compiler does not
# cause Informix to use the prototypes, there could be problems.  Once upon
# a time, this code added -DUSE_PROTOTYPES to the command line, but even
# this was not reliable (some compilers refused to allow esqlc.h to set
# __STDC__ when it was not set via the command line options, for example).
# The code in esqlc.h (version 1.9 and later) handles this mess for us.
# Additionally, you can run into problems with the code generated by the
# ESQL/C compiler, which undefines const if __STDC__ is not defined (eg on
# Solaris using the SUNWspro compiler).  These may show up as some function
# prototypes being redefined with the first version having const pointers
# and the second have non-const pointers.  However, Perl 5.005 requires
# prototypes and ESQL/C is moving in that direction, and it is the correct
# direction to go.  We'll assume it will all work.

if ($Config{"prototype"} ne 'define')
{
	print &nlt(q{
		Gosh!  Perl doesn't think your compiler handles prototypes.
		Well, even though I don't believe it, we'll take Perl's word
		for it and we won't try to force them into use.  Don't you
		need to upgrade your compiler?  If you run into compilation
		problems with the test program, you will need to revisit this
		issue.
		});
}

my $objects = "Informix.o dbdimp.o dbdattr.o sqltoken.o";
$objects .= " sqltype.o ixblob.o decsci.o odbctype.o link.o esqlcver.o $vercode.o";
$objects .= " eprintf.o" if defined $ENV{DBD_INFORMIX_USE_EPRINTF_CODE};
if (defined $ENV{DBD_INFORMIX_AUXILLIARY_OBJECT_FILES})
{
	my ($list) = $ENV{DBD_INFORMIX_AUXILLIARY_OBJECT_FILES};
	$objects .= " $list";
	print 'Using auxilliary object files from $DBD_INFORMIX_AUXILLIARY_OBJECT_FILES:';
	$list =~ s/^\s+//;
	$list =~ s/\s+$//gm;
	$list =~ s/\s+/\t\n/gm;
	print "\n\t$list\n\n";
}
# Map object file names on non-Unix platforms
$objects =~ s/\.o\w/$objext/g if ($objext ne ".o");

# Need to pick up the DBI headers.  The DBI headers might be in
# $INSTALLARCHLIB rather than $INSTALLSITEARCH.  This is the case under
# Debian, according to Roderick Schertler <roderick@argon.org>, 1999-09.
# May also, or instead, need -I\$(SITEARCHEXP)/auto/DBI; this was
# reported by Joachim Schrod <jschrod@acm.org> in January 1998 on AIX.
# And on 2002-07-03, Roderick Schertler also reported that we may need
# INSTALLVENDORARCH sometimes (Debian again), and gave the join/map
# formulation without listing SITEARCHEXP.  On my Solaris 7 box with my
# build of Perl 5.8.0, INSTALLVENDORARCH is empty, and SITEARCHEXP is
# the same as INSTALLSITEARCH, but that doesn't do any harm.
my $INC2 = join ' ', map { "-I\$($_)/auto/DBI" }
			qw (INSTALLARCHLIB INSTALLSITEARCH INSTALLVENDORARCH SITEARCHEXP);

$opts{INC} .= " $INC1 $INC2";
$opts{OBJECT} = $objects;

##############################
# - Start of ESQLTEST code - #
##############################

my $unsuccessful_test = qq%
The test program esqltest compiled successfully (which is good).
However, it did not run successfully (which is bad).

If the esqltest program did not produce any output:
	This suggests that there is a problem with the ESQL/C runtime
	environment, or with the database permissions (in which case, you
	should have seen diagnostics from the esqltest program itself).
	Consider whether the shared library path environment variable (eg
	LD_LIBRARY_PATH or SHLIB_PATH) is set correctly.

If the esqltest program did produce some output:
	This suggests that you do not have enough permissions in your
	Informix environment.  You really need DBA (at least RESOURCE)
	level privileges on the database you are using.

If you might be having problems with ESQL/C, try to compile and run
the simple ESQL/C program esqlbasic.ec, which has no Perl related
code in it at all -- it is a pure ESQL/C program:

		esql -o esqlbasic esqlbasic.ec && esqlbasic

If you cannot get that to work, then the problem is with ESQL/C
and not with $opts{NAME} per se, and you need to get your ESQL/C
installation fixed so that you can compile and run the esqlbasic
program successfully.

Make sure you read the whole README file before asking the DBI/DBD
community for help!
%;

if ($ENV{DBD_INFORMIX_NO_ESQLTEST})
{
	print &nlt(qq%
		Because DBD_INFORMIX_NO_ESQLTEST is set in your environment, you
		have chosen not to run the test which verifies that your ESQL/C
		setup will allow DBD::Informix to compile and the tests to run.  If
		you run into *ANY* problems, you must verify that the esqltest
		program can be compiled and run successfully before you even think
		of asking for help.  Also make sure you read the whole README
		file before asking the DBI/DBD community for help!\n
		%);
}
else
{
	# Check that the ESQL/C program esqltest can be compiled and run OK.
	# NB: test does not need any Perl headers (but don't pollute esqlperl.h
	#     with anything that needs a Perl header).
	# Remove this code if you run into irresolvable problems with shared
	# memory connections after you've read the README.olipcshm file.
	# On Unix, it is conceivable that someone who uses C Shell (or equivalent)
	# will run into problems because of the environment setting on the command
	# line.  Possible cure: ensure that $SHELL=/bin/ksh or /bin/sh.
	# There have also been problems on HP-UX 10.20 with environment setting
	# on the command line which may affect this test and/or the main build.
	print "Testing whether your Informix test environment will work...\n";
	my ($EQ, $RM, $EX);
	if ($NTConfiguration)
	{
		$EX = ".exe";
		$EQ = $esql;
		$RM = "del /q";
	}
	else
	{
		$EX = "";
		$RM = "rm -f";
		$EQ = "INFORMIXC='$Config{perlpath} esqlcc' ESQLCC='$Config{cc}' $esql";
	}

	my $sx = $ENV{DBD_INFORMIX_DEBUG_ESQLTEST} ? 1 : 0;

	execute_command("$EQ -c $Config{ccflags} $opts{DEFINE} esqltest.ec", $sx,
					"Failed to compile esqltest.ec to esqltest$objext\n");
	execute_command("$EQ -c $Config{ccflags} $opts{DEFINE} $vercode.ec", $sx,
					"Failed to compile $vercode.ec to $vercode$objext\n");
	execute_command("$EQ -o esqltest esqltest$objext $vercode$objext", $sx,
					"Failed to link test program esqltest\n");
	execute_command("$RM esqltest$objext esqltest.c $vercode.c $vercode$objext", $sx,
					"Failed to remove compilation debris\n")
		unless ($sx);
	execute_command("./esqltest", $sx, $unsuccessful_test);
	execute_command("$RM esqltest$EX", $sx,
					"Failed to remove esqltest$EX program\n")
		unless ($sx);
}

##############################
# -- End of ESQLTEST code -- #
##############################

###########################################################################
# The best way to get the library linked reliably is to use the script that
# comes with ESQL/C.  It knows which libraries are needed, etc.  The lists
# change regularly from release to release.  Do not try second-guessing it;
# you will fail, and sooner rather than later.
#
# On SVR4 machines, the -G option is used to tell the C compiler to
# create a shared object.  Unfortunately, the esql script interprets the
# -G option as 'add debugging' (a case-insensitive version of -g) so it
# does not get relayed to the actual loader (cc) program.  Hence, use
# INFORMIXC to define the loader and the LDDLFLAGS via the back door.
#
# However, there are other problems if the loader for dynamic (shared)
# libraries is not a C compiler.  Specifically, the esql script passes
# arguments like -I$INFORMIXDIR/incl/esql which 'ld' doesn't understand.
# The esqlld script provided with DBD::Informix eliminates those arguments
# for many machines.
#
# However, this doesn't work with the DEC OSF 'ld', because esql also adds
# a spurious -threads flag and needs various special options including
# '-shared -expect_unresolved "*"'.  The '*' is mishandled by the ESQL/C
# script, and it isn't worth trying to fix that.  With the ESQL/C Version
# 6.00 and later, we can get a list of libraries out of esql itself and
# pass these to LD.  The only wrinkle here is that if the version is 7.2x
# or later, then you also need to add $INFORMIXDIR/lib/esql/checkapi.o to
# the files list...

# Default version of $opts{LD}
$opts{LD} = "INFORMIXC='\$(FULLPERL) esqlld' " .
			"ESQLLD='$Config{ld} \$(LDDLFLAGS)' \$(ESQL)";

my $esql_nt = "";
if ($NTConfiguration)
{
	# NT configuration
	$esql_nt = "-cc";	# Not sure what this does; ask Harold.
	if ($vernum >= 500 && $vernum < 600)
	{
		my $libs=" ISQLI501.LIB LMCSQLW.LIB ";
		$opts{dynamic_lib} = { OTHERLDFLAGS => "/LIBPATH:$ID/lib $libs"};
	}
	elsif ($vernum >= 600)
	{
		print "Fortunately, you are using a new version of ESQL/C and\n";
		print "we can use 'esql -libs' to tell us which libraries to use.\n\n";
		my $libs = `$esql -libs` || die "Couldn't execute 'esql -libs'";
		$libs =~ s/Libraries to be used://gm;
		$libs =~ s/esql: error -55923: No source or object file\.//gm;
		$libs =~ s/\n/ /gm;
		$opts{dynamic_lib} =
			{ OTHERLDFLAGS => "/LIBPATH:$ID/lib /LIBPATH:$ID/lib/esql $libs"};
	}
	else
	{
		print "Unfortunately, you are also using a version of ESQL/C which\n";
		print "cannot tell us which libraries it needs.\n";
		print "We'll assume that esqlld can sort things out for you.\n";
		print "Contact the DBD::Informix maintenance team if it doesn't.\n\n";
		# Do not override default version of $opts{LD}
	}
}
elsif ($Config{ld} !~ /cc$/ && $Config{ld} ne $Config{cc})
{
	# Unix configuration (awkward squad subset of Unix configurations)
	# NB: On AIX 4.2, the C compiler cannot be used to create share libraries.
	# This problem noted and fixed by JL, 1999-09.
	print &nlt(qq{
		Uh oh!  We're on a machine which does not use the C compiler to
		create shared libraries.  Please consider recompiling Perl using
		the C compiler to create shared libraries; it makes life much
		easier for everyone!
		}) unless $Config{osname} eq "aix" or $Config{osname} eq "hpux";
	if ($vernum >= 600)
	{
		print &nlt(qq{
			Fortunately, you are using a new version of ESQL/C.  We could
			use 'esql -libs' to tell us which libraries to use, except that
			some versions of the esql script are very Clintonian and do not
			tell us the whole truth.  So we have to do a fiddly workaround,
			editing the esql script on the fly and feeding the edited
			version to the shell and ...  Oh, you really don't want to know
			what we do; it's horrid but it works, usually!
			});
		my $esqlscript = (-f $esql) ? $esql : "$ID/bin/esql";
		my $libs = `sed 's/^[ 	]*exec/echo/' $esqlscript | sh -s -- -o pseudonym $esqlc_flags dbd::ix.o`
			|| die "Couldn't execute $esqlscript to determine the ESQL/C libraries\n";
		$libs =~ s/\n/ /gm;
		$libs =~ s/^.* dbd::ix.o / /;
		# Remove -L directives for Informix libraries (we add them anyway later).
		$libs =~ s% -L *$ID/lib % %;
		$libs =~ s% -L *$ID/lib/esql % %;
		$libs =~ s/-threads// if ($Config{osname} eq 'dec_osf');
		$libs = &fix_aix_netstub($libs)
			if ($Config{osname} eq "aix" and $libs =~ /-lnetstub/);
		$libs = &fix_hpux_syslibs($libs)
			if ($Config{osname} eq "hpux" and $libs =~ /-l(V3|cl|:libcl.1)/);
		if ($ENV{DBD_INFORMIX_RELOCATABLE_INFORMIXDIR})
		{
			# Specify that SHLIB_PATH is OK at runtime
			$libs = "+s $libs" if ($Config{osname} eq "hpux");
		}
		else
		{
			my(@libs) = split ' ', $libs;
			my(@names) = map_informix_lib_names(@libs);
			$libs = join ' ', @names;
		}
		print "... We are going to use the library list:\n$libs\n";
		# On 722 on the DEC, including checkAPI twice dies.
		# Linking it once gives an undefined.  So we link once and
		# export.  Andrew Hunt (andy@toolshed.com), 1997-04-18.
		# JL 1998-01-13:
		# Do not need to add checkapi.o because the hacked ESQL/C script above will
		# have listed it.  Still need the -exported_symbol on DEC, though.  Probably.
		#		$libs .= " $ID/lib/esql/checkapi.o"
		#			if (-f "$ID/lib/esql/checkapi.o") &&
		#				!($vernum >= 722 && $Config{osname} eq 'dec_osf');
		# Override default version of $opts{LD}
		$opts{dynamic_lib} =
			{ OTHERLDFLAGS => "-L$ID/lib -L$ID/lib/esql $libs"};
		$opts{LD} = "$Config{ld}";
		$opts{LD} .= " -exported_symbol ifx_checkAPI"
			if ($vernum >= 722 && $Config{osname} eq 'dec_osf');
	}
	else
	{
		print &nlt(qq{
			Unfortunately, you are also using a version of ESQL/C which
			cannot tell us which libraries it needs.  We will assume that
			esqlld can sort things out for you.  Contact the $opts{NAME}
			maintenance team if it does not do so.
			});
		# Do not override default version of $opts{LD}
	}
	print "\n";
}

# On Solaris, setting -R flags allows DBD::Informix to be used in
# CGI scripts or cron tasks more easily.
${$opts{dynamic_lib}}{OTHERLDFLAGS} .= " -R$ID/lib -R$ID/lib/esql"
	if ($Config{osname} eq 'solaris');

# Ensure that esqlcc, esqlld, esqlsed are executable
my $file;
for $file (qw(esqlcc esqlld esqlsed))
{
	if (! -x $file)
	{
		my $mode = (stat $file)[2] | 0111;
		chmod $mode, $file;
	}
}

# Probably cause for being thrown out of The Perl Institute, but TMTOWTDI!
system "$^X t/dtgen.pl > t/dtgen.sql";
system "$^X t/decgen.pl > t/decgen.sql";

WriteMakefile(%opts);

# Cleanly exit from the Makefile-build process

exit 0;

#-------------------------------------------------------------------------
# Subroutines used in code above.
#-------------------------------------------------------------------------

# Tell the user that they did not read the README file and why
# we think they didn't read it.
sub did_not_read
{
	die "\n*** You didn't read the README file!\n@_\n\n";
}

# which: report the name of an executable command.
sub which
{
	my ($cmd, $path) = @_;
	my ($dir, $name);
	$path = $ENV{PATH} if (!$path);
	my @path = split /$split/, $path;
	for $dir (@path)
	{
		$dir = '.' if (!$dir);
		$name = $dir . "/" . $cmd;
		return $name if -x $name;
	}
	return "";
}

# Define a postamble function for the makefile which briefs MAKE on how to
# compile ESQL/C source code.  It gives .ec rules (and files) precedence
# over .c files with the same name by zapping and reorganizing the entire
# suffix list.  The .SUFFIXES list was copied from the MakeMaker constants
# section (circa 1998).  It contains all the extensions that DBD::Informix
# needs (and a few C++ strays) but isn't complete by 2002 standards.  It's
# a pity that changing this list cannot be handled more cleanly.

sub dbd_informix_postamble
{
my ($p1, $p2, $p3, $p4);

$p1 =
"
# ESQL/C compilation rules
ESQL       = $esql
ESQL_NT    = $esql_nt
ESQLCFLAGS = $esqlc_flags
.SUFFIXES:
.SUFFIXES: .ec .xs .c .C .cpp .cxx .cc $objext .sh

.ec$objext:";

$p2 = q%
	$(ESQL_CC) -c $(ESQLCFLAGS) $(ESQLFLAGS) $*.ec
	$(RM_F) $*.c

# Cribbed from the definition of CCCMD (MakeMaker const_cccmd) and the
# rules for compiling object files (MakeMakerc_o) in the Makefile.
# There should be a cleaner way to do this, too.
# May need fixing if the corresponding rules change.
# NB: UFLAGS is a DBD::Informix addition - it is for user-flags and should
#     not be set by the Makefile.  The user can add a flag on the make line
#     with "make UFLAGS=-Dxyz".
UFLAGS =
ESQLFLAGS = $(UFLAGS) $(INC) $(ESQL_NT) $(CCFLAGS) $(OPTIMIZE) \
		$(PERLTYPE) $(LARGE) $(SPLIT) $(DEFINE_VERSION) \
		$(XS_DEFINE_VERSION) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE)
%;

if ($NTConfiguration)
{
	$p3 = q%
	ESQL_CC     = $(ESQL)
	%;
}
else
{
	$p3 = q%
	ESQL_CC     = INFORMIXC="$(FULLPERL) esqlcc" ESQLCC="$(CC)" $(ESQL)
	%;
}
$p3 =~ s/\t//g;

$p4 = '
MAP_LINKCMD = $(ESQL_CC)

# Need to move the esql script created locally (in case the next build
# uses a version of ESQL/C which does not need the custom esql script).
clean::
	-[ ! -f esql ] || mv esql esql.old
';

return $p1 . $p2 . $p3 . $p4;
}

# nlt - no leading tabs.
# Strip leading tabs of lines in a string, to allow quoted strings to be
# indented in source but printed without leading tabs in output.
sub nlt
{
	my($string) = @_;
	$string =~ s/^\t+//o;
	$string =~ s/\n\t+/\n/gmo;
	return $string;
}

# Execute a command, logging it if $sx is set, and dying with given message
# if command fails.
sub execute_command
{
	my ($cmd, $sx, $msg) = @_;
	print "+ $cmd\n" if ($sx);
	die $msg unless system($cmd) == 0;
}

# Custom edit older versions of the ESQL/C compiler script to acknowledge
# the INFORMIXC environment variable.
sub customize_esql
{
	my ($src, $dst, $pkg) = @_;
	open(ESQL, "<$src") ||
		die "Unable to open $src for reading";
	open(LOCAL, ">$dst") ||
		die "Unable to open $dst for writing";
	while (<ESQL>)
	{
		if (/^CC=/o && !/INFORMIXC/o)
		{
			print LOCAL "# INFORMIXC added by Makefile.PL for $pkg.\n";
			chop;
			s/^CC=//;
			s/"(.*)"/$1/ if (/".*"/);
			$_ = 'CC="${INFORMIXC:-' . $_ . "}\"\n";
		}
		elsif (/\s+CC="cc -g"/o)
		{
			print LOCAL "# CC adjustment changed by Makefile.PL\n";
			print LOCAL "# Was: $_\n";
			s/CC="cc -g"/CC="\${CC} -g"/o;
		}
		elsif (/STATOPT="STATICONLY"/o)
		{
			# HP-UX 10.20, ESQL/C 7.24 will not link with shared libries.
			# This is probably a bug in ESQL/C release process.
			print LOCAL "# Static libraries only removed by Makefile.PL\n";
			print LOCAL "# Was: $_\n";
			s/STATICONLY//o;
		}
		print LOCAL;
	}
	close(ESQL);
	close(LOCAL);
	chmod 0755, $dst;
}

sub set_esqlc_linkage
{
	my ($def_link, $nt) = @_;
	# The NT ESQL/C compiler (version 9.30.TC1 at least, probably all) does
	# not recognize the "-shared" option (it passes it through to the C
	# compiler, which doesn't recognize it either), so never set it.
	return "" if ($nt);
	my $env_link = $ENV{DBD_INFORMIX_ESQLC_LINKAGE};
	print "** Using $env_link from DBD_INFORMIX_ESQLC_LINKAGE environment variable.\n\n"
		if (defined $env_link);
	return (defined $env_link) ? $env_link : $def_link;
}

sub grep_for_statopt_staticonly
{
	my ($src) = @_;
	open(ESQL, "<$src") ||
		die "Unable to open $src for reading";
	while (<ESQL>)
	{
		if (/^STATOPT="[^"]+"/)
		{
			close ESQL;
			return 1;
		}
	}
	close ESQL;
	return 0;
}

sub fix_b102265
{
	my ($epp, $esql, $name) = @_;
	warn &nlt(qq%
		Your version of ESQL/C is crippled and will not link with shared
		libraries even if you tell the script to use them (PTS Bug
		102265).  We are going to make a hacked copy of the script and
		use that.

		If the hacked ESQL/C script does not work, then you will probably
		have to make a static version of Perl with DBD::Informix and the
		ESQL/C.  Read the Notes/static.build file for more information.

		Or (a much better idea) upgrade to Client SDK 2.40 or later!
		%);
	&customize_esql($epp, $esql, $name);
}

# JL 2000-01-28: ESQL/C 9.15.UC1 (CSDK 2.01.UC1) on AIX 4.2 includes
# -lnetstub but $INFORMIXDIR/lib/libnetstub.so is rejected by the
# linker.  Option 1: use libnetstubshr.a, instead.  Option 2: not all
# versions have libnetstubshr.a, so look for netstub.a instead.
sub fix_aix_netstub
{
	my ($libs) = @_;
	if ($ENV{DBD_INFORMIX_AIX_USENETSTUB})
	{
		print "!!! Retaining reference to -lnetstub because of DBD_INFORMIX_AIX_USENETSTUB\n";
	}
	else
	{
		if (-f "$ID/lib/libnetstubshr.a")
		{
			print "... Replacing reference to -lnetstub with -lnetstubshr (override with DBD_INFORMIX_AIX_USENETSTUB)\n";
			$libs =~ s%-lnetstub%-lnetstubshr%;
		}
		elsif (-f "$ID/lib/netstub.a")
		{
			print "... Replacing reference to -lnetstub with $ID/lib/netstub.a (override with DBD_INFORMIX_AIX_USENETSTUB)\n";
			$libs =~ s%-lnetstub%$ID/lib/netstub.a%;
		}
		else
		{
			print "!!! Retaining reference to -lnetstub (no alternatives available?!)\n";
		}
	}
	return $libs;
}

# JL 2000-01-28: including -lcl and -l:libcl.1 on the link line causes
# HP-UX 11.0 to barf with thread-local storage in the shared library.
# As far as can be detected, libV3.{a,sl} is unneeded.  Provide escape
# routes to override the behaviour which removes them.
sub fix_hpux_syslibs
{
	my ($libs) = @_;
	if ($libs =~ /-lV3/)
	{
		if ($ENV{DBD_INFORMIX_HPUX_USELIBV3})
		{
			print "!!! Retaining reference to -lV3 because of DBD_INFORMIX_HPUX_USELIBV3\n";
		}
		else
		{
			print "... Removing reference to -lV3 (override with DBD_INFORMIX_HPUX_USELIBV3)\n";
			$libs =~ s/-lV3//;
		}
	}
	if ($libs =~ /-lcl/)
	{
		if ($ENV{DBD_INFORMIX_HPUX_USELIBCL})
		{
			print "!!! Retaining reference to -lcl because of DBD_INFORMIX_HPUX_USELIBCL\n";
		}
		else
		{
			print "... Removing reference to -lcl (override with DBD_INFORMIX_HPUX_USELIBCL)\n";
			$libs =~ s/-lcl//;
			$libs =~ s/-l:libcl.1//;
		}
	}
	return $libs;
}

sub Write_DBD_Informix_Defaults
{
	my $defaults = "$dbd_ix_pm_dir/Defaults.pm";
	open DEFAULTS, ">$defaults"
		or die "Cannot create $defaults ($!)";
	print DEFAULTS <<'EOF';
#   Default Environment Variables for IBM Informix Database Driver for Perl Version 2003.04 (2003-03-05)
#
#   Copyright 2002-03 IBM
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.

{
	package DBD::Informix::Defaults;

	require Exporter;
	@ISA = qw(Exporter);
	@EXPORT = qw(default_INFORMIXDIR default_INFORMIXSERVER);

	$VERSION = "2003.04";
	$VERSION = "0.97002" if ($VERSION =~ m%[:]VERSION[:]%);

EOF

	print DEFAULTS "\tsub default_INFORMIXDIR\n\t{\n\t\treturn '$ENV{INFORMIXDIR}';\n\t}\n";
	print DEFAULTS "\tsub default_INFORMIXSERVER\n\t{\n\t\treturn '$ENV{INFORMIXSERVER}';\n\t}\n";
	print DEFAULTS <<'EOF';
	1;
}

__END__

=head1 NAME

DBD::Informix::Defaults - Default values for INFORMIXDIR and INFORMIXSERVER

=head1 SYNOPSIS

use DBD::Informix::Defaults;

=head1 DESCRIPTION

This module was generated automatically by DBD::Informix
(IBM Informix Database Driver for Perl Version 2003.04 (2003-03-05)).
It records the default values of INFORMIXDIR and INFORMIXSERVER
that were in use when DBD::Informix was built.
You can edit the returned values if you need to.

The recorded default values are:

EOF

	print DEFAULTS "    INFORMIXDIR    = $ENV{INFORMIXDIR}\n";
	print DEFAULTS "    INFORMIXSERVER = $ENV{INFORMIXSERVER}\n";
	print DEFAULTS <<'EOF';

You will seldom if ever have cause to use this module directly.
You should seldom have cause to use it indirectly either because
you will always set INFORMIXDIR and INFORMIXSERVER in the
environment before using DBD::Informix.

=head1 AUTHOR

Jonathan Leffler

=cut
EOF

	close DEFAULTS or die;
	print "$defaults written OK\n";
}

__END__
