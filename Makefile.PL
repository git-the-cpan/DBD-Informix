#!/usr/bin/perl -sw
#
# @(#)Makefile.PL	55.1 97/05/20 11:50:49
#
# Portions Copyright (c) 1996,1997 Jonathan Leffler (johnl@informix.com)
# Portions Copyright (c) 1996 Alligator Descartes (descarte@hermetica.com)
# From an original by Tim Bunce
# DEC OSF/1 fix based on Dave Thomas' (Dave@Thomases.com) solution.
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the Perl README file.

use ExtUtils::MakeMaker qw(&WriteMakefile $Verbose);
use Config;
# A sufficiently recent version of DBI must be installed before we can
# build any DBD module.  The code uses ChopBlanks introduced in DBI 0.81.
use DBI 0.81;

$| = 1;     # Ensure that Perl output is interleaved with test output.

%opts = (
	'NAME'         => 'DBD::Informix',
	'VERSION_FROM' => 'Informix.pm',
);

print "\nConfiguring DBD::Informix...\n";
print "Remember to actually read the README file!\n\n";

$ID = $ENV{INFORMIXDIR};

die "\n*** You didn't read the README file!\n\n"
	unless ($] >= 5.003 && $DBI::VERSION >= 0.81 && $ID);

# Compare installed version of DBI with version which DBD::Informix was
# last tested with.
$dbi_ref_version = "0.81";
die "\n*** You must upgrade to DBI version $dbi_ref_version or later.\n\n"
	unless ($DBI::VERSION >= $dbi_ref_version);

$IDB = "$ID/bin";

die "\n*** You didn't read the README file!\n\n"
	unless (($ENV{PATH} =~ m%:$IDB:% ||
			 $ENV{PATH} =~ m%^$IDB:% ||
			 $ENV{PATH} =~ m%:$IDB\$%) &&
			-x "$IDB/esql");

# --- Find out which version of Informix ESQL/C by running 'esql -V'
open(ESQL, "$IDB/esql -V|") || die;
die "Failed to read anything from 'esql -V'\n"
	unless defined ($infversion = <ESQL>);
while(<ESQL>) { }		# Rest of input (1 line) to avoid Broken Pipe messages
close ESQL;

chomp($infversion);
$infversion =~ s/[ 	]+$//;
($version = $infversion) =~ s/INFORMIX.* Version (....).*/$1/;
die "Unexpected message from esql script -- $version\n"
	unless ($version =~ /[0-9]\.[0-9][0-9]/);
($vernum = $version) =~ s/^([0-9])\./$1/;

print "Using $infversion from $ID\n";

# --- Check whether Informix is installed OK for us.
sub chk_libs
{
	my (@libs) = @_;
	my ($ixlib1, $ixlib2, $ok) = ("$ID/lib/", "$ID/lib/esql/", 1);
	for $lib (@libs)
	{
		my ($lib1) = $ixlib1 . $lib;
		if (! -f $lib1)
		{
			my ($lib2) = $ixlib2 . $lib;
			if (! -f $lib2)
			{
				$ok = 0;
				warn "Cannot locate $lib under $ixlib1\n";
			}
		}
	}
	warn "*** Warning: ESQL/C does not appear to be installed correctly!\n\n"
		if ! $ok;
}

$esql = "esql";
$vercode = "esqlc_v6";
$multiconn = 1;
if ($vernum >= 500 && $vernum < 510)
{
	&chk_libs(qw{libgen.a libos.a libsql.a});
	$vercode = "esqlc_v5";
	$multiconn = 0;
	print "You need to use a customized ESQL/C compiler script\n";
	print "which recognizes the INFORMIXC environment variable.\n";
	print "I'll create a local version and ensure that make uses it.\n\n";
	open(ESQL, "<$ID/bin/esql") ||
		die "Unable to open $ID/bin/esql for reading";
	$esql = "./esql";
	open(LOCAL, ">$esql") ||
		die "Unable to open $esql for writing";
	while (<ESQL>)
	{
		if (/^CC=/o && !/INFORMIXC/o)
		{
			print LOCAL "# INFORMIXC added by Makefile.PL for DBD::Informix.\n";
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
	chmod 0755, $esql;
}
elsif (($vernum >= 600 && $vernum < 610) or ($vernum >= 710 && $vernum < 720))
{
	&chk_libs(qw{libgen.a libos.a libsql.a libasf.a});
}
elsif ($vernum >= 720 && $vernum < 740)
{
	# 7.2x is already released; 7.3x is in the pipeline
	&chk_libs(qw{libixgen.a libixos.a libixsql.a libixgls.a libixasf.a});
}
elsif ($version =~ /[1-4]\.[01][0-9]/)
{
	die qq{
	$infversion does not support string-named cursors.
	This version of DBD::Informix requires this facility.
	Please report your requirement to the DBD::Informix maintenance team.
	}
}
elsif ($vernum >= 900 && $vernum < 930)
{
	# 9.10 is released; 9.20 is in the pipeline
	&chk_libs(qw{libixgen.a libixos.a libixsql.a libixcss.a libixglx.a
				 libixgls.a libixasf.a});
}
else
{
	die qq{
	I do not know anything about $infversion.
	Please report this to the DBD::Informix maintenance team.
	However, if it is later than 5.00, there is a fair chance that
	DBD::Informix will work if you modify the code in Makefile.PL which
	contains this message to recognize your version.  If you have a
	5.1x release, then you should be fine treating it as a 5.0x
	release.  If you have an 8.0x release, you may need to treat it as
	7.1x or 7.2x; if you have 9.0x or later, there is likely to be a lot
	of functionality in the database which DBD::Informix does not know
	how to handle, but you should try treating it like 7.2x.  You might
	need to update (or remove) the library check.
	}
}

# -- Configure the make process

# Define the version of ESQL/C for the object code.
$opts{DEFINE}  = " -DESQLC_VERSION=$vernum";

# Can we locate the CLI headers qeodbc.h, sqlext.h and sql.h?
# If so, we'll use them.  If not, we use inc/odbctype.h instead.
# The code in odbctype.c expects to be given SQLEXT_H_FILENAME
print "\nChecking to see whether you have Informix-CLI (ODBC) installed.\n";
@hdrs = ("qeodbc.h", "sqlext.h", "sql.h");
@dirs = ("cli/include", "incl", "incl/esql", "odbc/include");
$fcnt = 0;
foreach $hdr (@hdrs)
{
	foreach $dir (@dirs)
	{
		$name = "$ID/$dir/$hdr";
		if (-r $name)
		{
			$fcnt++;
			$subd{$hdr} = $dir;
			print "\tFound $name\n";
			last;
		}
	}
}
if ($fcnt == @hdrs)
{
	print "You've got Informix-CLI or equivalent ODBC software installed.\n";
	print "$opts{NAME} will use the headers @hdrs.\n";
	$opts{INC} = "-I$ID/$subd{$hdrs[0]}";
	$incd{$subd{$hdrs[0]}} = 1;
	for ($i = 1; $i < @hdrs; $i++)
	{
		if ($subd{$hdrs[0]} ne $subd{$hdrs[$i]})
		{
			print "...That's odd; $hdrs[0] is in a different";
			print " directory from $hdrs[$i]\n";
			unless ($incd{$subd{$hdrs[$i]}})
			{
				$opts{INC} .= " -I$ID/$subd{$hdrs[$i]}";
				$incd{$subd{$hdrs[$i]}} = 1;
			}
		}
	}
	$inst_odbc = 1;
}
else
{
	print "You don't seem to have the Informix-CLI software installed.\n";
	print "Never mind; I'll use the home-brew header odbctype.h instead.\n";
	$inst_odbc = 0;
	$opts{INC} = " ";
}
print "\n";

# The ESQL/C script does not handle options with spaces and quotes, dammit!
# Hence, create $versionfile to contain ESQLC_VERSION_STRING.
# Also use it to decide whether ODBC is available or not.
{
$versionfile = "esqlvrsn.h";
unlink $versionfile;
die "Unable to open $versionfile for writing\n"
	unless open(VERSION, ">$versionfile");
print VERSION "#define ESQLC_VERSION_STRING \"$infversion\"\n";
if (defined $inst_odbc)
{
	print VERSION "#ifndef USE_INSTALLED_ODBC\n";
	print VERSION "#define USE_INSTALLED_ODBC $inst_odbc\n";
	print VERSION "#endif /* USE_INSTALLED_ODBC */\n";
}
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

# We need to add -Ae on HP-UX to ensure that prototypes are accepted.
$opts{DEFINE} .= " -Ae"
	if $Config{osname} eq "hpux" and $Config{ccflags} !~ /-A[ea]/;

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

$objects = "Informix.o dbdimp.o dbdattr.o";
$objects .= " sqltype.o ixblob.o decsci.o odbctype.o link.o $vercode.o";

# Need to pick up the DBI headers.
# NB: If using ESQL/C 4.xy, use -I$ID/incl, not -I$ID/incl/esql!
# However, you've got other major work to do to handle 4.xy ESQL/C.
# With DBI-0.77 and up, DBIXS.h is in an auto sub-directory.

$INC1 = "-I$ID/incl/esql";
$inc_pad = "/auto" if ($DBI::VERSION >= 0.77);
$INC2 = "-I\$(INSTALLSITEARCH)$inc_pad/DBI";

$opts{INC} .= " $INC1 $INC2";
$opts{OBJECT} = $objects;

###########################################################################
# Check that the ESQL/C program esqltest can be compiled and run OK.
# NB: test does not need any Perl headers (but don't pollute esqlperl.h)
#     with anything that needs a Perl header.
print "Testing whether your Informix test environment will work...\n";
$sx = $ENV{DBD_INFORMIX_DEBUG_ESQLTEST} ? "set -x;" : "";
$nr = $ENV{DBD_INFORMIX_DEBUG_ESQLTEST} ? "set -x; :" : "";
$ESQL = "INFORMIXC='$Config{perlpath} esqlcc' ESQLCC='$Config{cc}' $esql";
die "Failed to compile basic test program esqltest" unless
	((system "$sx $ESQL -c $Config{ccflags} $opts{DEFINE} esqltest.ec") == 0 &&
	 (system "$sx $ESQL -c $Config{ccflags} $opts{DEFINE} $vercode.ec") == 0 &&
	 (system "$sx $ESQL -o esqltest esqltest.o $vercode.o") == 0 &&
	 (system "$nr rm -f esqltest.o esqltest.c") == 0);
if ((system "./esqltest") != 0)
{
	die "You do not have enough permissions in your Informix environment.\n";
}
die "Failed to remove esqltest program" unless
	(system "$nr rm -f esqltest") == 0;
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

if ($Config{ld} !~ /cc$/ && $Config{ld} ne $Config{cc})
{
	print "Uh oh!  We're on a machine which does not use the C compiler to\n";
	print "create shared libraries.\n";
	if ($vernum >= 600)
	{
		print "Fortunately, you are using a new version of ESQL/C and\n";
		print "we can use 'esql -libs' to tell us which libraries to use.\n";
		my $libs = `esql -libs` || die "Couldn't execute 'esql -libs'";
		$libs =~ s/\n/ /gm;
		$libs =~ s/-threads// if ($Config{osname} eq 'dec_osf');
		# On 722 on the DEC, including checkAPI twice dies.
		# Linking it once gives an undefined.  So we link once and
		# export. -- AWH et al. 4/18/97
		# Andrew Hunt (andy@toolshed.com)
		$libs .= " $ID/lib/esql/checkapi.o"
			if (-f "$ID/lib/esql/checkapi.o") &&
				!($vernum >= 722 && $Config{osname} eq 'dec_osf');
		# Override default version of $opts{LD}
		$opts{dynamic_lib} = { OTHERLDFLAGS => "-L$ID/lib -L$ID/lib/esql $libs"};
		$opts{LD} = "$Config{ld} \$(LDDLFLAGS)";
		$opts{LD} .= " -exported_symbol ifx_checkAPI"
			if ($vernum >= 722 && $Config{osname} eq 'dec_osf');
	}
	else
	{
		print "Unfortunately, you are using a version of ESQL/C which does\n";
		print "not have a mechanism to tell us which libraries it needs.\n";
		print "We'll assume that esqlld can sort things out for you.\n";
		print "Contact the DBD::Informix maintenance team if it doesn't.\n";
		# Do not override default version of $opts{LD}
	}
}

# Ensure that esqlcc, esqlld, esqlsed are executable
for $file (qw(esqlcc esqlld esqlsed))
{
	if (! -x $file)
	{
		$mode = (stat $file)[2] | 0111;
		chmod $mode, $file;
	}
}

# log key platform information to help me help you quickly
print "Perl:     perl$] @Config{qw(archname dlsrc)}\n";
print "System:   @Config{qw(myuname)}\n";
print "Compiler: @Config{qw(cc optimize ccflags)}\n";

# which: report the name of an executable command.
sub which
{
	my ($cmd, $path) = @_;
	$path = $ENV{PATH} if (!$path);
	my @path = split /:/, $path;
	for $dir (@path)
	{
		$dir = '.' if (!$dir);
		$name = $dir . "/" . $cmd;
		return $name if -x $name;
	}
	return "";
}

# Assorted hints - these should be move to a hints subdirectory.
print "\nSee README notes about SPARCompiler on Solaris\n"
	if ($Config{osname} eq 'solaris' and &which($Config{cc}) =~ m%/SUNWspro/%);
print "\n";

# Probably cause for being thrown out of The Perl Institute, but TMTOWTDI!
system "perl t/dtgen.pl > t/dtgen.sql";
system "perl t/decgen.pl > t/decgen.sql";

WriteMakefile(%opts, dist => { COMPRESS => 'gzip', SUFFIX => 'gz' });

# Define a postamble for the makefile which briefs MAKE on how to compile
# ESQL/C source code.  It gives .ec rules (and files) precedence over .c
# files with the same name by zapping and reorganizing the entire suffix
# list.  The .SUFFIXES list is copied the MakeMaker constants section.
# It's a pity that changing this list cannot be handled more cleanly.  It
# doesn't really matter whether .xs files have precedence over .ec files or
# not -- it would be OK to place .ec in front of the standard list.

sub MY::postamble {
"
# ESQL/C compilation rules
ESQL = $esql
" . 
'
.SUFFIXES:
.SUFFIXES: .xs .ec .c .C .cpp .cxx .cc $(OBJ_EXT)

# Cribbed from the definition of CCCMD (MakeMaker const_cccmd) and the
# rules for compiling object files (MakeMakerc_o) in the Makefile.
ESQLFLAGS = $(INC) $(CCFLAGS) $(OPTIMIZE) \
		$(PERLTYPE) $(LARGE) $(SPLIT) $(DEFINE_VERSION) \
		$(XS_DEFINE_VERSION) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE)
ESQL_CC     = INFORMIXC="$(FULLPERL) esqlcc" ESQLCC="${CC}" $(ESQL)
# ESQL_LD is not used (but ideally should be)
ESQL_LD     = INFORMIXC="$(FULLPERL) esqlld" ESQLLD="${LD}" $(ESQL)
MAP_LINKCMD = $(ESQL_CC)

.ec.o:
	$(ESQL_CC) -c $(ESQLFLAGS) $*.ec
	$(RM_F) $*.c
'
}

# Cleanly exit from the Makefile-build process

exit 0;

__END__
