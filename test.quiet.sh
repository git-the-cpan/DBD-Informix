:	"@(#)$Id: test.quiet.sh,v 100.1 2002/02/08 22:49:43 jleffler Exp $"
#
#	Run specified test(s) quietly
#
# Copyright 1998 Jonathan Leffler
# Copyright 2000 Informix Software Inc
# Copyright 2002 IBM

pad=""
testlist=
for file in $*
do
	testlist="$testlist$pad'$file'"
	pad=", "
done

PERL_DL_NONLAZY=1 \
${PERL:-perl} -I./blib/arch -I./blib/lib \
	 -e "use Test::Harness qw(&runtests);
		runtests  $testlist;"
