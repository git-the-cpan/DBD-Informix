#!/usr/bin/perl -sw
#
# @(#)$Id: Makefile.PL,v 97.6 2000/01/19 21:45:52 jleffler Exp $ 
#
# Portions Copyright (c) 1996-99 Jonathan Leffler
# Portions Copyright (c) 1996    Alligator Descartes
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the Perl README file.

#TABSTOP=4

# A sufficiently recent version of Perl and DBI must be installed before we
# can build the DBD module.  The code in DBD::Informix needs the features
# present in Perl 5.004 and DBI 1.02.
use 5.004;
use ExtUtils::MakeMaker qw(&WriteMakefile $Verbose);
use Config;
use strict;
use DBI 1.02;
use DBI::DBD;

BEGIN { require "perlsubs/esqlc.pl"; }

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

my %opts = (
	NAME         => 'DBD::Informix',
	VERSION_FROM => 'Informix.pm.PL',
	clean        => { FILES        => 'Informix.pm Informix.xsi esqlinfo.h esqlvrsn.h t/decgen.sql t/dtgen.sql' },
	realclean    => { FILES        => 'esql' },
	dist         => { DIST_DEFAULT => 'clean pause_hack/Informix.pm distcheck disttest tardist',
					  PREOP        => '$(MAKE) -f Makefile.old distdir',
					  COMPRESS     => 'gzip -v9',
					  SUFFIX       => 'gz'
					},
	'PL_FILES'   =>	{ 'Informix.pm.PL' => 'Informix.pm' },
	'PM'         =>	{ 'Informix.pm' => '$(INST_LIBDIR)/Informix.pm',
					  'lib/Bundle/DBD/Informix.pm' => 'blib/lib/Bundle/DBD/Informix.pm',
					}
		   );

my $dbd_ix = &dbd_informix_version_info($opts{VERSION_FROM});
print qq%
Configuring $opts{NAME} version $dbd_ix...
		You are using DBI version $DBI::VERSION and Perl version $]
Remember to actually read the README file!

%;

# log key platform information to help me help you quickly
print "Perl:     perl$] @Config{qw(archname dlsrc)}\n";
print "System:   @Config{qw(myuname)}\n";
print "Compiler: @Config{qw(cc optimize ccflags)}\n";
print "Loader:   $Config{ld}\n"
	if ($Config{ld} !~ /cc$/ && $Config{ld} ne $Config{cc});

# Assorted hints - these should be move to a hints subdirectory.
print "\nSee notes about SPARCompiler on Solaris in Notes/solaris\n"
	if ($Config{osname} eq 'solaris' and &which($Config{cc}) =~ m%/SUNWspro/%);
print "\n";

&did_not_read("Perl is out of date") unless ($] >= 5.004);
&did_not_read("DBI is out of date") unless ($DBI::VERSION >= 1.02);

# Compare installed version of DBI with version which DBD::Informix was
# last tested with.
# The required and reference versions are the same for this release.
my $dbi_ref_ver = "1.13";
warn "*** Ideally, you should upgrade to DBI version $dbi_ref_ver.\n\n"
	unless ($DBI::VERSION >= $dbi_ref_ver);

my ($ID, $esqlprog) = &find_informixdir_and_esql($NTConfiguration);

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
	die qq{
	The ESQL/C version information found was: <<$infversion>>
	$opts{NAME} failed to find a version number ($vernum).
	Please report this to the $opts{NAME} maintenance team.
	};
}
elsif ($vernum >= 100 && $vernum < 500)
{
	die qq{
	$infversion does not support string-named cursors.
	This version of $opts{NAME} requires this facility.
	There are no longer any plans to back-port $opts{NAME}
	to such old and obsolete versions of ESQL/C.
	Please investigate upgrading your software.
	If all else fails, try installing DBD::Informix4 instead.
	}
}
elsif ($vernum >= 500 && $vernum < 600)
{
	warn &nlt(qq%
			This version of ESQL/C is not considered Y2K-safe by Informix.
			Please check out the Y2K page at the Informix web site (http://www.informix.com)
			Please upgrade to version 5.10 or later.
			%) unless $vernum >= 510;
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
			I'll create a local version and ensure that we use it.\n
			%);
		$esql = "./esql";
		&customize_esql("$ID/bin/$esqlprog", $esql, $opts{NAME});
	}
	print &nlt(qq%
		You may run into problems creating a shared object version of
		$opts{NAME}.  If so, try creating a statically linked version
		instead.  Read the Notes/static.build file.\n
		%);
}
elsif ($vernum >= 600 && $vernum < 700)
{
	warn &nlt(qq%
			This version of ESQL/C is obsolete.
			It is also not considered Y2K-safe by Informix.
			Please check out the Y2K page at the Informix web site (http://www.informix.com)
			Please upgrade to version 7.24 or later.
			%);
	print "Also check whether you should set DBD_INFORMIX_ESQLC_LINKAGE.\n";
	$esqlc_flags .= &set_esqlc_linkage("");
}
elsif ($vernum >= 700 && $vernum < 720)
{
	warn &nlt(qq%
			This version of ESQL/C is obsolete.
			It is also not considered Y2K-safe by Informix.
			Please check out the Y2K page at the Informix web site (http://www.informix.com)
			Please upgrade to version 7.24 or later.
			%);
	print "Also check whether you should set DBD_INFORMIX_ESQLC_LINKAGE.\n";
	$esqlc_flags .= &set_esqlc_linkage("");
}elsif ($vernum >= 720 && $vernum < 800)
{
	# 7.2x is already released.  There should not be an ESQL/C version
	# 7.3x.  The 7.3x server is Informix Dynamic Server, IDS.  You use
	# ClientSDK 2.x to access IDS, and the ESQL/C version numbers for
	# ClientSDK are currently 9.1x numbers, not 7.3x (see below).
	# Note that the IUS tests take into account both the version of
	# ESQL/C and the version of the database engine you are using
	# before trying to run any IUS data type testing.
	# Set $esqlc_flags to try and ensure shared library linking.
	# Officially, the default should be shared library linking, but
	# by report, some versions have reverted to static linking as the
	# default.  Use the -shared flag to force shared library linking.
	# Provide DBD_INFORMIX_ESQLC_LINKAGE to override the default.
	warn &nlt(qq%
			This version of ESQL/C is not considered Y2K-safe by Informix.
			Please check out the Y2K page at the Informix web site (http://www.informix.com)
			Please upgrade to version 7.24 or later.
			%) if ($vernum < 724);
	$esqlc_flags .= &set_esqlc_linkage("-shared");
}
elsif ($vernum >= 800 && $vernum < 900)
{
	# Informix XPS.  Versions 8.00 through 8.2x probably use ESQL/C 8.xy.
	# Starting with version 8.30, you are expected to use ClientSDK, normally.
	# We finally have some feedback from a real user (Robert E Wyrick <rob@wyrick.org>),
	# so we can say we support 8.x at last.
	print &nlt(qq%
				$opts{NAME} is still learning about XPS, so please report
				your experience installing $opts{NAME} with XPS.  Thanks!
				%);
	$esqlc_flags .= &set_esqlc_linkage("-shared");
}
elsif ($vernum >= 900 && $vernum < 912)
{
	# ESQL/C 9.0x and 9.10 or 9.11 were pre-releases of the ESQL/C for
	# the Informix Universal Server (IUS).  These should not still be
	# in use.  ESQL/C 9.12 was released as ESQL/C 9.12, to go with the
	# first generally available (GA) release of IUS.  Since then,
	# Informix OnLine has been renamed Informix Dynamic Server (IDS),
	# and IUS has been renamed IDS/UDO (IDS Universal Data Option).
	# ESQL/C is now a component of ClientSDK, and its version numbers
	# are independent of the database server.  So, for example, it is
	# possible to use IDS/UDO 9.14, the latest version at 1998-11-01,
	# with ClientSDK 2.10 (aka ESQL/C 9.16), also the latest version.
	print "You should upgrade to a more recent version of ESQL/C.\n";
	print "Also check whether you should set DBD_INFORMIX_ESQLC_LINKAGE.\n";
	print $warning;
	$esqlc_flags .= &set_esqlc_linkage("-shared");
}
elsif ($vernum >= 912 && $vernum < 1000)
{
	# ESQL/C 9.13 was released as ClientSDK 2.00
	# ESQL/C 9.14 was released as ClientSDK 2.01
	# ESQL/C 9.15 was released as ClientSDK 2.02
	# ESQL/C 9.16 was released as ClientSDK 2.10
	# ESQL/C 9.20 was released as ClientSDK 2.20
	# ESQL/C 9.21 was released as ClientSDK 2.30
	# ESQL/C 9.30 was released as ClientSDK 2.40
	print &nlt(qq%
			The tests in t/t31nulls.t and t/t32nulls.t will probably fail.
			Please upgrade to a more recent version of ClientSDK.
		%) if ($vernum == 914);
	print $warning;
	$esqlc_flags .= &set_esqlc_linkage("-shared");
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

# The ESQL/C script does not handle options with spaces and quotes, dammit!
# Hence, create $versionfile to contain ESQLC_VERSION_STRING.
{
my $versionfile = "esqlvrsn.h";
unlink $versionfile;
die "Unable to open $versionfile for writing\n"
	unless open(VERSION, ">$versionfile");
print VERSION "/* File $versionfile generated by $opts{NAME} $dbd_ix for $infversion */\n";
print VERSION "#define ESQLC_VERSION_STRING \"$infversion\"\n";
close VERSION;
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
close ESQLINFO;
}

# Add extra definitions to compile the code under GCC if DBD_GCC_DEBUG set.
# Perl configuration headers contain lots of /* inside comments (-Wno-comment)
#$opts{DEFINE} .= ' -Wall -pedantic -Wno-comment -Wpointer-arith -Wcast-align'
#	    . ' -Wconversion -Wtraditional -Wcast-qual'
$opts{DEFINE} .= ' -Wall -pedantic -Wno-comment'
	if $Config{cc} eq 'gcc' and $ENV{DBD_GCC_DEBUG};

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
# May also, or instead, need -I\$(SITEARCHEXP)/auto/DBI; this was reported
# by Joachim Schrod <jschrod@acm.org> in January 1998 on AIX.
my $INC2 = "-I\$(INSTALLARCHLIB)/auto/DBI -I\$(INSTALLSITEARCH)/auto/DBI";

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

If you can't get that to work, then the problem is with ESQL/C
and not with $opts{NAME} per se, and you need to get your ESQL/C
installation fixed so that you can compile and run the esqlbasic
program successfully.

Make sure you've read the whole README file before asking the
DBI/DBD community for help!
%;

if ($ENV{DBD_INFORMIX_NO_ESQLTEST})
{
	print &nlt(qq%
		Because DBD_INFORMIX_NO_ESQLTEST is set in your environment, you
		have chosen not to run the test which verifies that your ESQL/C
		setup will allow DBD::Informix to compile and the tests to run.  If
		you run into *ANY* problems, you must verify that the esqltest
		program can be compiled and run successfully before you even think
		of asking for help.  Also make sure you've read the whole README
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

my $esql_nt;
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
		}) unless $Config{osname} eq "aix";
	if ($vernum >= 600)
	{
		print &nlt(qq{
			Fortunately, you are using a new version of ESQL/C.  We could
			use 'esql -libs' to tell us which libraries to use, except that
			some versions of the esql script are very Clintonian and don't
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
			cannot tell us which libraries it needs.  We'll assume that
			esqlld can sort things out for you.  Contact the $opts{NAME}
			maintenance team if it doesn't.
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
	my ($reason) = @_;
	die "\n*** You didn't read the README file!\n$reason\n\n";
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

# Define a postamble for the makefile which briefs MAKE on how to compile
# ESQL/C source code.  It gives .ec rules (and files) precedence over .c
# files with the same name by zapping and reorganizing the entire suffix
# list.  The .SUFFIXES list is copied the MakeMaker constants section.
# It's a pity that changing this list cannot be handled more cleanly.  It
# doesn't really matter whether .xs files have precedence over .ec files or
# not -- it would be OK to place .ec in front of the standard list.

sub MY::postamble
{
my ($p1, $p2, $p3, $p4, $p5, $p6);

$p1 = 
"
# ESQL/C compilation rules
ESQL       = $esql
ESQL_NT    = $esql_nt
ESQLCFLAGS = $esqlc_flags
.SUFFIXES:
.SUFFIXES: .xs .ec .c .C .cpp .cxx .cc $objext .sh

.ec$objext:";

$p2 = '
	$(ESQL_CC) -c $(ESQLCFLAGS) $(ESQLFLAGS) $*.ec
	$(RM_F) $*.c

# Cribbed from the definition of CCCMD (MakeMaker const_cccmd) and the
# rules for compiling object files (MakeMakerc_o) in the Makefile.
# May need fixing if the corresponding rules change.
ESQLFLAGS = $(INC) $(ESQL_NT) $(CCFLAGS) $(OPTIMIZE) \
		$(PERLTYPE) $(LARGE) $(SPLIT) $(DEFINE_VERSION) \
		$(XS_DEFINE_VERSION) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE)';

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

# Standardised code to generate Informix.xs from Informix.xsi and the
# template from DBI (Driver.xst).  dbd_postamble() is defined by DBI::DBD.
$p5 = dbd_postamble();

# Code to update the version in the file that we give to PAUSE.
my $version_src = MM->catfile('pause_hack', 'Informix.pm.src');
my $version_dst = MM->catfile('pause_hack', 'Informix.pm');
$p6 = qq!
$version_dst : Makefile
	\$\(PERL\) -pe 's/^\\\$\$VERSION = .*/\\\$\$VERSION = \$(VERSION);/' $version_src > $version_dst

!;

return $p1 . $p2 . $p3 . $p4 . $p5 . $p6;
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

sub MY::processPL
{
	package MY;
	my $inherited = shift->SUPER::processPL(@_);
	my $server = '';
	$server = "-dINFORMIXSERVER=$ENV{INFORMIXSERVER}" if defined $ENV{INFORMIXSERVER};
	$inherited =~ s/(\$\(PERL\) .* Informix.pm.PL)/$1 -dINFORMIXDIR=$ID $server/;
	$inherited;
}

__END__
