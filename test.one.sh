:	"@(#)$Id: test.one.sh,v 1.5 1998/08/06 01:52:00 jleffler Exp $"
#
#	Run specified test(s)

PERL_DL_NONLAZY=1
export PERL_DL_NONLAZY

for test in "$@"
do
	${PERL:-perl} \
		-I./blib/arch \
		-I./blib/lib \
		"$test"
done
