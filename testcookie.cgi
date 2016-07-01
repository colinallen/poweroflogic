#!/usr/bin/perl -T
# cookie tester by CA 2012-09-28
push @INC, cwd;
require './lib/header.pl';


$pageoutcookie=&create_pageout_cookie('012345678','98765432'); # dummy values

$polmenu{'Help'} = 'help.cgi';

&start_polpage;

print "Cookie test. Now click Main Menu on the left and report to us whether you remained logged in as '1234'";

&pol_footer;
&end_polpage;

