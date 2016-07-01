#!/usr/bin/perl
# grader-check-symb.pl
# Chris Menzel, 30 Oct 2003

# Got to get STDIN before requires when called by grader.pl
while (<>) {
    chomp;
    next if /^\s*$/;   # Strip out any blank lines
    ++$i;
#    print "INPUT LINE $i $_\n<br />";
    push @input, $_;
}

local $completed_open_branch = 0;

############
# Requires #
############

# The maid did it only if a knife was not the murder weapon.  (M: The
# maid did it.  K: A knife was the +murder weapon) M->~K

require "../lib/header.pl";
require "../Trans/ttree.pl";
require "../lib/wff-subrs.pl";
require "../lib/qlwff-subrs.pl";

# $ques = @input[0];
# $rawans = @input[1];
# ($sentence,$scheme,$rawsymb) = split(/\s*\(|\)\s*/,$ques,3);

# Incoming <question /> form from PageOut is 
# SENTENCE (SCHEME)\nCANAONICAL_SYMB
 
$sent_scheme = @input[0];
$rawsymb = @input[1];
$rawans = @input[2];

# remove when square bracket mystery solved
$test_rawans = $rawans;
$test_rawans =~ s/^\s*\[(.*)\]\s*$/$1/;
$rawans = $test_rawans
  if &wff($test_rawans) and not &wff($rawans);

# remove when square bracket mystery solved
$test_rawsymb = $rawsymb;
$test_rawsymb =~ s/^\s*\[(.*)\]\s*$/$1/;
$rawsymb = $test_rawsymb 
  if &wff($test_rawsymb) and not &wff($rawsymb);

($sentence,$scheme) = split(/\s*\(\s*/,$sent_scheme,2);

$scheme =~ s/\)\s*$//;  # remove trailing paren
chomp $sentence;
chomp $rawsymb;
chomp $rawans;
$rawsymb =~ s/\s//g;
$rawans =~ s/\s//g;

## show the question elements
print "<p />";
print "<strong>Sentence:</strong> $sentence<br />\n";
print "<strong>Scheme:</strong> $scheme<br />\n";
print "<strong>Instructor Answer:</strong> $rawsymb<br />\n";

unless ($sentence and $scheme and $rawsymb) {
    print "The question was malformed: at least one of the required elements listed above is missing\n";
    exit;
}

print "<em>The instructor\'s answer $rawsymb is not well-formed!</em>\n" and exit
    if !&wff($rawsymb);

## Input errors by student
print "<em>This question was not answered by the student</em>\n" and exit
    unless $rawans;

print "<em>The student's answer $rawans is not well-formed.</em>\n" and exit
    if !&wff($rawans);

## Finally we can actually check the symbolization
$ans = &add_outer_parens($rawans);

$symb = &add_outer_parens($rawsymb);

$negbicond = "~($ans<->$symb)";

die $negbicond;

$eval = &ttree_wrapper([$negbicond],"","","",""),"\n";

print
    "<strong>Evaluation: <em>Correct!</em></strong> <br />",
    "<strong>Message:</strong> The symbolization \"<tt>$rawans</tt>\" ",
    "of the sentence <p /><center>$sentence</center><p /> ",
    "under the scheme of abbreviation<p /><center>$scheme</center><p /> ",
    "is correct!\n<p />" and exit
    if $eval == 1;

print
    "<strong>Evaluation: <em>Incorrect</em></strong><br />",
    "<strong>Message:</strong> The symbolization <tt>$rawans</tt> of ",
    "the sentence<p /> <center>\"$sentence\"</center><p />  under the ",
    "scheme of abbreviation<p /><center>$scheme</center><p /> ",
    "is not correct.  The correct answer is (anything logically ",
    "equivalent to) \"<tt>$rawsymb</tt>\".\n<p />" and exit
    if $eval == 0;
    
print
    "<strong><em>TIMED OUT!</em></strong>  The symbolization checker was not able ",
    "to determine whether or not $ans is a correct symbolization of \"$sentence\".\n";

