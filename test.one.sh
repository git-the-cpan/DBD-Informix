:	"@(#)$Id: test.one.sh,v 1.4 1998/01/14 02:23:55 johnl Exp $"
#
#	Run specified test(s)

PERL_DL_NONLAZY=1
export PERL_DL_NONLAZY

for test in "$@"
do
	${PERL:-/usr/bin/perl} \
		-I./blib/arch \
		-I./blib/lib \
		"$test"
done
