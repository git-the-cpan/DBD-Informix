#!/usr/bin/perl -w
#
# @(#)$Id: examples/x10cgi_nodbi.pl version /main/3 1998-11-17 00:28:10 $
#
# Simple example of self-populating (self-regenerating) CGI Form
# Cribbed from CGI.pm documentation.

use strict;
use CGI qw/:standard/;

my $clear = (param('reset')) ? 1 : 0;
my @rainbow = ('red', 'orange', 'yellow', 'green', 'blue', 'indigo', 'violet');
Delete_all if $clear;

print header,
		start_html('A Simple Example'),
		h1('A Simple Example'),
		start_form,
		"What's your name? ",
		textfield(-name=>'name', -default=>'', -override=>$clear), p,
		"What's the combination?", p,
		checkbox_group(	-name=>'words', -override=>$clear,
						-value=>['eenie', 'meenie', 'minie', 'moe'],
						-default=>['eenie', 'meenie']), p,
		"What's your favourite colour? ",
		popup_menu( -name=>'colour', -override=>$clear,
					-value=>[@rainbow]), p,
		submit, submit(-name=>'reset', -value=>'Clear Form'),
		end_form,
		hr;

if (param('name'))
{
	print "Your name is ", em(param('name')), p,
			"You think the keywords are: ", em(join(", ", param('words'))), p,
			"Your favourite colour is ", em(param('colour')),
			hr;
}

