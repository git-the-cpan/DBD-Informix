:	"@(#)$Id: test.run.sh,v 2004.1 2004/12/01 17:40:14 jleffler Exp $"
#
#	Run specified test(s)
#
# Copyright 1998 Jonathan Leffler
# Copyright 2000 Informix Software Inc
# Copyright 2002 IBM
# Copyright 2004 Jonathan Leffler

PERL_DL_NONLAZY=1
export PERL_DL_NONLAZY

exec ${PERL:-perl} \
	-I./blib/arch \
	-I./blib/lib \
	"$@"
