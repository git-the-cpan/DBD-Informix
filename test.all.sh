:	"@(#)$Id: test.all.sh,v 1.8 1997/11/18 05:33:01 johnl Exp $"
#
#	Run tests against logged, unlogged and mode_ansi databases

dblist=${DBD_INFORMIX_DBLIST:-"logged unlogged mode_ansi"}

status=0
for dbase in $dblist
do
	echo
	echo "Testing database $dbase"
	if	DBD_INFORMIX_DATABASE=$dbase \
		PERL_DL_NONLAZY=1 ${PERL:-/usr/bin/perl} \
		-I./blib/arch \
		-I./blib/lib \
		-e 'use Test::Harness qw(&runtests $verbose);
			$verbose='${TEST_VERBOSE:-0}'; runtests @ARGV;' ${*:-t/*.t}
	then : OK
	else status=1
	fi
done
exit $status
