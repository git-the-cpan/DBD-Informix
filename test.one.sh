:	"@(#)$Id: test.one.sh,v 1.7 1999/03/31 19:40:28 jleffler Exp $"
#
#	Run specified test(s)

PERL_DL_NONLAZY=1
export PERL_DL_NONLAZY

for test in "$@"
do
	rm -f core
	${PERL:-perl} \
		-I./blib/arch \
		-I./blib/lib \
		"$test"
	if [ -f core ]
	then
		save=core.`basename $test .t`
		mv core $save
		x=`echo "### TEST FAILED -- CORE DUMP SAVED AS $save ###" | sed 's/./#/g'`
		echo
		echo $x
		echo "### TEST FAILED -- CORE DUMP SAVED AS $save ###"
		echo $x
	fi
done
