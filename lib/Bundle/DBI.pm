# @(#)$Id: DBI.pm,v 1.3 1998/11/03 00:52:51 jleffler Exp $

package Bundle::DBI;

$VERSION = '1.02';

1;

__END__

=head1 NAME

Bundle::DBI - A bundle to install all DBI related modules

=head1 SYNOPSIS

C<perl -MCPAN -e 'install Bundle::DBI'>

=head1 CONTENTS

Storable  - Storable by RAM (Raphael Manfredi)

RPC::pClient  - RPC::pClient by JWIED (Jochen Wiedmann)

DBI  - DBI by TIMB (Tim Bunce)

=head1 DESCRIPTION

This bundle includes all the modules used by the Perl Database
Interface (DBI) module for version 1.02, created by Tim Bunce.
It may not work on non-Unix platforms because of dependencies on
the Sys::Syslog module which may not be available on non-Unix
platforms.
Note that the prerequisites are not really needed for DBI proper,
but they are used by DBI::Proxy which is bundled with DBI.

This bundle does not deal with the various database drivers (eg
DBD::Informix, DBD::Oracle), most of which require software from
sources other than CPAN.

If you've not previously used the CPAN module to install any
bundles, you will be interrogated during its setup phase.
But when you've done it once, it remembers what you told it.
You could start by running:

    C<perl -MCPAN -e 'install Bundle::CPAN'>

=head1 BUGS

On Solaris 2.6 with Perl 5.004_04, the Sys::Syslog module used by
Storable during testing did not work until I ran:

    C<cd /usr/include; h2ph * sys/*>

A subset of these files would have sufficed (syslog.h,
sys/syslog.h, and sys/feat_test.h at a minimum; probably more).

=head1 AUTHOR

Jonathan Leffler E<lt>F<jleffler@informix.com>E<gt>

=head1 THANKS

This bundle was created by ripping off Bundle::libnet created by 
Graham Barr E<lt>F<gbarr@ti.com>E<gt>, and was then seriously
refined with the help of information from Jochen Wiedmann E<lt>F<joe@ispsoft.de>E<gt>.

=cut
