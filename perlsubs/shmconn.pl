# @(#)$Id: shmconn.pl,v 97.1 2000/01/19 17:44:46 jleffler Exp $
#
# Copyright (c) 1999 Jonathan Leffler
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the Perl README file.

# Verify whether specified database name will use a shared memory connection.
# The use of grep (the Unix command) probably renders this worthless on NT.
# NB: Error checking is minimal and assumes that esqltest at least ran OK.

use strict;

sub is_shared_memory_connection
{
	my($dbs) = @_;
	my ($server) = $dbs;
	if ($dbs !~ /.*@/)
	{
		my ($ixsrvr) = $ENV{INFORMIXSERVER};
		$ixsrvr = 'unknown server name' unless $ixsrvr;
		$server = "$dbs\@$ixsrvr";
	}
	$server =~ s/.*@//;
	my($sqlhosts) = $ENV{INFORMIXSQLHOSTS};
	$sqlhosts = "$ENV{INFORMIXDIR}/etc/sqlhosts" unless $sqlhosts;
	# Implications for NT?
	my($ent) = qx(grep "^$server\[ 	][ 	]*" $sqlhosts 2>/dev/null);
	$ent = 'server protocol host service' unless $ent;
	my(@ent) = split ' ', $ent;
	return (($ent[1] =~ /o[ln]ipcshm/) ? 1 : 0);
}

1;
