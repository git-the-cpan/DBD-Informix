:	"@(#)$Id: test.run.sh,v 100.1 2002/02/08 22:49:44 jleffler Exp $"
#
#	Run specified test(s)
#
# Copyright 1998 Jonathan Leffler
# Copyright 2000 Informix Software Inc
# Copyright 2002 IBM

PERL_DL_NONLAZY=1
export PERL_DL_NONLAZY

exec ${PERL:-/usr/bin/perl} \
	-I./blib/arch \
	-I./blib/lib \
	"$@"
