#!/usr/bin/perl
# started by CA Dec 17 2001

use CGI qw(:standard :html3);
require 'lib/header.pl';

$cgi = new CGI;
$cgi->import_names('CGI');


$chapter = $CGI::resume;
$chapter =~ s/\..*//;

if ($CGI::resume eq $chapter) {
    $polmenu{"More from Ch. $chapter"} = "$cgibase/menu.cgi?chapter=$chapter";
} elsif ($CGI::resume) {
    $polmenu{"More from Ex. $CGI::resume"} = "$cgibase/menu.cgi?selected_exercise=$CGI::resume";
}

if ($gradecookie and $gradecookie ne "not logged in") {
    if (&check_authcookie) {
	&start_polpage('Results');
	&pol_header('Results');
	# look up results
	print "Need to look up results for $gradecookie";
	# print results
	print " and display them nicely with a mailto option.";
	if ($CGI::resume) {
	    print
		"<p>",
		"Show chapter $CGI::resume",
		" results first 'cuz that's what we're working on currently.",
		;
	    
	}
	print &chapter_menu_button;
    } else {
	$gradecookie = "not logged in";
	&start_polpage('Results');
	&pol_header('Results');
	print "Authentication error; your session may have expired -- please log in again";
    }
} else {
    # shouldn't be here
    &start_polpage('Results');
    &pol_header('Results');
    print "Your session expired.  Please log in again before checking results.";
}
&pol_footer;
&end_polpage;








