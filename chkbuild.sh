#!/bin/ksh
#
#	@(#)$Id: chkbuild.sh,v 1.7 1997/07/13 01:09:42 johnl Exp $
#
#	Test DBD::Informix for compatability with different ESQL/C versions

: ${PERL:=perl}
: ${MAKE:=make}

if [ ! -f Makefile.PL ]
then ${CO:-co} Makefile.PL
fi

config_list="${@:-${DBD_INFORMIX_CONFIG_LIST:-508UD1 601UD1 723UC1 911UC1}}"

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
		${MAKE} test
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
