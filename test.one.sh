:	"@(#)$Id: test.one.sh,v 1.3 1997/07/18 00:37:31 johnl Exp $"
#
#	Run specified test(s)

PERL_DL_NONLAZY=1
export PERL_DL_NONLAZY

for test in $*
do
	${PERL:-/usr/bin/perl} \
		-I./blib/arch \
		-I./blib/lib \
		$*
done
