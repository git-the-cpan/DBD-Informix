#!/bin/sh
#
#   @(#)$Id: Notes/hpux-gcc-build.sh version /main/1 2000-01-28 17:16:06 $
#
#   Script to build GCC 2.95.2 on HP-UX 10.20 using bundled C compiler
#	Assumes you have the following files available:
#       binutils-2.9.1.tar.gz
#       bison-1.28.tar.gz
#       flex-2.5.4a.tar.gz
#       gcc-2.95.2.tar.gz
#       gettext-0.10.35.tar.gz
#       make-3.77.tar.gz
#       sed-3.02.tar.gz

# All the GNU software will be placed under the $PREFIXDIR directory
PREFIXDIR=$HOME/hpux
CCSBIN=/usr/ccs/bin
PATH=$PREFIXDIR/bin:$CCSBIN:$PATH
export PATH

# JLSS install script
# These values mean JL does not have to have be root for install to work.
export CHOWN=:
export CHGRP=:

echo "Build of GCC for HPUX Starting"
date
echo

gunzip -c gettext-0.10.35.tar.gz | tar -xf -
date
(
echo gettext-0.10.35
cd gettext-0.10.35
./configure --prefix=$PREFIXDIR
make
make install
)
date
rm -fr gettext-0.10.35
echo

gunzip -c bison-1.28.tar.gz | tar -xf -
date
(
echo bison-1.28
cd bison-1.28
./configure --prefix=$PREFIXDIR
make
make install
)
date
rm -fr bison-1.28
echo

gunzip -c flex-2.5.4a.tar.gz | tar -xf -
date
(
echo flex-2.5.4
cd flex-2.5.4
./configure --prefix=$PREFIXDIR
make
make install
)
date
rm -fr flex-2.5.4
echo

gunzip -c sed-3.02.tar.gz | tar -xf -
date
(
echo sed-3.02
cd sed-3.02
./configure --prefix=$PREFIXDIR
make
make install
)
date
rm -fr sed-3.02
echo

# Configure warns about ld not working...
gunzip -c binutils-2.9.1.tar.gz | tar -xf -
date
(
echo binutils-2.9.1
cd binutils-2.9.1
./configure --prefix=$PREFIXDIR
make
# The build reported failures, but repeated attempts to rerun the
# make didn't produce useful info on where the build was failing.
# However, I decided to pretend that it was something to do with
# the warning about ld not working, and got on with the install.
# Everything seemed to work OK afterwards.
make install
)
date
rm -fr binutils-2.9.1
echo

gunzip -c make-3.77.tar.gz | tar -xf -
date
(
echo make-3.77
cd make-3.77
./configure --prefix=$PREFIXDIR
make
make install
)
date
rm -fr make-3.77
echo

gunzip -c gcc-2.95.2.tar.gz | tar -xf -
date
(
echo gcc-2.95.2
mkdir gcc-2.95.2-obj
cd gcc-2.95.2-obj
../gcc-2.95.2/configure --prefix=$PREFIXDIR --with-gnu-as
make bootstrap -k
date
make install -k
)
date
rm -fr gcc-2.95.2 gcc-2.95.2-obj

echo
date
echo "Build of GCC for HPUX Complete"
