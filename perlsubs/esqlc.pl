# @(#)$Id: esqlc.pl,v 97.1 2000/01/19 00:22:27 jleffler Exp $ 
#
# Copyright (c) 1999 Jonathan Leffler
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the Perl README file.

#TABSTOP=4

# This file defines the following subs, most of which are used by both
# Makefile.PL and BugReport.
# -- customize_esql
# -- dbd_informix_version_info
# -- find_informixdir_and_esql
# -- get_esqlc_version
# -- set_esqlc_linkage

# Custom edit older versions of the ESQL/C compiler script to acknowledge
# the INFORMIXC environment variable.
sub customize_esql
{
	my ($src, $dst, $pkg) = @_;
	open(ESQL, "<$src") ||
		die "Unable to open $src for reading";
	open(LOCAL, ">$dst") ||
		die "Unable to open $dst for writing";
	while (<ESQL>)
	{
		if (/^CC=/o && !/INFORMIXC/o)
		{
			print LOCAL "# INFORMIXC added by Makefile.PL for $pkg.\n";
			chop;
			s/^CC=//;
			s/"(.*)"/$1/ if (/".*"/);
			$_ = 'CC="${INFORMIXC:-' . $_ . "}\"\n";
		}
		elsif (/\s+CC="cc -g"/o)
		{
			print LOCAL "# CC adjustment changed by Makefile.PL\n";
			print LOCAL "# Was: $_\n";
			s/CC="cc -g"/CC="\${CC} -g"/o;
		}
		print LOCAL;
	}
	close(ESQL);
	close(LOCAL);
	chmod 0755, $dst;
}

# Extract the version number from Informix.pm.
# It may need to handle single quotes as well as double quotes around the
# version number to be fully general.  If there's a better way to do this,
# I want to be told, please.
sub dbd_informix_version_info
{
	my ($file) = @_;
	open(PMFILE, $file) || die "$0: failed to open $file - $!\n";
	while (<PMFILE>)
	{
		if (/\$VERSION\s*=\s*"([^"]+)"\s*;/)
		{
			close PMFILE;
			return $1;
		}
	}
	close PMFILE;
	return "<<ERROR - no VERSION in $file>>";
}

# Locate $INFORMIXDIR and the ESQL/C compiler
sub find_informixdir_and_esql
{
	my ($NTConfiguration) = @_;
	my ($esql, $ID);
	if ($NTConfiguration)
	{
		# NT configuration
		# Tested for Config: archname='MSWin32' osname='MSWin32' osvers='4.0'
		my ($p);
		# Trying to find ESQL (and determining INFORMIXDIR too)
		foreach $p (split( /;/, $ENV{PATH}))
		{
			if( -x "$p/ESQL.EXE")
			{
				# HUMS: \\ needed, because string goes into Makefile (via postamble)
				$esql="$p\\ESQL.EXE"; 
				# HUMS: \\ necessary because string comes from ENV
				$p  =~ s/\\BIN//i;
				$ID=$p;
				last;
			}
		}
		&did_not_read('No executable ESQL/C compiler found in $PATH')
			unless defined $esql;
		print "Using INFORMIXDIR=$ID and ESQL/C compiler $esql\n";
	}
	else
	{
		# Unix configuration
		$ID = $ENV{INFORMIXDIR};
		&did_not_read('$INFORMIXDIR is not set') unless ($ID);
		$esql = $ENV{ESQL};
		$esql = "esql" unless $esql;
		if ($esql =~ m%/%)
		{
			# ESQL/C program specified with path name
			&did_not_read("No executable ESQL/C compiler $esql")
				unless (-x $esql);
		}
		else
		{
			# ESQL/C program specified without any path name
			&did_not_read("No executable ESQL/C compiler $ID/bin/$esql")
				unless (-x "$ID/bin/$esql");
		}
		&did_not_read('$INFORMIXDIR/bin is not in $PATH')
			unless ($ENV{PATH} =~ m%:$ID/bin:% ||
					$ENV{PATH} =~ m%^$ID/bin:% ||
					$ENV{PATH} =~ m%:$ID/bin$%);
	}
	return $ID, $esql;
}

# --- Find out which version of Informix ESQL/C by running 'esql -V'
# NB: Argument should be name of esql program which can be executed.
#     The checks for Unix in find_informixdir_and_esql should be OK.
sub get_esqlc_version
{
	my ($esql) = @_;
	my ($infv, $vers);

	open(ESQL, "$esql -V|") || die;
	die "Failed to read anything from 'esql -V'\n"
		unless defined ($infv = <ESQL>);
	# Read the rest of the input (1 line) to avoid Broken Pipe messages
	while(<ESQL>) { }
	close ESQL;

	chomp($infv);
	$infv =~ s/[ 	]+$//;
	($vers = $infv) =~ s/INFORMIX.* Version (....).*/$1/;
	die "Unexpected message from esql script -- $vers\n"
		unless ($vers =~ /[0-9]\.[0-9][0-9]/);
	$vers =~ s/^([0-9])\./$1/;

	return $infv, $vers;
}

sub set_esqlc_linkage
{
	my ($def_link) = @_;
	my $env_link = $ENV{DBD_INFORMIX_ESQLC_LINKAGE};
	print "** Using $env_link from DBD_INFORMIX_ESQLC_LINKAGE environment variable.\n\n"
		if (defined $env_link);
	return (defined $env_link) ? $env_link : $def_link;
}

1;
