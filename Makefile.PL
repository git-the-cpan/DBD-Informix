#!/usr/bin/perl -sw
#
# @(#)$Id: Makefile.PL,v 57.6 1997/11/14 03:13:08 johnl Exp $ 
#
# Portions Copyright (c) 1996,1997 Jonathan Leffler (johnl@informix.com)
# Portions Copyright (c) 1996 Alligator Descartes (descarte@arcana.co.uk)
# From an original by Tim Bunce (Tim.Bunce@ig.co.uk)
# DEC OSF/1 fix based on Dave Thomas' (Dave@Thomases.com) solution.
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the Perl README file.

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
my($split,$objext);
$objext = $Config{obj_ext};
$split = $Config{path_sep};
if ($Config{archname} eq 'MSWin32')
{
	# NT configuration...
	# Tested for Config: archname='MSWin32' osname='MSWin32' osvers='4.0'
	# Run the Makefile.NT script.  Not as neat as incorporating it into
	# this script (it's a double maintenance nightmare), but I haven't
	# worked out how to deal with the complete incompatabilities in the way
	# NT does things and the way civilized operating systems do them.
	system("perl Makefile.NT");
	exit 0;
}

$| = 1;     # Ensure that Perl output is interleaved with test output.

my %opts = (
    NAME         => 'DBD::Informix',
    VERSION_FROM => 'Informix.pm',
    clean        => { FILES        => 'Informix.xsi' },
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
print "\nConfiguring DBD::Informix version $dbd_ix...\n";
print "\tYou are using DBI version $DBI::VERSION and Perl version $]\n";
print "Remember to actually read the README file!\n\n";

my $ID = $ENV{INFORMIXDIR};

die "\n*** You didn't read the README file!\n\n"
	unless ($] >= 5.004 && $DBI::VERSION >= 0.90 && $ID);

# Compare installed version of DBI with version which DBD::Informix was
# last tested with.
# The required and reference versions are the same for this release.
my $dbi_ref_version = "0.90";
die "\n*** You must upgrade to DBI version $dbi_ref_version or later.\n\n"
	unless ($DBI::VERSION >= $dbi_ref_version);

my $IDB = "$ID/bin";

my $esqlprog = $ENV{ESQL};
$esqlprog = "esql" unless $esqlprog;
my $auxincl = "";
$auxincl = " -I$ID/incl/tools" if ($esqlprog =~ /\bc4gl\b/);

die "\n*** You didn't read the README file!\n\n"
	unless (($ENV{PATH} =~ m%:$IDB:% ||
			 $ENV{PATH} =~ m%^$IDB:% ||
			 $ENV{PATH} =~ m%:$IDB$%) &&
			-x "$IDB/$esqlprog");

# --- Find out which version of Informix ESQL/C by running 'esql -V'
open(ESQL, "$IDB/$esqlprog -V|") || die;
die "Failed to read anything from 'esql -V'\n"
	unless defined (my $infversion = <ESQL>);
while(<ESQL>) { }		# Rest of input (1 line) to avoid Broken Pipe messages
close ESQL;

chomp($infversion);
$infversion =~ s/[ 	]+$//;
(my $version = $infversion) =~ s/INFORMIX.* Version (....).*/$1/;
die "Unexpected message from esql script -- $version\n"
	unless ($version =~ /[0-9]\.[0-9][0-9]/);
(my $vernum = $version) =~ s/^([0-9])\./$1/;

print "Using $infversion from $ID\n";

# --- Check whether Informix is installed OK for us.
sub chk_libs
{
	my (@libs) = @_;
	my ($ixlib1, $ixlib2, $ixlib3, $ok) = ("$ID/lib/", "$ID/lib/esql/", "$ID/lib/tools/", 1);
	my ($lib);
	for $lib (@libs)
	{
		my ($lib1) = $ixlib1 . $lib;
		if (! -f $lib1)
		{
			my ($lib2) = $ixlib2 . $lib;
			if (! -f $lib2)
			{
				my ($lib3) = $ixlib3 . $lib;
				if (! -f $lib3)
				{
				$ok = 0;
				warn "Cannot locate $lib under $ixlib1\n";
				}
			}
		}
	}
	warn "*** Warning: ESQL/C does not appear to be installed correctly!\n\n"
		if ! $ok;
}

my $esql = "$esqlprog";
my $vercode = "esqlc_v6";
my $multiconn = 1;
if ($vernum >= 500 && $vernum < 600)
{
	&chk_libs(qw{libgen.a libos.a libsql.a});
	$vercode = "esqlc_v5";
	$multiconn = 0;
	print "You need to use a customized ESQL/C compiler script\n";
	print "which recognizes the INFORMIXC environment variable.\n";
	print "I'll create a local version and ensure that make uses it.\n\n";
	open(ESQL, "<$ID/bin/$esqlprog") ||
		die "Unable to open $ID/bin/$esqlprog for reading";
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
elsif (($vernum >= 600 && $vernum < 700) or ($vernum >= 710 && $vernum < 720))
{
	&chk_libs(qw{libgen.a libos.a libsql.a libasf.a});
}
elsif ($vernum >= 720 && $vernum < 800)
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
elsif ($vernum >= 900 && $vernum < 912)
{
	# 9.00 through 9.11 are released.
	&chk_libs(qw{libixgen.a libixos.a libixsql.a libixcss.a libixglx.a
				 libixgls.a libixasf.a});
}
elsif ($vernum >= 912 && $vernum < 1000)
{
	# 9.12 is released; 9.20 is in the pipeline
	# The libraries got renamed extensively...
	&chk_libs(qw{libifgen.a libifos.a libifsql.a libifcss.a libifglx.a
				 libifgls.a libifasf.a});
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
my @hdrs = ("qeodbc.h", "sqlext.h", "sql.h");
my @dirs = ("cli/include", "incl", "incl/esql", "odbc/include");
my $fcnt = 0;
my ($hdr, $dir, $name, %subd, %incd, $inst_odbc);
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
	for (my $i = 1; $i < @hdrs; $i++)
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
my $versionfile = "esqlvrsn.h";
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

my $objects = "Informix.o dbdimp.o dbdattr.o";
$objects .= " sqltype.o ixblob.o decsci.o odbctype.o link.o $vercode.o";
$objects =~ s/\.o\w/$objext/g if ($objext ne ".o");

# Need to pick up the DBI headers.
# NB: If using ESQL/C 4.xy, use -I$ID/incl, not -I$ID/incl/esql!
# However, you've got other major work to do to handle 4.xy ESQL/C.
# With DBI-0.77 and up, DBIXS.h is in an auto sub-directory.

my $INC1 = "-I$ID/incl/esql$auxincl";
my $inc_pad = "/auto" if ($DBI::VERSION >= 0.77);
my $INC2 = "-I\$(INSTALLSITEARCH)$inc_pad/DBI";

$opts{INC} .= " $INC1 $INC2";
$opts{OBJECT} = $objects;

##############################
# - Start of ESQLTEST code - #
##############################

###########################################################################
# Check that the ESQL/C program esqltest can be compiled and run OK.
# NB: test does not need any Perl headers (but don't pollute esqlperl.h)
#     with anything that needs a Perl header.
# Remove this code if you run into irresolvable problems with shared memory
# connections after you've read the README.olipcshm file.
print "Testing whether your Informix test environment will work...\n";
my $sx = $ENV{DBD_INFORMIX_DEBUG_ESQLTEST} ? "set -x;" : "";
my $nr = $ENV{DBD_INFORMIX_DEBUG_ESQLTEST} ? "set -x; :" : "";
my $ESQL = "INFORMIXC='$Config{perlpath} esqlcc' ESQLCC='$Config{cc}' $esql";
die "Failed to compile basic test program esqltest" unless
	((system "$sx $ESQL -c $Config{ccflags} $opts{DEFINE} esqltest.ec") == 0 &&
	 (system "$sx $ESQL -c $Config{ccflags} $opts{DEFINE} $vercode.ec") == 0 &&
	 (system "$sx $ESQL -o esqltest esqltest.o $vercode.o") == 0 &&
	 (system "$nr rm -f esqltest.o esqltest.c $vercode.c $vercode.o") == 0);
if ((system "./esqltest") != 0)
{
	die "You do not have enough permissions in your Informix environment.\n" .
		"Make sure you've read the whole README file before asking the\n" .
		"DBI/DBD community for help!\n";
}
die "Failed to remove esqltest program" unless
	(system "$nr rm -f esqltest") == 0;
###########################################################################

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

if ($Config{ld} !~ /cc$/ && $Config{ld} ne $Config{cc})
{
	print "Uh oh!  We're on a machine which does not use the C compiler to\n";
	print "create shared libraries.\n";
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
		print "Unfortunately, you are also using a version of ESQL/C which\n";
		print "cannot tell us which libraries it needs.\n";
		print "We'll assume that esqlld can sort things out for you.\n";
		print "Contact the DBD::Informix maintenance team if it doesn't.\n";
		# Do not override default version of $opts{LD}
	}
	print "\n";
}

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

# which: report the name of an executable command.
sub which
{
	my ($cmd, $path) = @_;
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
my ($p1, $p2, $p3);

$p1 = 
"
# ESQL/C compilation rules
ESQL = $esql
.SUFFIXES:
.SUFFIXES: .xs .ec .c .C .cpp .cxx .cc $objext .sh

.ec$objext:";

$p2 = '
	$(ESQL_CC) -c $(ESQLFLAGS) $*.ec
	$(RM_F) $*.c

# Cribbed from the definition of CCCMD (MakeMaker const_cccmd) and the
# rules for compiling object files (MakeMakerc_o) in the Makefile.
# May need fixing if the corresponding rules change.
ESQLFLAGS = $(INC) $(CCFLAGS) $(OPTIMIZE) \
		$(PERLTYPE) $(LARGE) $(SPLIT) $(DEFINE_VERSION) \
		$(XS_DEFINE_VERSION) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE)
ESQL_CC     = INFORMIXC="$(FULLPERL) esqlcc" ESQLCC="${CC}" $(ESQL)
# ESQL_LD is not used (but ideally should be)
ESQL_LD     = INFORMIXC="$(FULLPERL) esqlld" ESQLLD="${LD}" $(ESQL)
MAP_LINKCMD = $(ESQL_CC)

# Need to move the esql script created locally (in case the next build
# uses a version of ESQL/C which does not need the custom esql script).
clean::
	-[ ! -f esql ] || mv esql esql.old
';

# Standardised code to generate Informix.xs from Informix.xsi and the
# template from DBI (Driver.xst).  dbd_postamble() is defined by DBI::DBD.
$p3 = dbd_postamble();

return $p1 . $p2 . $p3;
}

__END__
