#!/bin/ksh
#
#	@(#)$Id: chkbuild.sh,v 1.8 1997/11/18 03:42:39 johnl Exp $
#
#	Test DBD::Informix for compatability with different ESQL/C versions

: ${PERL:=perl}
: ${MAKE:=make}

if [ ! -f Makefile.PL ]
then ${CO:-co} Makefile.PL
fi

if [ ! -f test.all ]
then ${MAKE} -f /dev/null test.all
fi

config_list="${@:-${DBD_INFORMIX_CONFIG_LIST:-508UD1 601UD1 724UC1 912UC2}}"

for config in $config_list
do
	(
	echo
	date
	echo "Testing ESQL/C $config with DBD::Informix"
	case "$config" in
	9*)	. $config.IUS;;
	*)	. $config.OnLine;;
	esac
	esql_vers=`expr $config : '\(...\).*'`
	export ESQLC_VERSION=$esql_vers
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
