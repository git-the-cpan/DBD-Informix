#!/bin/ksh
#
# @(#)$Id: test.c4gl.sh,v 1.1 1998/01/15 19:10:03 johnl Exp $
#
# Test whether DBD::Informix can be built with I4GL

(
set -x
export INFORMIXSQLHOSTS=/usr/informix/etc/sqlhosts
export INFORMIXDIR=/usr/informix/6.05.UC1
export PATH=$INFORMIXDIR/bin:$PATH
ESQL=c4gl perl Makefile.PL
make
make test
)

