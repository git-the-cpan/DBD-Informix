#!/usr/bin/perl -sw
#
# @(#)$Id: Makefile.PL,v 60.3 1998/08/13 00:47:02 jleffler Exp $ 
#
# Portions Copyright (c) 1996-98 Jonathan Leffler
# Portions Copyright (c) 1996    Alligator Descartes
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the Perl README file.

#TABSTOP=4

# A sufficiently recent version of Perl and DBI must be installed before we
# can build the DBD module.  The code in DBD::Informix needs the features
# present in Perl 5.004 and DBI 0.90.
use 5.004;
use ExtUtils::MakeMaker qw(&WriteMakefile $Verbose);
use Config;
use strict;
use DBI 0.90;
use DBI::DBD;

# Configure for Unix vs Windows 95/NT
my $objext = $Config{obj_ext};
my $split = $Config{path_sep};
my $NTConfiguration = $Config{archname} eq 'MSWin32';

if ($NTConfiguration)
{
	# NT configuration...
	print q[
	This is a semi-experimental version of Makefile.PL with Win32 (NT)
	support.  This version has been tested on NT, but there could still
	be bugs in it.  Please help save the world by trying to debug the
	NT code and report the results back to the DBI Users mail list.

	Thanks!
	]
}

$| = 1;     # Ensure that Perl output is interleaved with test output.

my %opts = (
    NAME         => 'DBD::Informix',
    VERSION_FROM => 'Informix.pm',
    clean        => { FILES        => 'Informix.xsi esqlvrsn.h' },
    realclean    => { FILES        => 'esql' },
    dist         => { DIST_DEFAULT => 'clean distcheck disttest tardist',
                      PREOP        => '$(MAKE) -f Makefile.old distdir',
                      COMPRESS     => 'gzip',
                      SUFFIX       => 'gz'
                    }
           );

# Extract the version number from Informix.pm.
# It may need to handle single quotes as well as double quotes around the
# version number to be fully general.  If there's a better way to do this,
# I want to be told, please.
sub version_info
{
	my ($file) = @_;
	open(PMFILE, $file) || die;
	while (<PMFILE>)
	{
		if (/\$VERSION\s*=\s*"([^"]+)"\s*;/)
		{
			close PMFILE;
			return $1;
		}
	}
	close PMFILE;
	return "<<ERROR - no VERSION in $file>>";
}

my $dbd_ix = &version_info($opts{VERSION_FROM});
print "\nConfiguring $opts{NAME} version $dbd_ix...\n";
print "\tYou are using DBI version $DBI::VERSION and Perl version $]\n";
print "Remember to actually read the README file!\n\n";

sub did_not_read
{
	my ($reason) = @_;
	die "\n*** You didn't read the README file!\n$reason\n\n";
}

did_not_read("Perl is out of date") unless ($] >= 5.004);
did_not_read("DBI is out of date") unless ($DBI::VERSION >= 0.90);

# Compare installed version of DBI with version which DBD::Informix was
# last tested with.
# The required and reference versions are different for this release.
my $dbi_ref_ver = "0.95";
warn "*** Ideally, you should upgrade to DBI version $dbi_ref_ver.\n\n"
	unless ($DBI::VERSION >= $dbi_ref_ver);

sub find_informixdir_and_esql
{
	my ($esql, $ID);
	if ($NTConfiguration)
	{
		# NT configuration
		# Tested for Config: archname='MSWin32' osname='MSWin32' osvers='4.0'
		my ($p);
		# Trying to find ESQL (and determining INFORMIXDIR too)
		foreach $p (split( /;/, $ENV{PATH}))
		{
			if( -x "$p/ESQL.EXE")
			{
				# HUMS: \\ needed, because string goes into Makefile (via postamble)
				$esql="$p\\ESQL.EXE"; 
				# HUMS: \\ necessary because string comes from ENV
				$p  =~ s/\\BIN//i;
				$ID=$p;
				last;
			}
		}
		did_not_read('No executable ESQL/C compiler found in $PATH')
			unless defined $esql;
		print "Using INFORMIXDIR=$ID and ESQL/C compiler $esql\n";
	}
	else
	{
		# Unix configuration
		$ID = $ENV{INFORMIXDIR};
		did_not_read('$INFORMIXDIR is not set') unless ($ID);
		$esql = $ENV{ESQL};
		$esql = "esql" unless $esql;
		if ($esql =~ m%/%)
		{
			# ESQL/C program specified with path name
			did_not_read("No executable ESQL/C compiler $esql")
				unless (-x $esql);
		}
		else
		{
			# ESQL/C program specified without any path name
			did_not_read("No executable ESQL/C compiler $ID/bin/$esql")
				unless (-x "$ID/bin/$esql");
		}
		did_not_read('$INFORMIXDIR/bin is not in $PATH')
			unless ($ENV{PATH} =~ m%:$ID/bin:% ||
					$ENV{PATH} =~ m%^$ID/bin:% ||
					$ENV{PATH} =~ m%:$ID/bin$%);
	}
	return $ID, $esql;
}

my ($ID, $esqlprog) = find_informixdir_and_esql();

my $auxincl = "";
$auxincl = " -I$ID/incl/tools" if ($esqlprog =~ /\bc4gl\b/);

# --- Find out which version of Informix ESQL/C by running 'esql -V'
# NB: Argument should be name of esql program which can be executed.
#     The checks for Unix in find_informixdir_and_esql should be OK.
sub get_esqlc_version
{
	my ($esql) = @_;
	my ($infv, $vers);

	open(ESQL, "$esql -V|") || die;
	die "Failed to read anything from 'esql -V'\n"
		unless defined ($infv = <ESQL>);
	# Read the rest of the input (1 line) to avoid Broken Pipe messages
	while(<ESQL>) { }
	close ESQL;

	chomp($infv);
	$infv =~ s/[ 	]+$//;
	($vers = $infv) =~ s/INFORMIX.* Version (....).*/$1/;
	die "Unexpected message from esql script -- $vers\n"
		unless ($vers =~ /[0-9]\.[0-9][0-9]/);
	$vers =~ s/^([0-9])\./$1/;

	return $infv, $vers;
}

my ($infversion, $vernum) = get_esqlc_version($esqlprog);
print "Using $infversion from $ID\n";

sub customize_esql
{
	my ($src, $dst) = @_;
	open(ESQL, "<$src") ||
		die "Unable to open $src for reading";
	open(LOCAL, ">$dst") ||
		die "Unable to open $dst for writing";
	while (<ESQL>)
	{
		if (/^CC=/o && !/INFORMIXC/o)
		{
			print LOCAL "# INFORMIXC added by Makefile.PL for $opts{NAME}.\n";
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
		print LOCAL;
	}
	close(ESQL);
	close(LOCAL);
	chmod 0755, $dst;
}

# --- Check whether Informix is installed OK for us.
my $warning = qq{
Beware: $opts{NAME} is not yet aware of the new IUS data types.
It will work with traditional data types, but will fail badly
on any data types which were not in earlier versions of OnLine.

};

# NB: If using ESQL/C 4.xy, use -I$ID/incl, not -I$ID/incl/esql!
# However, you've got other major work to do to handle 4.xy ESQL/C.
# Also, it appears that NT ESQL/C 5.x used -I$ID/incl, too.
my $INC1 = "-I$ID/incl/esql$auxincl";

my $esql = "$esqlprog";
my $vercode = "esqlc_v6";
my $multiconn = 1;
if ($vernum >= 500 && $vernum < 600)
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
		print "You need to use a customized ESQL/C compiler script\n";
		print "which recognizes the INFORMIXC environment variable.\n";
		print "I'll create a local version and ensure that we use it.\n\n";
		$esql = "./esql";
		customize_esql("$ID/bin/$esqlprog", $esql);
	}
}
elsif (($vernum >= 600 && $vernum < 700) or ($vernum >= 710 && $vernum < 720))
{
	print "Ideally, you should upgrade to a more recent version of ESQL/C.\n";
}
elsif ($vernum >= 720 && $vernum < 800)
{
	# 7.2x is already released; 7.3x is in the pipeline
}
elsif ($vernum >= 100 && $vernum < 500)
{
	die qq{
	$infversion does not support string-named cursors.
	This version of $opts{NAME} requires this facility.
	Please report your requirement to the $opts{NAME} maintenance team.
	}
}
elsif ($vernum >= 900 && $vernum < 912)
{
	print "Ideally, you should upgrade to a more recent version of ESQL/C.\n";
	print $warning;
}
elsif ($vernum >= 912 && $vernum < 1000)
{
	# 9.12 is released; 9.13 and 9.20 are in the pipeline.
	print $warning;
}
else
{
	die qq{
	I do not know anything about $infversion.
	Please report this to the $opts{NAME} maintenance team.
	However, if it is later than 5.00, there is a fair chance that
	$opts{NAME} will work if you modify the code in Makefile.PL which
	contains this message to recognize your version.  If you have a
	5.1x release, then you should be fine treating it as a 5.0x
	release.  If you have an 8.0x release, you may need to treat it as
	7.1x or 7.2x; if you have 9.0x or later, there is likely to be a lot
	of functionality in the database which $opts{NAME} does not know
	how to handle, but you should try treating it like 7.2x.
	}
}

# -- Configure the make process

# Define the version of ESQL/C for the object code.
$opts{DEFINE} = " -DESQLC_VERSION=$vernum";
$opts{DEFINE} .= " -DNDEBUG" if defined($ENV{DBD_INFORMIX_DISABLE_ASSERT});

print "\n$opts{NAME} doesn't check whether ODBC or Informix-CLI software\n";
print "is installed any more.  It uses a home-brew odbctype.h instead.\n\n";
$opts{INC} = " ";

# The ESQL/C script does not handle options with spaces and quotes, dammit!
# Hence, create $versionfile to contain ESQLC_VERSION_STRING.
# Also use it to decide whether ODBC is available or not.
{
my $versionfile = "esqlvrsn.h";
unlink $versionfile;
die "Unable to open $versionfile for writing\n"
	unless open(VERSION, ">$versionfile");
print VERSION "#define ESQLC_VERSION_STRING \"$infversion\"\n";
print VERSION "#ifndef USE_INSTALLED_ODBC\n";
print VERSION "#define USE_INSTALLED_ODBC 0\n";
print VERSION "#endif /* USE_INSTALLED_ODBC */\n";
close VERSION;
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

# Workaround Informix bug B08223 (aka B14937, and other numbers too)
# AIX localedef31.h defines a loc_t and is used by some system headers.
# Informix locator.h also defines a loc_t.  The workaround is to prevent
# the localedef31.h declaration from being included.
$opts{DEFINE} .= " -D__H_LOCALEDEF"
	if ($Config{osname} eq 'aix');

# The Informix headers (like sqlhdr.h) only generate function prototypes if
# __STDC__ is defined.  Without function prototypes, we are often passing
# pointers to _iq.. functions that the compiler thinks are ints.  This
# causes incorrect code to be generated on a 64-bit DEC Alpha with any
# optimization level greater than -O1.  So, if the compiler supports
# prototypes, we'll add -DUSE_PROTOTYPES to the command line.  The code in
# esqlc.h (version 1.9 and later) handles this mess for us.
# Additionally, you can run into problems with the code generated by the
# ESQL/C compiler, which undefines const if __STDC__ is not defined (eg
# on Solaris using the SUNWspro compiler).  These may show up as some
# function prototypes being redefined with the first version having const
# pointers and the second have non-const pointers.

if ($Config{"prototype"} eq 'define')
{
	$opts{DEFINE} .= " -DUSE_PROTOTYPES";
}
else
{
	print "\nGosh!  Perl doesn't think your compiler handles prototypes.\n";
	print "Well, even though I don't believe it, we'll take Perl's word\n";
	print "for it and we won't try to force them into use.\n";
	print "Don't you need to upgrade your compiler?\n";
}

my $objects = "Informix.o dbdimp.o dbdattr.o sqltoken.o";
$objects .= " sqltype.o ixblob.o decsci.o odbctype.o link.o $vercode.o";
$objects .= " eprintf.o" if defined $ENV{DBD_INFORMIX_USE_EPRINTF_CODE};
# Map object file names on non-Unix platforms
$objects =~ s/\.o\w/$objext/g if ($objext ne ".o");

# Need to pick up the DBI headers.
# Prior to DBI-0.77, the /auto sub-directory in $INC2 was not used.
my $INC2 = "-I\$(INSTALLSITEARCH)/auto/DBI";

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

my $sx = $ENV{DBD_INFORMIX_DEBUG_ESQLTEST} ? 1 : 0;

sub execute_command
{
	my ($cmd, $msg) = @_;
	print "+ $cmd\n" if ($sx);
	die $msg unless system($cmd) == 0;
}

if ($ENV{DBD_INFORMIX_NO_ESQLTEST})
{
	print q%
	Because DBD_INFORMIX_NO_ESQLTEST is set in your environment, you
	have chosen not to run the test which verifies that your ESQL/C
	setup will allow DBD::Informix to compile and the tests to run.  If
	you run into *ANY* problems, you must verify that the esqltest
	program can be compiled and run successfully before you even think
	of asking for help.  Also make sure you've read the whole README
	file before asking the DBI/DBD community for help!

%;
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

	execute_command("$EQ -c $Config{ccflags} $opts{DEFINE} esqltest.ec",
					"Failed to compile esqltest.ec to esqltest$objext\n");
	execute_command("$EQ -c $Config{ccflags} $opts{DEFINE} $vercode.ec",
					"Failed to compile $vercode.ec to $vercode$objext\n");
	execute_command("$EQ -o esqltest esqltest$objext $vercode$objext",
					"Failed to link test program esqltest\n");
	execute_command("$RM esqltest$objext esqltest.c $vercode.c $vercode$objext",
					"Failed to remove compilation debris\n")
		unless ($sx);
	execute_command("./esqltest", $unsuccessful_test);
	execute_command("$RM esqltest$EX",
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
	print qq{
	Uh oh!  We're on a machine which does not use the C compiler to
	create shared libraries.  Please consider recompiling Perl using
	the C compiler to create shared libraries; it makes life easier for
	everyone!
	};
	if ($vernum >= 600)
	{
		print "Fortunately, you are using a new version of ESQL/C and\n";
		print "we could use 'esql -libs' to tell us which libraries to use.\n";
		print "Unfortunately, some versions of the esql script fib and\n";
		print "don't tell us the whole truth.  So we have to do a fiddly\n";
		print "workaround, editing the esql script on the fly and feeding\n";
		print "the edited version to the shell and ...  Oh, you really don't\n";
		print "really want to know what we do; it's horrid but it works!\n";
		my $esqlscript = (-f $esql) ? $esql : "$ID/bin/esql";
		my $libs = `sed 's/^[ 	]*exec/echo/' $esqlscript | sh -s dbd::ix.o`
			|| die "Couldn't execute determine the ESQL/C libraries (dammit!)";
		$libs =~ s/\n/ /gm;
		$libs =~ s/^.* dbd::ix.o //;
		print "... We are going to use the library list:\n$libs\n";
		$libs =~ s/-threads// if ($Config{osname} eq 'dec_osf');
		# On 722 on the DEC, including checkAPI twice dies.
		# Linking it once gives an undefined.  So we link once and
		# export. -- AWH et al. 4/18/97
		# Andrew Hunt (andy@toolshed.com)
# JL 98-01-13:
# Do not need to add checkapi.o because the hacked ESQL/C script above will
# have listed it.  Still need the -exported_symbol on DEC, though.  Probably.
#		$libs .= " $ID/lib/esql/checkapi.o"
#			if (-f "$ID/lib/esql/checkapi.o") &&
#				!($vernum >= 722 && $Config{osname} eq 'dec_osf');
		# Override default version of $opts{LD}
		$opts{dynamic_lib} =
			{ OTHERLDFLAGS => "-L$ID/lib -L$ID/lib/esql $libs"};
		$opts{LD} = "$Config{ld} \$(LDDLFLAGS)";
		$opts{LD} .= " -exported_symbol ifx_checkAPI"
			if ($vernum >= 722 && $Config{osname} eq 'dec_osf');
	}
	else
	{
		print "Unfortunately, you are also using a version of ESQL/C which\n";
		print "cannot tell us which libraries it needs.\n";
		print "We'll assume that esqlld can sort things out for you.\n";
		print "Contact the $opts{NAME} maintenance team if it doesn't.\n";
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

# log key platform information to help me help you quickly
print "Perl:     perl$] @Config{qw(archname dlsrc)}\n";
print "System:   @Config{qw(myuname)}\n";
print "Compiler: @Config{qw(cc optimize ccflags)}\n";
print "Loader:   $Config{ld}\n"
	if ($Config{ld} !~ /cc$/ && $Config{ld} ne $Config{cc});

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

# Assorted hints - these should be move to a hints subdirectory.
print "\nSee notes about SPARCompiler on Solaris in hints/solaris\n"
	if ($Config{osname} eq 'solaris' and &which($Config{cc}) =~ m%/SUNWspro/%);
print "\n";

# Probably cause for being thrown out of The Perl Institute, but TMTOWTDI!
system "perl t/dtgen.pl > t/dtgen.sql";
system "perl t/decgen.pl > t/decgen.sql";

WriteMakefile(%opts);

# Cleanly exit from the Makefile-build process

exit 0;

# Define a postamble for the makefile which briefs MAKE on how to compile
# ESQL/C source code.  It gives .ec rules (and files) precedence over .c
# files with the same name by zapping and reorganizing the entire suffix
# list.  The .SUFFIXES list is copied the MakeMaker constants section.
# It's a pity that changing this list cannot be handled more cleanly.  It
# doesn't really matter whether .xs files have precedence over .ec files or
# not -- it would be OK to place .ec in front of the standard list.

sub MY::postamble {
my ($p1, $p2, $p3, $p4, $p5, $p6);

$p1 = 
"
# ESQL/C compilation rules
ESQL    = $esql
ESQL_NT = $esql_nt
.SUFFIXES:
.SUFFIXES: .xs .ec .c .C .cpp .cxx .cc $objext .sh

.ec$objext:";

$p2 = '
	$(ESQL_CC) -c $(ESQLFLAGS) $*.ec
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

if ($DBI::VERSION == 0.92)
{
	print q%

You're using DBI 0.92.  I've patched the generated Makefile to work with it,
but you should upgrade to at least DBI 0.93, please.  ASAP!

%;
	$p6 = q%
$(BASEEXT)$(OBJ_EXT): $(BASEEXT).xsi
%;
}

return $p1 . $p2 . $p3 . $p4 . $p5 . $p6;
}

__END__
