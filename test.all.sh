:	"@(#)$Id: test.all.sh,v 1.6 1997/07/11 03:26:53 johnl Exp $"
#
#	Run tests against logged, unlogged and mode_ansi databases

dblist=${DBD_INFORMIX_DBLIST:-"logged unlogged mode_ansi nonexistent"}

for dbase in $dblist
do
	echo
	echo "Testing database $dbase"
	DBD_INFORMIX_DATABASE=$dbase \
	PERL_DL_NONLAZY=1 ${PERL:-/usr/bin/perl} \
		-I./blib/arch \
		-I./blib/lib \
		-e 'use Test::Harness qw(&runtests $verbose);
			$verbose='${TEST_VERBOSE:-0}'; runtests @ARGV;' ${*:-t/*.t}
done
