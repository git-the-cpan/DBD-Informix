#!/usr/local/bin/perl -sw
# $Id: Makefile.PL,v 1.21 1995/06/22 00:37:04 timbo Rel $
#
# Modification History:
# By:		Date:		Description:

use ExtUtils::MakeMaker qw(&WriteMakefile $Verbose %att);
use Getopt::Std;
use Config;

use DBI;	# The DBI must be installed before we can build a DBD

%opts = (
    'NAME'    => 'DBD::Informix',
    'VERSION' => '0.20pl0',
);

# Options, typically only used for debugging
#$opt_m = '';		# path to proc.mk or oracle.mk file to read

#getopts('m:') or die "Invalid arguments";

# --- Introduction

print "\nConfiguring DBD::Informix version $opts{VERSION}...\n";
print "Remember to actually read the README file!\n\n";

# --- Where is Informix installed...

unless ($ENV{INFORMIXDIR}){
    warn "\$INFORMIXDIR not defined. Searching for Informix...\n";
    foreach(qw(/usr/Informix /opt/Informix /usr/soft/Informix)){
	$ENV{INFORMIXDIR}=$_,last if -d "$_/lib/esql";
    }
    die "Unable to determine \$INFORMIXDIR!\n" unless $ENV{INFORMIXDIR};
}
my $ID = $ENV{INFORMIXDIR};

print "Using Informix in $ID\n";

# --- What Informix is installed...

# Validate we have the right stuff installed

warn "Warning: Informix library does not appear to be installed.\n"
	unless -f "$ID/lib/esql/libgen.a"
           and -f "$ID/lib/esql/libos.a"
           and -f "$ID/lib/esql/libsql.a";

# read list of libs that oracle requires (eg -lm -lnsl)
$sysliblist = "-L$ID/lib/esql -lsql -lgen -los -lm";
print "Informix sysliblist: $sysliblist\n";

#$oraclemk = $opt_m || "$OH/proc/lib/proc.mk";
# Apparently some Oracle 7.1.3 Pro*C makefiles might be here:
#$oraclemk = "$OH/proc16/lib/proc16.mk" unless -f $oraclemk;
#die "Unable to locate proc.mk (use -m /path/to/proc.mk to specify)\n"
#    unless -f $oraclemk;
# We need -R if we're on Solaris.....

if ( $Config{osname} eq 'solaris' ) {
    $linkwith = "-L$ID/lib -R$ID/lib";
  } else {
    $linkwith = "-L$ID/lib";
  }
 
#print "Using $oraclemk version $MK{mkver}\n";

#$OCIINCLUDE = $MK{INCLUDE} || '';

$opts{LIBS} = [ $sysliblist ];
$opts{INC}  = "-I$ID/include -I$Config{archlib}/DBI";
#$opts{dynamic_lib} = { OTHERLDFLAGS => '-L$(LIBHOME)' .$linkwith };
$opts{dynamic_lib} = { OTHERLDFLAGS => '-L$(INFORMIXDIR)/lib ' .$linkwith };
$opts{OBJECT} = '$(O_FILES) dbdimp.o';
$opts{macro} = { 'ESQL_LIB' => '$(INFORMIXDIR)/include' };

# --- Handle special cases ---

# Since HPUX can't mix -pic & non-pic (.a) in a dynamically loadable
# file and oracle only supply .a libs we have to build static.
if ($Config{osname} eq 'hpux' || $Config{osname} eq 'i386-sysv' ) {
    print "Warning: forced to build static not dynamic on $Config{osname}\n";
    print "         See README file for more information.\n";
    $opts{LINKTYPE} = 'static';
}

$opts{DEFINE} = '-Wall -pedantic -Wno-comment -Wpointer-arith -Wcast-align'
	    . ' -Wconversion -Wtraditional -Wpointer-arith'
	    . ' -Wcast-qual'
	if $Config{cc} eq 'gcc';	# Just me asking gcc to be paranoid.

$opts{DEFINE} .= ' -Xa' if $Config{cc} eq 'clcc';	# CenterLine CC


# Set some private WriteMakefile options if this is 'me' :-)
if ($ENV{LOGNAME} eq 'timbo' and $ENV{S_ARCH_SW}){  # a reasonable guess
    $Verbose = 1;
    $opts{INST_LIB}     = $Config{installprivlib};
    $opts{INST_ARCHLIB} = $Config{installarchlib};
}

# log key platform information to help me help you quickly
print "System: perl$] @Config{qw(myuname archname dlsrc)}\n";
print "Compiler: @Config{qw(cc optimize ccflags)}\n";

# Assorted hints - these should be move to a hints subdirectory
print "See README notes about SPARCompiler on Solaris\n"
    if -d "/opt/SUNWspro/bin" and $Config{osname} eq 'solaris';

print "\n";

WriteMakefile(%opts);

exit 0;

__END__
