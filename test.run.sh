:	"@(#)$Id: test.run.sh version /main/1 1998-01-15 19:01:43 $"
#
#	Run specified test(s)

PERL_DL_NONLAZY=1
export PERL_DL_NONLAZY

exec ${PERL:-/usr/bin/perl} \
	-I./blib/arch \
	-I./blib/lib \
	"$@"
