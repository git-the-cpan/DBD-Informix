#!/bin/ksh
#
# @(#)$Id: test.c4gl.sh,v 100.1 2002/02/08 22:49:41 jleffler Exp $
#
# Test whether DBD::Informix can be built with I4GL
#
# Copyright 1997 Jonathan Leffler
# Copyright 2000 Informix Software Inc
# Copyright 2002 IBM

(
set -x
export INFORMIXSQLHOSTS=/usr/informix/etc/sqlhosts
export INFORMIXDIR=/usr/informix/6.05.UC1
export PATH=$INFORMIXDIR/bin:$PATH
ESQL=c4gl perl Makefile.PL
make
make test
)

