#!/usr/bin/perl -w
#
# @(#)$Id: examples/x11cgi_nodbi.pl version /main/3 1998-11-17 00:28:10 $
#
# Simple example of self-populating (self-regenerating) CGI Form
# Adapted from CGI.pm documentation; revised to work with CGI::Apache.

use strict;
use Apache;
use CGI::Apache;

my $q = new CGI::Apache;

my $clear = ($q->param('reset')) ? 1 : 0;
my @rainbow = ('red', 'orange', 'yellow', 'green', 'blue', 'indigo', 'violet');

# CGI::Apache doesn't support a suitable delete_all or Delete_all...
map { $q->delete($_); } $q->param if ($clear);

print	$q->header,
		$q->start_html('A Simple Example'),
		$q->h1('A Simple Example'),
		$q->start_form,
		"What's your name? ",
		$q->textfield(-name=>'name', -default=>'', -override=>$clear),
		$q->p,
		"What's the combination?", $q->p,
		$q->checkbox_group(	-name=>'words', -override=>$clear,
						-value=>['eenie', 'meenie', 'minie', 'moe'],
						-default=>['eenie', 'meenie']),
		$q->p,
		"What's your favourite colour? ",
		$q->popup_menu( -name=>'colour', -override=>$clear,
					-value=>[@rainbow]),
		$q->p,
		$q->submit,
		$q->submit(-name=>'reset', -value=>'Clear Form'),
		$q->end_form,
		$q->hr;

if ($q->param('name'))
{
	print	"Your name is ", $q->em($q->param('name')),
			$q->p,
			"You think the keywords are: ",
			$q->em(join(", ", $q->param('words'))), $q->p,
			"Your favourite colour is ",
			$q->em($q->param('colour')),
			$q->hr;
}

