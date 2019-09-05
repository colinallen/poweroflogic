#!/usr/bin/perl -T

# this is help.cgi
# a simple interface for showing help

# parameters are:
# helpfile: relative to docs/Help/
# helpsubject: provides a title
# prevwork: script to execute to return to previous point

$debug=0;
$server = $ENV{'SERVER_NAME'};
$server =~ s/^www\.//;
$server =~ /(\w+)\.com/;
$site = $1;

#require "/home/www/sites/$site/cgi/lib/header.pl";
require "./lib/header.pl";

$helpfile = $cgi->param('helpfile');
if ($helpfile) {
    ($helpfile,$rubbish) = split(/\?/,$helpfile);
    $helpfile =~ s/\||\.\.//g; # remove pipeline exploit - CA 9-17-04
    $helpfile =~ s/^\///;       # disallow leading slash
    $helpfile =~ s/\.\.//g;    # disallow directory traversal
    $helpfile =~ /([^\/]?\/?[^\/]+)$/;
    $helpfile = $1; #untainted
    $helpfile = "help.html" if $helpfile =~ /\/\//; # badly formed
} else {
    $helpfile = 'help.html';
}

$realhelpfile = "$HELPDIR/$helpfile";

$helpmessage = $cgi->param('helpsubject');
$helpmessage = "HELP" unless $helpmessage;

#$prevwork = $cgi->param('prevwork');
#$prevwork = &decode_query_string($prevwork);
#$prevworktitle = '<font color=red>Return to work</font>';
#$polmenu{$prevworktitle} = "$prevwork";

$polmenu{'Main Menu'} = 'menu.cgi';
&start_polpage($helpmessage);
&pol_header($helpmessage);

#print "debug:referred by $prevwork";

open(FILE,$realhelpfile)
    || &html_error("The help file `$helpfile' you requested is not yet available. <br>Please check back soon to see whether it has become available.");

print
    $cgi->startform,
    $cgi->hidden('helpmessage'),
    $cgi->hidden('prevwork');

print
    "<table width=94% align=center>",
    "<!-- begin help contents -->",
    "<tr><td>\n",
    ;

while (<FILE>) {
    print;
}
close FILE;
print
    "</td></tr>",
    "</table>",
    "<!--end help contents -->\n",
    ;

print
    "<hr width=98%>",
    $cgi->endform,
    "<center>";

print # button to get back to work
    $cgi->startform(-method=>'post',
		    -action=>"$prevwork"),
    $cgi->submit(-value=>'Return to previous work'),
    $cgi->endform
    if $prevwork;


print # button for front page of help system
    $cgi->startform,
    $cgi->submit(-value=>'General Help'),
    $cgi->endform
    if $helpfile;

print # failsafe return method
    "<font color=maroon>",
    "Use the browser's back arrow to return to previous page",
    "</font>",
    "</center>";

&pol_footer;
&end_polpage;

sub html_error { # dirty exit
    my ($err_msg) = @_;
    print
	"<center>",
        $err_msg,
	"</center>",
        $cgi->Dump;
    &pol_footer();
    &mailit('logic.pedallers@gmail.com',$err_msg);
    &end_polpage;
}

