#!/usr/bin/perl -w
#
#	@(#)sqlcmd.sh	54.2 97/04/08
#
#	SQL Command Reader & Executor

use Getopt::Std;
use DBI;

$delim = $ENV{DBDELIMITER};
$delim = "|" unless $delim;

sub print_row
{
	my (@row) = @_;
	my ($i);
	for ($i = 0; $i < @row; $i++)
	{

		print "$row[$i]" if (defined $row[$i]);
		print "$delim";
	}
	print "\n";
}

# Execute an SQL command -- the preparable ones...
sub sql_exec
{
	my ($cmd) = @_;
	my ($sth);
	print "+ $cmd\n" if ($opt_x);
	warn "SQL command failed: $DBI::errstr\n"
		unless ($sth = $dbh->prepare($cmd) and $sth->execute);
	if ($sth->{ix_Fetchable})
	{
		# SELECT statements other than SELECT...INTO TEMP, and
		# EXECUTE PROCEDURE statements which return values.
		my (@row);
		while (@row = @{$sth->fetch})
		{
			print_row(@row);
		}
	}
	warn "SQL command failed: $DBI::errstr\n"
		unless $sth->finish;
}

# BUG: this code does not support multiple occurrences of the -e option on
# the command line.  Nor does it support the -f option.
$opt_d = '.DEFAULT.';
$opt_e = '';
$opt_x = '';
$opt_V = '';
getopts('d:e:xV');

# Print version information
if ($opt_V)
{
	print "$0: SQLCMD Version 54.2 (97/04/08)\n";
	$drh = DBI->install_driver('Informix');
	print "DBI Version $DBI::VERSION\n";
	print "DBD::$drh->{Name} Version $drh->{Version}\n";
	print "$drh->{ProductName}\n";
	exit(0);
}

# Pre-select database
die "Failed to connect to the database\n" unless
	$dbh = DBI->connect($opt_d,'','','Informix');

if ($opt_e)
{
	# Command line SQL statement
	sql_exec $opt_e;
}
else
{
	# Read SQL commands from files (or stdin)
	$cmd = "";
	while (<>)
	{
		next if /^\s*$/;
		$cmd .= $_;
		if (/;/)	# Inaccurate, but OK for first hack!
		{
			sql_exec $cmd;
			$cmd = "";
		}
	}
}

$dbh->disconnect;

__END__
