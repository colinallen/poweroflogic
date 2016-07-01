#!/usr/bin/perl

use CGI;
$cgi=new CGI;
my $uri = $cgi->param('goto');
$uri = "/" if !$uri;
print $cgi->redirect(-uri=>$uri);
exit;

