#!/usr/local/bin/perl -sw
# $Id: Makefile.PL,v 1.1 1996/04/14 17:25:11 descarte Exp descarte $
#
# (c)1996 Hermetica. Written by Alligator Descartes <descarte@hermetica.com>
# From an original by Tim Bunce
#
# Covered by GPL - License to be added!
#
# $Log: Makefile.PL,v $
# Revision 1.1  1996/04/14 17:25:11  descarte
# Initial revision
#

use ExtUtils::MakeMaker qw(&WriteMakefile $Verbose);
use Getopt::Std;
use Config;

use DBI;	# The DBI must be installed before we can build a DBD

%opts = (
    'NAME'    => 'DBD::Informix',
    'VERSION' => '0.24',
);

print "\nConfiguring DBD::Informix version $opts{VERSION}...\n";
print "Remember to actually read the README file!\n\n";

# --- Where is Informix installed...

unless ($ENV{INFORMIXDIR}){
    warn "\$INFORMIXDIR not defined. Searching for Informix...\n";
    foreach(qw(/usr/informix /opt/informix /usr/soft/informix)){
	$ENV{INFORMIXDIR}=$_,last if -d "$_";
    }
    die "Unable to determine \$INFORMIXDIR!\n" unless $ENV{INFORMIXDIR};
}
my $ID = $ENV{INFORMIXDIR};

print "What version of Informix are you using? [5/6/7] ";
open TTY, "/dev/tty";
$infversion = <TTY>;
chomp( $infversion );
close TTY;

print "Using Informix version $infversion in $ID\n";

# --- What Informix is installed...

# Validate we have the right stuff installed

if ( $infversion eq '5' ) {
    warn "Warning: Informix library does not appear to be installed.\n"
    	unless -f "$ID/lib/esql/libgen.a"
               and -f "$ID/lib/esql/libos.a"
               and -f "$ID/lib/esql/libsql.a";
    $sysliblist = "-L$ID/lib/esql -lsql -lgen -los -lm";
  } else {
        if ( $infversion eq '6' || $infversion eq '7' ) {
            warn "Warning: Informix library does not appear to be installed.\n"
                unless -f "$ID/lib/esql/libgen.a"
                   and -f "$ID/lib/esql/libos.a"
                   and -f "$ID/lib/esql/libsql.a"
                   and -f "$ID/lib/libasf.a";
            $sysliblist = "-L$ID/lib -L$ID/lib/esql -lsql -lasf -lgen -los -lm";
          }
  }

# Display the list of libs that we reckon the stated version of Informix 
# - requires to build
print "Informix sysliblist: $sysliblist\n";

$ccflags = "";			# Fudge to get round HP-UX brain-death
if ( $Config{osname} eq 'solaris' ) {
    $linkwith = "-L$ID/lib -R$ID/lib -L$ID/lib/esql -R$ID/lib/esql";
  } else {
    if ( $Config{osname} eq 'aix' ) {
        $linkwith = "-L$ID/lib -lbsd";
      } else {
        if ( $Config{osname} eq 'hpux' ) {
            $ccflags = $Config{ccflags};
          }
        $linkwith = "-L$ID/lib";
      }
  }
 
$opts{LIBS} = [ $sysliblist ];
$opts{INC}  = "-I$ID/incl/esql -I$Config{archlib}/DBI -I$Config{sitearch}/DBI";
$opts{dynamic_lib} = { OTHERLDFLAGS => '-L$(INFORMIXDIR)/lib ' .$linkwith };
$opts{OBJECT} = '$(O_FILES) dbdimp.o';
$opts{macro} = { 'ESQL_LIB' => '$(INFORMIXDIR)/include' };

$opts{DEFINE} = '-Wall -pedantic -Wno-comment -Wpointer-arith -Wcast-align'
	    . ' -Wconversion -Wtraditional -Wpointer-arith'
	    . ' -Wcast-qual'
	if $Config{cc} eq 'gcc';	# Just me asking gcc to be paranoid.

$opts{DEFINE} .= ' -Xa' if $Config{cc} eq 'clcc';	# CenterLine CC

# log key platform information to help me help you quickly
print "System: perl$] @Config{qw(myuname archname dlsrc)}\n";
print "Compiler: @Config{qw(cc optimize ccflags)}\n";

# Assorted hints - these should be move to a hints subdirectory
print "See README notes about SPARCompiler on Solaris\n"
    if -d "/opt/SUNWspro/bin" and $Config{osname} eq 'solaris';

print "\n";

WriteMakefile(%opts);

# Cleanly exit from the Makefile-build process

exit 0;

sub MY::postamble {
      '
.SUFFIXES: .ec

.ec.o:
	esql -e -I$(ESQL_LIB) -I$(PERL_LIB) -I$(PERL_ARCHLIB) -I$(SITEARCHEXP)/DBI -I$(PERL_ARCHLIB)/CORE dbdimp.ec
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) -I$(ESQL_LIB) $*.c
	rm -f dbdimp.c
';
}

sub MY::clean {
    '
clean::
	rm -f dbdimp.c
	rm -f *.o
	rm -f *.so
	rm -f Makefile.old
	rm -f Informix.c
	rm -f pm_to_blib
	rm -rf blib
';
}

__END__
