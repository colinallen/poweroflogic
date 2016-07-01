#!/usr/bin/perl

# this is venn2.cgi
# Version 0.1 Aug 19, 2001 by CA

require "../lib/header.pl";
require "./twocirc_subrs.pl";

$imagedir="/Images/Venn2";
srand;

# comment out next line if you don't want mail to be sent
#$mailto = 'random';
#$mailto = 'colin';

$debug = 1 if $cgi->url =~ /mayfield/i;

local $title ="Venn Diagrams ";
$title = "Exercise $POL::exercise, $title" if $POL::exercise;


################# keep track of prevchosen items
@POL::prevchosen = split(/::/,$POL::prevchosenstring)
    if $POL::prevchosenstring;
%prevchosen = ();
for (@POL::prevchosen) {
    next unless $_;              # skip bogus values
    $prevchosen{$_} = 1;         # store legit values
}
$prevchosen{$POL::probnum} = 1 if $POL::probnum;  # register current probnum
$cgi->param('prevchosen', sort {$a<=>$b} keys %prevchosen); # set in cgi
$prevchosen_string = join "::", keys %prevchosen; # used for menu
################ end prevchosen maintenance


####################################################
# ADD LOCAL MENU ITEMS HERE
# $polmenu{"Main Menu"} = "../menu.cgi";

if ($POL::exercise =~ /^(\d+)\./) {
    $polmenu{"More from Ch. $1"} = "../menu.cgi?chapter=$1";
    $polmenu{"More from Ex. $POL::exercise"} = $cgi->url."?exercise=$POL::exercise&prevchosenstring=$prevchosen_string&do=".time;
}

$polmenu{'Help with Venn'} = "../help.cgi?helpfile=vennhelp.html"
    if $POL::prob;

#####################################################

&start_polpage($title);

if ($POL::prob) {
    $POL::prob = &rot($POL::prob);
} else {
    &picksyll;
    &bye_bye;
#    $POL::prob = &twocirc_random_pick;
#    $cgi->param('prob',&rot($POL::prob));
}
    
($statement,$subject,$predicate,$diag)
    = split("::",$POL::prob,4);

if ($POL::action =~/Check/) {
    &twocirc_checkdiag($subject,$predicate,$statement);
} elsif ($POL::action =~ /Shad|Partic/) {
    &twocirc_redraw($subject,$predicate,$statement,$title);
} else {
    &twocirc_draw($subject,$predicate,$statement,"0000.gif",$title);
}

&end_polpage();

