:	"@(#)$Id: test.one.sh,v 100.1 2002/02/08 22:49:42 jleffler Exp $"
#
#	Run specified test(s)
#
# Copyright 1997-99 Jonathan Leffler
# Copyright 2000    Informix Software Inc
# Copyright 2002    IBM

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
