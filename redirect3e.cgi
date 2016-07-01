#!/usr/bin/perl

use CGI;
require "./lib/header.pl";

$cgi=new CGI;
my $uri = $cgi->param('goto');
$uri = "/" if !$uri;
#print $cgi->redirect(-uri=>$uri);
&start_polpage("POWEROFLOGIC.COM - Redirect to current edition site");

&pol_header('Redirection from previous edition site');


print
    h3({-align=>'center'},"You reached this page from an outdated link"),
    "The current edition of the Logic Tutor corresponds to the 3rd edition of the text book.\n",
    "<br />\n",
    "<br />\n",
    "Versions of the site for earlier editions are no longer being maintained.\n",
    "<br />\n",
    "<br />\n",
		      
    "You may <a href=\"/\">go to the top-level page</a> for this site or <a href=\"$uri\">follow this link</a> to try to reach the more specific section of the site that you were attempting to find.\n",

    "<br />\n",
    "<br />\n",
		      
    "Please note that substantial differences exist between editions, so the second link may take you to a part of the site that does not correspond exactly to the exercises you were looking for.\n",
    ;

print &end_polpage;

exit;

