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
