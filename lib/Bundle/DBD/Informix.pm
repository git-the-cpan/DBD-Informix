# @(#)$Id: Informix.pm,v 100.4 2002/02/08 22:50:19 jleffler Exp $

package Bundle::DBD::Informix;

$VERSION = '2005.01';

1;

__END__

=head1 NAME

Bundle::DBD::Informix - A bundle to install all DBD::Informix related modules

=head1 SYNOPSIS

C<perl -MCPAN -e 'install Bundle::DBD::Informix'>

=head1 CONTENTS

Digest::MD5  - Perl interface to the MD5 Algorithm by GAAS (Gisle Aas)

Time::HiRes  - High Resolution Timing by DEWEG (Douglas Wegscheid)

Bundle::DBI  - Bundle for DBI by TIMB (Tim Bunce)

DBD::Informix  - DBD::Informix by JOHNL (Jonathan Leffler)

=head1 DESCRIPTION

This bundle includes all the modules used by the Perl Database
Interface (DBI) driver for Informix (DBD::Informix), assuming the
use of DBI version 1.02 or later, created by Tim Bunce.

If you've not previously used the CPAN module to install any
bundles, you will be interrogated during its setup phase.
But when you've done it once, it remembers what you told it.
You could start by running:

    C<perl -MCPAN -e 'install Bundle::CPAN'>
    C<perl -MCPAN -e 'install Bundle::libnet'>
    C<perl -MCPAN -e 'install Bundle::LWP'>

Note that DBD::Informix does not directly use Digest::MD5.  However, when
Informix takes over support for DBD::Informix, then you may be required to
demonstrate that the MD5 checksums of the code you've got match the
original, or you'll be required to provide the diffs between the original
and what you are using.  The shell script md5.verify and Perl script
md5.check will be used to do this.

DBD::Informix uses the Time::HiRes module for timing insert cursors.

=head1 SEE ALSO

Bundle::DBI

=head1 AUTHOR

Jonathan Leffler E<lt>F<jleffler@informix.com>E<gt>

=head1 THANKS

This bundle was created by ripping off Bundle::libnet created by 
Graham Barr E<lt>F<gbarr@ti.com>E<gt>, and radically simplified
with some information from Jochen Wiedmann E<lt>F<joe@ispsoft.de>E<gt>.

  Copyright 1998-1999 Jonathan Leffler
  Copyright 2000      Informix Software Inc
  Copyright 2002      IBM

=cut
