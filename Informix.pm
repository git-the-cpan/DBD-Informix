#   $Id: Informix.pm,v 1.18 1995/08/15 05:31:30 timbo Rel $
#
#   Copyright (c) 1994,1995 Tim Bunce
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.

{
    package DBD::Informix;

    require DBI;

    require DynaLoader;
    @ISA = qw(DynaLoader);

	$VERSION = "0.22";

    bootstrap DBD::Informix;

    $err = 0;		# holds error code   for DBI::err
    $errstr = "";	# holds error string for DBI::errstr
    $drh = undef;	# holds driver handle once initialised

    sub driver{
	return $drh if $drh;
	my($class, $attr) = @_;

	unless ($ENV{'INFORMIXDIR'}){
	    foreach(qw(/usr/informix /opt/informix /opt/Informix)){
		$ENV{'INFORMIXDIR'}=$_,last if -d "$_/rdbms/lib";
	    }
	    my $msg = ($ENV{INFORMIXDIR}) ? "set to $ENV{INFORMIXDIR}" : "not set!";
	    warn "INFORMIXDIR $msg\n";
	}

	$class .= "::dr";

	# not a 'my' since we use it above to prevent multiple drivers

	$drh = DBI::_new_drh($class, {
	    'Name' => 'Informix',
	    'Version' => $VERSION,
	    'Err'    => \$DBD::Informix::err,
	    'Errstr' => \$DBD::Informix::errstr,
	    'Attribution' => 'Informix DBD by Alligator Descartes',
	    });

	$drh;
    }

    1;
}


{   package DBD::Informix::dr; # ====== DRIVER ======
    use strict;

    sub errstr {
	DBD::Informix::errstr(@_);
    }

    sub connect {
	my($drh, $host, $dbname, $user, $pass)= @_;

	# create a 'blank' dbh

	my $this = DBI::_new_dbh($drh, {
            'Host' => $host,
	    'Name' => $dbname,
            'User' => $user,
            'Pass' => $pass
	    });

	# Call Informix login func in the Informix.xs file
	# and populate internal handle data.

	DBD::Informix::db::_login($this, $host, $dbname, $user, $pass)
	    or return undef;

	$this;
    }

}


{   package DBD::Informix::db; # ====== DATABASE ======
    use strict;

    sub errstr {
	DBD::Informix::errstr(@_);
    }

    sub prepare {
	my($dbh, $statement)= @_;

	# create a 'blank' dbh

	my $sth = DBI::_new_sth($dbh, {
	    'Statement' => $statement,
	    });

	# Call Informix OCI oparse func in Informix.xs file.
	# (This will actually also call oopen for you.)
	# and populate internal handle data.

	DBD::Informix::st::_prepare($sth, $statement)
	    or return undef;

	$sth;
    }

}


{   package DBD::Informix::st; # ====== STATEMENT ======
    use strict;

    sub errstr {
	DBD::Informix::errstr(@_);
    }
}

1;
