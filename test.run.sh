:	"@(#)$Id: test.run.sh,v 1.1 1998/01/15 19:01:43 johnl Exp $"
#
#	Run specified test(s)

PERL_DL_NONLAZY=1
export PERL_DL_NONLAZY

exec ${PERL:-/usr/bin/perl} \
	-I./blib/arch \
	-I./blib/lib \
	"$@"
