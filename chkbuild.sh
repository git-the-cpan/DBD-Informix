#!/bin/ksh
#
#	@(#)$Id: chkbuild.sh,v 100.1 2002/02/08 22:49:00 jleffler Exp $
#
#	Test DBD::Informix for compatability with different ESQL/C versions
#
#   Copyright 1996-1999 Jonathan Leffler
#   Copyright 2000      Informix Software
#   Copyright 2002      IBM

: ${PERL:=perl}
: ${MAKE:=make}

if [ ! -f Makefile.PL ]
then ${CO:-co} Makefile.PL
fi

if [ ! -f test.all ]
then ${MAKE} -f /dev/null test.all
fi

case $# in
0)	if [ -z "$DBD_INFORMIX_CONFIG_LIST" ]
	then
		echo 'Specify the environment setting scripts on the command line' 1>&2
		echo 'or in $DBD_INFORMIX_CONFIG_LIST' 1>&2
		exit 1
	fi
	config_list="${DBD_INFORMIX_CONFIG_LIST}";;
*)	config_list="$*";;
esac

for config in $config_list
do
	(
	echo
	date
	echo "Testing DBD::Informix with configuration $config"
	esql_vers=`esql -V | sed -e '2,$d' -e 's/.*Version //' -e 's/\([0-9][0-9]*\)\.\([0-9][0-9]\).*/\1\2/'`
	export ESQLC_VERSION=$esql_vers
	# JLSS command - environ
	environ -a -u -b
	echo
	rm -f esql
	if $PERL Makefile.PL &&
		${MAKE} clean &&
		mv Makefile.old Makefile &&
		( [ ! -f esql.old ] || mv esql.old esql )
		${MAKE} &&
		${MAKE} test &&
		test.all
	then status="PASSED"
	else status="FAILED"
	fi
	echo
	# JLSS command - boxecho
	boxecho "$config -- $status"
	echo
	sleep 2
	if [ -f Makefile ]
	then ${MAKE} -f Makefile realclean
	fi
	rm -f esql.old
	echo
	)
done
