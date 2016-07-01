#!/usr/bin/perl

use CGI;
$cgi = new CGI;
$cgi->import_names('CGI');

print
    $cgi->header,
    $cgi->start_html,
    ;

if ($CGI::pid) {
    system("kill -9 $CGI::pid");
    print
	"Attempted to kill $CGI::pid",
	;
}

print
    $cgi->startform,
    $cgi->textfield(-name=>'pid',-size=>6),
    $cgi->submit(-name=>'kill'),
    $cgi->endform,
    $cgi->end_html,
    ;
