# This Makefile is for the DBD::Informix extension to perl.
#
# It was generated automatically by MakeMaker version 4.16 from the contents
# of Makefile.PL. Don't edit this file, edit Makefile.PL instead.
#
#	ANY CHANGES MADE HERE WILL BE LOST! 
#
#   MakeMaker Parameters: 
#	DEFINE => '-Wall -pedantic -Wno-comment -Wpointer-arith -Wcast-align -Wconversion -Wtraditional -Wpointer-arith -Wcast-qual'
#	INC => '-I/opt/informix/incl/esql -I/opt/gnu/lib/perl5/sparc-solaris/DBI -I/DBI'
#	LIBS => [ '-L/opt/informix/lib/esql -lsql -lgen -los -lm' ]
#	NAME => 'DBD::Informix'
#	OBJECT => '$(O_FILES) dbdimp.o'
#	VERSION => '0.20pl1'
#	dynamic_lib => { OTHERLDFLAGS=>'-L$(INFORMIXDIR)/lib -L/opt/informix/lib -R/opt/informix/lib -L/opt/informix/lib/esql -R/opt/informix/lib/esql' }
#	macro => { ESQL_LIB=>'$(INFORMIXDIR)/include' }

# --- MakeMaker post_initialize section:


# --- MakeMaker const_config section:

# These definitions are from config.sh (via /opt/gnu/lib/perl5/sparc-solaris/Config.pm)
CC = gcc
LIBC = /usr/lib/libc.so
LDFLAGS = 
LDDLFLAGS = -G
CCDLFLAGS =  
CCCDLFLAGS = -fpic
RANLIB = :
SO = so
DLEXT = so
DLSRC = dl_dlopen.xs


# --- MakeMaker constants section:

NAME = DBD::Informix
DISTNAME = DBD-Informix
VERSION = 0.20pl1
VERSION_SYM = 0_20pl1

# In which directory should we put this extension during 'make'?
# This is typically ./blib.
# (also see INST_LIBDIR and relationship to ROOTEXT)
INST_LIB = ./blib
INST_ARCHLIB = ./blib
INST_EXE = ./blib

# AFS users will want to set the installation directories for
# the final 'make install' early without setting INST_LIB,
# INST_ARCHLIB, and INST_EXE for the testing phase
INSTALLPRIVLIB = /opt/gnu/lib/perl5
INSTALLARCHLIB = /opt/gnu/lib/perl5/sparc-solaris
INSTALLBIN = /opt/gnu/bin

# Perl library to use when building the extension
PERL_LIB = /opt/gnu/lib/perl5
PERL_ARCHLIB = /opt/gnu/lib/perl5/sparc-solaris
LIBPERL_A = libperl.a

MAKEMAKER = $(PERL_LIB)/ExtUtils/MakeMaker.pm
MM_VERSION = 4.16
I_PERL_LIBS = -I$(PERL_ARCHLIB) -I$(PERL_LIB)

# Perl header files (will eventually be under PERL_LIB)
PERL_INC = /opt/gnu/lib/perl5/sparc-solaris/CORE
# Perl binaries
PERL = /opt/gnu/bin/perl
FULLPERL = /opt/gnu/bin/perl

# FULLEXT = Pathname for extension directory (eg DBD/Oracle).
# BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT.
# ROOTEXT = Directory part of FULLEXT with leading slash (eg /DBD)
FULLEXT = DBD/Informix
BASEEXT = Informix
ROOTEXT = /DBD

INC = -I/opt/informix/incl/esql -I/opt/gnu/lib/perl5/sparc-solaris/DBI -I/DBI
DEFINE = -Wall -pedantic -Wno-comment -Wpointer-arith -Wcast-align -Wconversion -Wtraditional -Wpointer-arith -Wcast-qual
OBJECT = $(O_FILES) dbdimp.o
LDFROM = $(OBJECT)
LINKTYPE = dynamic

# Handy lists of source code files:
XS_FILES= Informix.xs
C_FILES = Informix.c \
	dbdimp.c
O_FILES = Informix.o \
	dbdimp.o
H_FILES = Informix.h \
	dbdimp.h

.SUFFIXES: .xs

.PRECIOUS: Makefile

.NO_PARALLEL:

.PHONY: all config static dynamic test linkext

# This extension may link to it's own library (see SDBM_File)
MYEXTLIB = 

# Where is the Config information that we are using/depend on
CONFIGDEP = $(PERL_ARCHLIB)/Config.pm $(PERL_INC)/config.h

# Where to put things:
INST_LIBDIR     = $(INST_LIB)$(ROOTEXT)
INST_ARCHLIBDIR = $(INST_ARCHLIB)$(ROOTEXT)

INST_AUTODIR      = $(INST_LIB)/auto/$(FULLEXT)
INST_ARCHAUTODIR  = $(INST_ARCHLIB)/auto/$(FULLEXT)

INST_STATIC  = $(INST_ARCHAUTODIR)/$(BASEEXT).a
INST_DYNAMIC = $(INST_ARCHAUTODIR)/$(BASEEXT).$(DLEXT)
INST_BOOT    = $(INST_ARCHAUTODIR)/$(BASEEXT).bs

INST_PM = $(INST_LIBDIR)/Informix.pm


# --- MakeMaker const_loadlibs section:

# DBD::Informix might depend on some other libraries:
# (These comments may need revising:)
#
# Dependent libraries can be linked in one of three ways:
#
#  1.  (For static extensions) by the ld command when the perl binary
#      is linked with the extension library. See EXTRALIBS below.
#
#  2.  (For dynamic extensions) by the ld command when the shared
#      object is built/linked. See LDLOADLIBS below.
#
#  3.  (For dynamic extensions) by the DynaLoader when the shared
#      object is loaded. See BSLOADLIBS below.
#
# EXTRALIBS =	List of libraries that need to be linked with when
#		linking a perl binary which includes this extension
#		Only those libraries that actually exist are included.
#		These are written to a file and used when linking perl.
#
# LDLOADLIBS =	List of those libraries which can or must be linked into
#		the shared library when created using ld. These may be
#		static or dynamic libraries.
#		LD_RUN_PATH is a colon separated list of the directories
#		in LDLOADLIBS. It is passed as an environment variable to
#		the process that links the shared library.
#
# BSLOADLIBS =	List of those libraries that are needed but can be
#		linked in dynamically at run time on this platform.
#		SunOS/Solaris does not need this because ld records
#		the information (from LDLOADLIBS) into the object file.
#		This list is used to create a .bs (bootstrap) file.
#
EXTRALIBS  = -L/opt/informix/lib/esql -lsql -lgen -los
LDLOADLIBS = -L/opt/informix/lib/esql -lsql -lgen -los -lm
BSLOADLIBS = 
LD_RUN_PATH= /opt/informix/lib/esql


# --- MakeMaker const_cccmd section:
CCCMD = $(CC) -c -DDEBUGGING -O


# --- MakeMaker tool_autosplit section:

# Usage: $(AUTOSPLITFILE) FileToSplit AutoDirToSplitInto
AUTOSPLITFILE = $(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" -e 'use AutoSplit;autosplit($$ARGV[0], $$ARGV[1], 0, 1, 1) ;'


# --- MakeMaker tool_xsubpp section:

XSUBPPDIR = $(PERL_LIB)/ExtUtils
XSUBPP = $(XSUBPPDIR)/xsubpp
XSUBPPDEPS = $(XSUBPPDIR)/typemap
XSUBPPARGS = -typemap $(XSUBPPDIR)/typemap


# --- MakeMaker tools_other section:

SHELL = /bin/sh
LD = gcc
TOUCH = touch
CP = cp
MV = mv
RM_F  = rm -f
RM_RF = rm -rf
CHMOD = chmod

# The following is a portable way to say mkdir -p
MKPATH = $(PERL) -wle '$$"="/"; foreach $$p (@ARGV){ next if -d $$p; my(@p); foreach(split(/\//,$$p)){ push(@p,$$_); next if -d "@p/"; print "mkdir @p"; mkdir("@p",0777)||die $$! }} exit 0;'


# --- MakeMaker macro section:
ESQL_LIB = $(INFORMIXDIR)/include


# --- MakeMaker post_constants section:


# --- MakeMaker pasthru section:

PASTHRU1 = INST_LIB="$(INST_LIB)"\
	INST_ARCHLIB="$(INST_ARCHLIB)"\
	INST_EXE="$(INST_EXE)"\
	INSTALLPRIVLIB="$(INSTALLPRIVLIB)"\
	INSTALLARCHLIB="$(INSTALLARCHLIB)"\
	INSTALLBIN="$(INSTALLBIN)"\
	LIBPERL_A="$(LIBPERL_A)"\
	LINKTYPE="$(LINKTYPE)"

PASTHRU2 = INSTALLPRIVLIB="$(INSTALLPRIVLIB)"\
	INSTALLARCHLIB="$(INSTALLARCHLIB)"\
	INSTALLBIN="$(INSTALLBIN)"\
	LIBPERL_A="$(LIBPERL_A)"\
	LINKTYPE="$(LINKTYPE)"


# --- MakeMaker c_o section:

.c.o:
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $(INC) $*.c


# --- MakeMaker xs_c section:

.xs.c:
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(XSUBPP) $(XSUBPPARGS) $*.xs >$*.tc && mv $*.tc $@


# --- MakeMaker xs_o section:

.xs.o:
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(XSUBPP) $(XSUBPPARGS) $*.xs >xstmp.c && mv xstmp.c $*.c
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $(INC) $*.c


# --- MakeMaker top_targets section:

all ::	config linkext $(INST_PM)


config :: Makefile $(INST_LIBDIR)/.exists $(INST_ARCHAUTODIR)/.exists Version_check

$(INST_LIBDIR)/.exists :: $(PERL)
	@ $(MKPATH) $(INST_LIBDIR)
	@ $(TOUCH) $(INST_LIBDIR)/.exists

$(INST_ARCHAUTODIR)/.exists :: $(PERL)
	@ $(MKPATH) $(INST_ARCHAUTODIR)
	@ $(TOUCH) $(INST_ARCHAUTODIR)/.exists

$(INST_EXE)/.exists :: $(PERL)
	@ $(MKPATH) $(INST_EXE)
	@ $(TOUCH) $(INST_EXE)/.exists

$(O_FILES): $(H_FILES)

help:
	$(PERL) -I$(PERL_LIB) -e 'use ExtUtils::MakeMaker "&help"; &help;'

Version_check:
	@$(PERL) -I$(PERL_LIB) -e 'use ExtUtils::MakeMaker qw($$Version &Version_check);' \
		-e '&Version_check($(MM_VERSION))'


# --- MakeMaker linkext section:

linkext :: $(LINKTYPE)



# --- MakeMaker dlsyms section:


# --- MakeMaker dynamic section:

# $(INST_PM) has been moved to the all: target.
# It remains here for awhile to allow for old usage: "make dynamic"
dynamic :: Makefile $(INST_DYNAMIC) $(INST_BOOT) $(INST_PM)



# --- MakeMaker dynamic_bs section:

BOOTSTRAP = Informix.bs

# As Mkbootstrap might not write a file (if none is required)
# we use touch to prevent make continually trying to remake it.
# The DynaLoader only reads a non-empty file.
$(BOOTSTRAP): Makefile 
	@ echo "Running Mkbootstrap for $(NAME) ($(BSLOADLIBS))"
	@ $(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" \
		-e 'use ExtUtils::Mkbootstrap;' \
		-e 'Mkbootstrap("$(BASEEXT)","$(BSLOADLIBS)");'
	@ $(TOUCH) $(BOOTSTRAP)
	$(CHMOD) 644 $@
	@echo $@ >> $(INST_ARCHAUTODIR)/.packlist

$(INST_BOOT): $(BOOTSTRAP)
	@ rm -rf $(INST_BOOT)
	-cp $(BOOTSTRAP) $(INST_BOOT)
	$(CHMOD) 644 $@
	@echo $@ >> $(INST_ARCHAUTODIR)/.packlist


# --- MakeMaker dynamic_lib section:

# This section creates the dynamically loadable $(INST_DYNAMIC)
# from $(OBJECT) and possibly $(MYEXTLIB).
ARMAYBE = :
OTHERLDFLAGS = -L$(INFORMIXDIR)/lib -L/opt/informix/lib -R/opt/informix/lib -L/opt/informix/lib/esql -R/opt/informix/lib/esql

$(INST_DYNAMIC): $(OBJECT) $(MYEXTLIB) $(BOOTSTRAP) $(INST_ARCHAUTODIR)/.exists
	LD_RUN_PATH="$(LD_RUN_PATH)" $(LD) -o $@ $(LDDLFLAGS) $(LDFROM) $(OTHERLDFLAGS) $(MYEXTLIB) $(LDLOADLIBS)
	$(CHMOD) 755 $@
	@echo $@ >> $(INST_ARCHAUTODIR)/.packlist


# --- MakeMaker static section:

# $(INST_PM) has been moved to the all: target.
# It remains here for awhile to allow for old usage: "make static"
static :: Makefile $(INST_STATIC) $(INST_PM)



# --- MakeMaker static_lib section:

$(INST_STATIC): $(OBJECT) $(MYEXTLIB) $(INST_ARCHAUTODIR)/.exists
	ar cr $@ $(OBJECT) && $(RANLIB) $@
	@echo "$(EXTRALIBS)" > $(INST_ARCHAUTODIR)/extralibs.ld
	$(CHMOD) 755 $@
	@echo $@ >> $(INST_ARCHAUTODIR)/.packlist


# --- MakeMaker installpm section:

# installpm: Informix.pm => $(INST_LIBDIR)/Informix.pm, splitlib=$(INST_LIB)

$(INST_LIBDIR)/Informix.pm: Informix.pm Makefile $(INST_LIBDIR)/.exists
	@ rm -f $@
	cp Informix.pm $@
	$(CHMOD) 644 $@
	@echo $@ >> $(INST_ARCHAUTODIR)/.packlist
	@$(AUTOSPLITFILE) $@ $(INST_LIB)/auto



# --- MakeMaker processPL section:


# --- MakeMaker installbin section:


# --- MakeMaker subdirs section:

# none

# --- MakeMaker clean section:

# Delete temporary files but do not touch installed files. We don't delete
# the Makefile here so a later make realclean still has a makefile to use.

clean ::
	-rm -rf *~ t/*~ *.o *.a mon.out core so_locations $(BOOTSTRAP) $(BASEEXT).bso $(BASEEXT).exp Informix.c ./blib
	-mv Makefile Makefile.old 2>/dev/null


# --- MakeMaker realclean section:

# Delete temporary files (via clean) and also delete installed files
realclean purge ::  clean
	rm -rf $(INST_AUTODIR) $(INST_ARCHAUTODIR)
	rm -f $(INST_DYNAMIC) $(INST_BOOT)
	rm -f $(INST_STATIC) $(INST_PM)
	rm -rf Makefile Makefile.old


# --- MakeMaker dist section:

TAR  = tar
TARFLAGS = cvf
COMPRESS = compress
SUFFIX = Z
SHAR = shar
PREOP = @ :
POSTOP = @ :
CI = ci -u
RCS = rcs -Nv$(VERSION_SYM):
DIST_DEFAULT = tardist

distclean :: realclean distcheck

distcheck :
	$(PERL) -I$(PERL_LIB) -e 'use ExtUtils::Manifest "&fullcheck";' \
		-e 'fullcheck();'

manifest :
	$(PERL) -I$(PERL_LIB) -e 'use ExtUtils::Manifest "&mkmanifest";' \
		-e 'mkmanifest();'

dist : $(DIST_DEFAULT)

tardist : $(DISTNAME)-$(VERSION).tar.$(SUFFIX)

$(DISTNAME)-$(VERSION).tar.$(SUFFIX) : distdir
	$(PREOP)
	$(TAR) $(TARFLAGS) $(DISTNAME)-$(VERSION).tar $(DISTNAME)-$(VERSION)
	$(COMPRESS) $(DISTNAME)-$(VERSION).tar
	$(RM_RF) $(DISTNAME)-$(VERSION)
	$(POSTOP)

uutardist : $(DISTNAME)-$(VERSION).tar.$(SUFFIX)
	uuencode $(DISTNAME)-$(VERSION).tar.$(SUFFIX) \
		$(DISTNAME)-$(VERSION).tar.$(SUFFIX) > \
		$(DISTNAME)-$(VERSION).tar.$(SUFFIX).uu

shdist : distdir
	$(PREOP)
	$(SHAR) $(DISTNAME)-$(VERSION) > $(DISTNAME)-$(VERSION).shar
	$(RM_RF) $(DISTNAME)-$(VERSION)
	$(POSTOP)

distdir :
	$(RM_RF) $(DISTNAME)-$(VERSION)
	$(PERL) -I$(PERL_LIB) -e 'use ExtUtils::Manifest "/mani/";' \
		-e 'manicopy(maniread(),"$(DISTNAME)-$(VERSION)");'


ci :
	$(PERL) -I$(PERL_LIB) -e 'use ExtUtils::Manifest "&maniread";' \
		-e '@all = keys %{maniread()};' \
		-e 'print("Executing $(CI) @all\n"); system("$(CI) @all");' \
		-e 'print("Executing $(RCS) ...\n"); system("$(RCS) @all");'



# --- MakeMaker install section:

doc_install ::
	@ echo Appending installation info to $(INSTALLARCHLIB)/perllocal.pod
	@ $(PERL) -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB)  \
		-e "use ExtUtils::MakeMaker; MM->writedoc('Module', '$(NAME)', \
		'LINKTYPE=$(LINKTYPE)', 'VERSION=$(VERSION)', \
		'EXE_FILES=$(EXE_FILES)')" >> $(INSTALLARCHLIB)/perllocal.pod

install :: pure_install doc_install

pure_install ::
	@$(PERL) -e 'foreach (@ARGV){die qq{You do not have permissions to install into $$_\n} unless -w $$_}' $(INSTALLPRIVLIB) $(INSTALLARCHLIB)
	: perl5.000 and MM pre 3.8 autosplit into INST_ARCHLIB, we delete these old files here
	rm -f $(INSTALLARCHLIB)/auto/$(FULLEXT)/*.al
	rm -f $(INSTALLARCHLIB)/auto/$(FULLEXT)/*.ix
	$(MAKE) INST_LIB=$(INSTALLPRIVLIB) INST_ARCHLIB=$(INSTALLARCHLIB) INST_EXE=$(INSTALLBIN)
	@$(PERL) -i.bak -lne 'print unless $$seen{$$_}++' $(INSTALLARCHLIB)/auto/$(FULLEXT)/.packlist

#### UNINSTALL IS STILL EXPERIMENTAL ####
uninstall ::
	$(RM_RF) `cat $(INSTALLARCHLIB)/auto/$(FULLEXT)/.packlist`


# --- MakeMaker force section:
# Phony target to force checking subdirectories.
FORCE:


# --- MakeMaker perldepend section:

PERL_HDRS = $(PERL_INC)/EXTERN.h $(PERL_INC)/INTERN.h \
    $(PERL_INC)/XSUB.h	$(PERL_INC)/av.h	$(PERL_INC)/cop.h \
    $(PERL_INC)/cv.h	$(PERL_INC)/dosish.h	$(PERL_INC)/embed.h \
    $(PERL_INC)/form.h	$(PERL_INC)/gv.h	$(PERL_INC)/handy.h \
    $(PERL_INC)/hv.h	$(PERL_INC)/keywords.h	$(PERL_INC)/mg.h \
    $(PERL_INC)/op.h	$(PERL_INC)/opcode.h	$(PERL_INC)/patchlevel.h \
    $(PERL_INC)/perl.h	$(PERL_INC)/perly.h	$(PERL_INC)/pp.h \
    $(PERL_INC)/proto.h	$(PERL_INC)/regcomp.h	$(PERL_INC)/regexp.h \
    $(PERL_INC)/scope.h	$(PERL_INC)/sv.h	$(PERL_INC)/unixish.h \
    $(PERL_INC)/util.h	$(PERL_INC)/config.h



$(OBJECT) : $(PERL_HDRS)

Informix.c : $(XSUBPPDEPS)


# --- MakeMaker makefile section:

$(OBJECT) : Makefile

# We take a very conservative approach here, but it's worth it.
# We move Makefile to Makefile.old here to avoid gnu make looping.
Makefile :	Makefile.PL $(CONFIGDEP)
	@echo "Makefile out-of-date with respect to $?"
	@echo "Cleaning current config before rebuilding Makefile..."
	-@mv Makefile Makefile.old
	-$(MAKE) -f Makefile.old clean >/dev/null 2>&1 || true
	$(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" Makefile.PL 
	@echo "Now you must rerun make."; false


# --- MakeMaker staticmake section:

# --- MakeMaker makeaperl section ---
MAP_TARGET    = perl
FULLPERL      = /opt/gnu/bin/perl
MAP_LINKCMD   = $(CC) 
MAP_PERLINC   = -I./blib -I./blib -I/opt/gnu/lib/perl5/sparc-solaris -I/opt/gnu/lib/perl5
MAP_STATIC    = ./blib/auto/DBD/Informix/Informix.a /opt/gnu/lib/perl5/sparc-solaris/auto/DBD/Oracle/Oracle.a /opt/gnu/lib/perl5/sparc-solaris/auto/DBD/mSQL/mSQL.a /opt/gnu/lib/perl5/sparc-solaris/auto/DBI/DBI.a /opt/gnu/lib/perl5/sparc-solaris/auto/DynaLoader/DynaLoader.a /opt/gnu/lib/perl5/sparc-solaris/auto/Fcntl/Fcntl.a /opt/gnu/lib/perl5/sparc-solaris/auto/NDBM_File/NDBM_File.a /opt/gnu/lib/perl5/sparc-solaris/auto/POSIX/POSIX.a /opt/gnu/lib/perl5/sparc-solaris/auto/SDBM_File/SDBM_File.a /opt/gnu/lib/perl5/sparc-solaris/auto/Socket/Socket.a /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/Bitmap/Bitmap.a /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/Canvas/Canvas.a /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/Entry/Entry.a /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/IO/IO.a /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/Listbox/Listbox.a /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/Menu/Menu.a /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/Menubutton/Menubutton.a /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/Photo/Photo.a /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/Pixmap/Pixmap.a /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/Scale/Scale.a /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/Scrollbar/Scrollbar.a /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/Text/Text.a /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/Tk.a /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/Xlib/Xlib.a
MAP_PRELIBS   = -lsocket -lnsl -ldl -lm -lc -lcrypt 

MAP_LIBPERL = /opt/gnu/lib/perl5/sparc-solaris/CORE/libperl.a

extralibs.ld: ./blib/auto/DBD/Informix/extralibs.ld /opt/gnu/lib/perl5/sparc-solaris/auto/DBD/Oracle/extralibs.ld /opt/gnu/lib/perl5/sparc-solaris/auto/DBD/mSQL/extralibs.ld /opt/gnu/lib/perl5/sparc-solaris/auto/DBI/extralibs.ld /opt/gnu/lib/perl5/sparc-solaris/auto/DynaLoader/extralibs.ld /opt/gnu/lib/perl5/sparc-solaris/auto/Fcntl/extralibs.ld /opt/gnu/lib/perl5/sparc-solaris/auto/NDBM_File/extralibs.ld /opt/gnu/lib/perl5/sparc-solaris/auto/POSIX/extralibs.ld /opt/gnu/lib/perl5/sparc-solaris/auto/SDBM_File/extralibs.ld /opt/gnu/lib/perl5/sparc-solaris/auto/Socket/extralibs.ld /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/Bitmap/extralibs.ld /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/Canvas/extralibs.ld /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/Entry/extralibs.ld /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/IO/extralibs.ld /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/Listbox/extralibs.ld /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/Menu/extralibs.ld /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/Menubutton/extralibs.ld /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/Photo/extralibs.ld /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/Pixmap/extralibs.ld /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/Scale/extralibs.ld /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/Scrollbar/extralibs.ld /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/Text/extralibs.ld /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/extralibs.ld /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/Xlib/extralibs.ld
	@ rm -f $@
	@ $(TOUCH) $@
	cat ./blib/auto/DBD/Informix/extralibs.ld >> $@
	cat /opt/gnu/lib/perl5/sparc-solaris/auto/DBD/Oracle/extralibs.ld >> $@
	cat /opt/gnu/lib/perl5/sparc-solaris/auto/DBD/mSQL/extralibs.ld >> $@
	cat /opt/gnu/lib/perl5/sparc-solaris/auto/DBI/extralibs.ld >> $@
	cat /opt/gnu/lib/perl5/sparc-solaris/auto/DynaLoader/extralibs.ld >> $@
	cat /opt/gnu/lib/perl5/sparc-solaris/auto/Fcntl/extralibs.ld >> $@
	cat /opt/gnu/lib/perl5/sparc-solaris/auto/NDBM_File/extralibs.ld >> $@
	cat /opt/gnu/lib/perl5/sparc-solaris/auto/POSIX/extralibs.ld >> $@
	cat /opt/gnu/lib/perl5/sparc-solaris/auto/SDBM_File/extralibs.ld >> $@
	cat /opt/gnu/lib/perl5/sparc-solaris/auto/Socket/extralibs.ld >> $@
	cat /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/Bitmap/extralibs.ld >> $@
	cat /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/Canvas/extralibs.ld >> $@
	cat /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/Entry/extralibs.ld >> $@
	cat /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/IO/extralibs.ld >> $@
	cat /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/Listbox/extralibs.ld >> $@
	cat /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/Menu/extralibs.ld >> $@
	cat /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/Menubutton/extralibs.ld >> $@
	cat /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/Photo/extralibs.ld >> $@
	cat /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/Pixmap/extralibs.ld >> $@
	cat /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/Scale/extralibs.ld >> $@
	cat /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/Scrollbar/extralibs.ld >> $@
	cat /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/Text/extralibs.ld >> $@
	cat /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/extralibs.ld >> $@
	cat /opt/gnu/lib/perl5/sparc-solaris/auto/Tk/Xlib/extralibs.ld >> $@

$(MAP_TARGET): ./perlmain.o $(MAP_LIBPERL) $(MAP_STATIC) extralibs.ld
	$(MAP_LINKCMD) -o $@ ./perlmain.o $(MAP_LIBPERL) $(MAP_STATIC) `cat extralibs.ld` $(MAP_PRELIBS)
	@ echo 'To install the new "$(MAP_TARGET)" binary, call'
	@ echo '    make -f Makefile inst_perl MAP_TARGET=$(MAP_TARGET)'
	@ echo 'To remove the intermediate files say'
	@ echo '    make -f Makefile map_clean'

./perlmain.o: ./perlmain.c
	cd . && $(CC) -I/opt/gnu/lib/perl5/sparc-solaris/CORE -c -DDEBUGGING -O perlmain.c

./perlmain.c: Makefile
	@ echo Writing $@
	@ $(FULLPERL) $(MAP_PERLINC) -e 'use ExtUtils::Miniperl; \
		writemain(grep s#.*/auto/##, qw|$(MAP_STATIC)|)' > $@.tmp && mv $@.tmp $@


doc_inst_perl:
	@ echo Appending installation info to $(INSTALLARCHLIB)/perllocal.pod
	@ $(FULLPERL) -e 'use ExtUtils::MakeMaker; MM->writedoc("Perl binary",' \
		-e '"$(MAP_TARGET)", "MAP_STATIC=$(MAP_STATIC)",' \
		-e '"MAP_EXTRA=@ARGV", "MAP_LIBPERL=$(MAP_LIBPERL)")' \
		-- `cat extralibs.ld` >> $(INSTALLARCHLIB)/perllocal.pod

inst_perl: pure_inst_perl doc_inst_perl

pure_inst_perl: $(MAP_TARGET)
	cp $(MAP_TARGET) $(INSTALLBIN)/$(MAP_TARGET)

clean :: map_clean

map_clean :
	rm -f ./perlmain.o ./perlmain.c $(MAP_TARGET) extralibs.ld


# --- MakeMaker test section:

TEST_VERBOSE=0
TEST_TYPE=test_dynamic

test :: $(TEST_TYPE)

test_dynamic :: all
	$(FULLPERL) -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB) test.pl

test_static :: all $(MAP_TARGET)
	./$(MAP_TARGET) -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB) test.pl



# --- MakeMaker postamble section:


# End.
.SUFFIXES: .ec

.ec.o:
	esql -c -I$(ESQL_LIB) -I$(PERL_LIB) -I$(PERL_ARCHLIB) -I$(PERL_ARCHLIB)/DBI -I$(PERL_ARCHLIB)/CORE dbdimp.ec

