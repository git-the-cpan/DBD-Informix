#!/usr/bin/perl -sw
#
# @(#)Makefile.PL	52.3 97/03/05 15:45:05
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

%opts = (
	'NAME'    => 'DBD::Informix',
	'VERSION' => '0.52',
);

print "\nConfiguring DBD::Informix version $opts{VERSION}...\n";
print "Remember to actually read the README file!\n\n";
die "\n*** You didn't read the README file!\n\n" unless ($] >= 5.003);

# A sufficiently recent version of DBI must be installed before we can
# build any DBD module
use DBI;
require_version DBI 0.69;

# --- Where is Informix installed...

unless ($ENV{INFORMIXDIR}){
    warn "\$INFORMIXDIR not defined. Searching for Informix...\n";
    foreach(qw(/usr/informix /opt/informix /home/informix /opt/Informix))
	{
		$ENV{'INFORMIXDIR'} = $_, last if (-d "$_/lib");
    }
    die "Unable to determine \$INFORMIXDIR!\n" unless $ENV{INFORMIXDIR};
	print "Please set INFORMIXDIR in your environment before building.\n"
		if $ENV{INFORMIXDIR} != "/usr/informix";
}
my $ID = $ENV{INFORMIXDIR};

# Ensure $INFORMIXDIR/bin is on PATH.
$ENV{PATH} .= ":$ENV{INFORMIXDIR}/bin"
	if $ENV{PATH} !~ m%$ENV{INFORMIXDIR}/bin%;

# --- Find out which version of Informix ESQL/C by running 'esql -V'
open(ESQL, "esql -V|") || die;
die "Failed to read anything from 'esql -V'\n"
	unless ($infversion = <ESQL>);
while(<ESQL>) { }		# Rest of input (1 line) to avoid Broken Pipe messages
close ESQL;

chomp($infversion);
$infversion =~ s/[ 	]+$//;
($version = $infversion) =~ s/INFORMIX.* Version (....).*/$1/;
die "Unexpected message from esql script $version"
	unless ($version =~ /[0-9]\.[0-9][0-9]/);
($vernum = $version) =~ s/^([0-9])\./$1/;

print "Using $infversion from $ID\n";

# --- Check whether Informix is installed OK for us.
sub chk_libs
{
	my (@libs) = @_;
	my ($ixlib, $ok) = ("$ID/lib/", 1);
	for $lib (@libs)
	{
		$ok = 0 if ! -f $ixlib . $lib;
	}
	warn "*** Warning: ESQL/C does not appear to be installed correctly!\n\n"
		if ! $ok;
}

$esql = "esql";
$vercode = "esqlc_v6.o";
$multiconn = 1;
if ($vernum >= 500 && $vernum < 510)
{
	&chk_libs(qw{esql/libgen.a esql/libos.a esql/libsql.a});
	$vercode = "esqlc_v5.o";
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
	&chk_libs(qw{esql/libgen.a esql/libos.a esql/libsql.a libasf.a});
}
elsif ($vernum >= 720 && $vernum < 740)
{
	# 7.2x is already released; 7.3x is in the pipeline
	&chk_libs(qw{esql/libixgen.a esql/libixos.a esql/libixsql.a
				 esql/libixgls.a libixasf.a});
}
elsif ($version =~ /[1-4]\.[01][0-9]/)
{
	die qq{
	$infversion does not support string-named cursors.
	This version of DBD::Informix requires this facility.
	Please report your requirement to the DBD::Informix maintenance team.
	}
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

# -- Produce correctly configured Informix.pm file

{
	print "\nWriting Informix.pm\n";
	my ($vn, $pn, $pv, $cc) = (0, 0, 0, 0);
	my $input  = "Informix.PM";
	my $output = "Informix.pm";
	my $kvn = "VERSION";
	my $kpn = "PRODUCTNAME";
	my $kpv = "PRODUCTVERSION";
	my $kcc = "MultipleConnections";

	open(PM_IN, "<$input") or die "Failed to open file $input";
	open(PM_OUT, ">$output") or die "Failed to open file $output";
	while (<PM_IN>)
	{
		$vn == 0 and s/\$$kvn[ \t]*=.*;/\$$kvn = "$opts{VERSION}";/o and $vn++;
		$pn == 0 and s/\$$kpn[ \t]*=.*;/\$$kpn = "$infversion";/o and $pn++;
		$pv == 0 and s/\$$kpv[ \t]*=.*;/\$$kpv = "$vernum";/o and $pv++;
		$cc == 0 and s/\$$kcc[ \t]*=.*;/\$$kcc = "$multiconn";/o and $cc++;
		print PM_OUT;
	}
	print "\n";
}

# -- Configure the make process

# Define the version of ESQL/C for the object code.
$opts{DEFINE}  = " -DESQLC_VERSION=$vernum";

# The ESQL/C script does not handle options with spaces and quotes, dammit!
# Hence, create $versionfile to contain ESQLC_VERSION_STRING.
{
$versionfile = "esqlvrsn.h";
unlink $versionfile;
die "Unable to open $versionfile for writing\n"
	unless open(VERSION, ">$versionfile");
print VERSION "#define ESQLC_VERSION_STRING \"$infversion\"\n";
close VERSION;
}

# Add extra definitions to compile the code under GCC if DBD_GCC_DEBUG set.
# Perl configuration headers contain lots of /* inside comments (-Wno-comment)
#$opts{DEFINE} .= ' -Wall -pedantic -Wno-comment -Wpointer-arith -Wcast-align'
#	    . ' -Wconversion -Wtraditional -Wcast-qual'
$opts{DEFINE} .= ' -Wall -pedantic -Wno-comment'
	if $Config{cc} eq 'gcc' and $ENV{DBD_GCC_DEBUG};

# Extra definitions to compiler the code under CenterLine CC.
$opts{DEFINE} .= ' -Xa'
	if $Config{cc} eq 'clcc';

# Extra definitions under Alpha cc to get __STDC__ defined
$opts{DEFINE} .= ' -std1'
	if (($Config{cc} eq 'cc') && ($Config{osname} eq 'dec_osf'));

# Workaround Informix bug B08223 (aka B14937, and other numbers too)
# AIX localedef31.h defines a loc_t and is used by some system headers.
# Informix locator.h also defines a loc_t.  The workaround is to prevent
# the localedef31.h declaration from being included.
$opts{DEFINE} .= " -D__H_LOCALEDEF"
	if ($Config{osname} eq 'aix');

# The Informix headers (like sqlhdr.h) only generate function prototypes if
# __STD__ is defined.  Without function prototypes, we are often passing
# pointers to _iq.. functions that the compiler thinks are ints.  This
# causes incorrect code to be generated on a 64-bit DEC Alpha with any
# optimization level greater than -O1.  So, if the compiler supports
# prototypes, we'll add -DUSE_PROTOTYPES to the command line.  The code in
# esqlc.h (version 1.9 and later) handles this mess for us.

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

$objects = "Informix.o sqltype.o ixblob.o decsci.o dbdimp.o dbdattr.o link.o $vercode";

# Need to pick up the DBI headers.
# NB: If using ESQL/C 4.xy, use -I$ID/incl, not -I$ID/incl/esql!
# However, you've got other major work to do to handle 4.xy ESQL/C.
# With DBI-0.77 and up, DBIXS.h is in an auto sub-directory.
 
$INC1 = "-I$ID/incl/esql";
$INC2 = "-I$Config{archlib}/DBI";
$inc_pad = "/auto" if ($DBI::VERSION >= 0.77);
$INC3 = "-I$Config{sitearch}$inc_pad/DBI";

$opts{INC} = "$INC1 $INC2 $INC3";
$opts{OBJECT} = $objects;

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
		$libs .= " $ID/lib/esql/checkapi.o" if (-f "$ID/lib/esql/checkapi.o");
		# Override default version of $opts{LD}
		$opts{dynamic_lib} = { OTHERLDFLAGS => "-L$ID/lib -L$ID/lib/esql $libs"};
		$opts{LD} = "$Config{ld} \$(LDDLFLAGS)";
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

# Dependency and rebuild rule for Informix.pm.
# It is entirely negotiable whether this approach to handling version
# information is a good idea -- I am not convinced, but I am not sure
# how else to get the information I want into the the system.
#
# This rule is cribbed from the MakeMaker makefile section.
#
# We take a very conservative approach here, but it is worth it.
# We move Makefile to Makefile.old here to avoid gnu make looping.
Informix.pm : Informix.PM Makefile.PL $(CONFIGDEP)
	@echo "$@ is out-of-date with respect to $?"
	@echo "Cleaning current config before rebuilding $@..."
	-@mv Makefile Makefile.old
	-$(MAKE) -f Makefile.old clean >/dev/null 2>&1 || true
	$(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" Makefile.PL 
	@echo ">>> Your Makefile and Informix.pm have been rebuilt. <<<"
	@echo ">>>          Please rerun the make command.          <<<"; false
'
}

# Cleanly exit from the Makefile-build process

exit 0;

__END__
