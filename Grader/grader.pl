#!/usr/bin/perl
use IPC::Open2;
require '../lib/header.pl';
require "../Grader/grader-subrs.pl";
$checker = '../Proof/proof.pl';
$ttchecker = '../TT/grader-check-tt.pl';

$LSO = quotemeta(':.');
$RSO = quotemeta('.:');

@ts = (time); # tag stack
$errors = "";
$linecount=0;
$element_content = "";
$problem_id = 0;

my @input;
while (<>) { # slurp in XML document
    chomp;
    ++$linecount;
    next if s/<\?[^>]*\?>//g;
    next if /^\s*$/;

    # print "\n$linecount $_";
    push @input, $_;
}


%HASH = &parse_xml(@input);

print "================RECEIVED======================\n";

print &xmlify(\%HASH);

$HASH{'type'} = 'response'; # change its type

&grade_hash(\%HASH);


print "\n\n\n\n================RETURNED======================\n";

print &xmlify(\%HASH);
