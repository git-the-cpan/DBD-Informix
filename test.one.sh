:	"@(#)$Id: test.one.sh,v 1.2 1997/05/29 10:10:13 johnl Exp $"
#
#	Run specified test(s)

export PERL_DL_NONLAZY=1
${PERL:-/usr/bin/perl} \
	-I./blib/arch \
	-I./blib/lib \
	$*
