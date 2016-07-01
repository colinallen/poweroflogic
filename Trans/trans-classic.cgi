#!/usr/bin/perl
##
## trans.cgi - translation module
## Chris Menzel

use CGI qw(:standard :html3);
require '../lib/header.pl';
require '../TT/calculate-tv.pl';
require '../lib/wff-subrs.pl';
require '../lib/qlwff-subrs.pl';
require '../Trans/ttree.pl';


$cgi = new CGI;
$cgi->import_names('TR');
$program  = $cgi->url;
$fullprog  = $cgi->self_url;

####################################################
# ADD LOCAL MENU ITEMS HERE
$polmenu{"Main Menu"} = "../menu.cgi";

($chapter,$exnum)=split(/\./,$TR::exercise,2);
$polmenu{"More from Ch. $chapter"} = "/cgi-pol/menu.cgi?chapter=$chapter"
    if $TR::exercise;
$polmenu{"More from Ex. $TR::exercise"} = "$program?exercise=$TR::exercise"
    if $TR::prob;
$polmenu{"Main Menu"} = "../menu.cgi";
#####################################################

srand; #seed random
$qsep = "-:-";
$sep = "::";

$debug=0;
local $probfile = $EXHOME."$chapter/$chapter.$exnum";

for ($TR::action) {
    
    /Main/ and do { 
	print $cgi->redirect(-uri=>'../menu.cgi');
	last;
    };
    /Return/ and do { 
	print $cgi->redirect(-uri=>"../menu.cgi?chapter=$chapter");
	last;
    };
    /Check/ and do { (&check_answers and &bye_bye) };
    &generate_quiz($probfile);
}
    
&bye_bye;

########################################################################
# subroutine to pick random selection of questions from a problem file ...
# and (with the help of (answer_form) generate an appropriate quiz 

sub generate_quiz {
    $probfile = shift;
    $section = $probfile;
    $section =~ s/^.*(\d+\.\d+)[A-Z]/$1/;
    $section =~ s/i//g;                     # Remove i's that might be in the file name
    $part = $probfile;
    $part =~ s/^.*\d+\.\d+([A-Z])/$1/;
    $part =~ s/i//g;                        # Remove i's that might be in the file name
    local $exercise = $TR::exercise;
    $exercise =~ s/i//g;

    my @prevchosen = @TR::prevchosen;

    $qtype;
    $values;
    $qtype_marker = "\#!qtype";
    $preamble_marker = "\#!preamble";
    $preamble;
    my $numqs = 5;
    $numqs = 3 if $TR::exercise eq '9.5B';

    # Determine the number of questions in the quiz file

    $probfile =~ s/\||\.\.//g; # close pipeline exploit; CA 9-17-2004
    open(PROBFILE,$probfile);
    
    while(<PROBFILE>){
	chop;
	($foo,$qtype) = split(/ /,$_,2) and next if /$qtype_marker/;  #get $qtype and continue
	($foo,$values) = split(/ /,$_,2) and next if /values/;
	($preamble .= $_) and next if /$preamble_marker/;
	next if /\#/;
	next if /^\s*$/;
	push @questions, $_;                     # Push each line in $probfile onto @questions
    }

    $values =~ s/\s+$//;
    $values =~ s/\s+/ /;

    close PROBFILE;
    $cgi->param('qtype',$qtype);
    
    $numqs=@questions if @questions<$numqs;
    my $plural = "s" if $numqs > 1;
    
    $preamble =~ s/\#!preamble//g;

### The following chunk of code generates a random list of quiz questions w/o duplicates
### It also checks that no previously chosen questions show up in later rounds


    if (@TR::prevchosen >= @questions) {           # If user has already been quizzed on all 
	$cgi->delete('prevchosen');                # of the questions, make prevchosen nil;
    }

    @prevchosen = $cgi->param('prevchosen');   # find out what nums have already been used

    my @selected;  # Variable to store random indices for selecting quiz questions
    $i=0;
    QUIZNUMS: while ($i<$numqs) {         
	                                  
	$j=int(rand @questions);          
	for ($n=0;$n<$i;$n++) {           
	    if ($j==$selected[$n]) {
		next QUIZNUMS;
	    }
	}
	if (@questions<=@selected+@prevchosen) {   # Check that we've got enough problems in the 
	    @selected=(@selected,$j);              # problem file to avoid repeats from previous 
                                                   # rounds, and if not,
	    $i++;                                  # just tack $j onto @selected directly ...
	    next QUIZNUMS;                         # and find the next number to put in @selected
	}
	for (@prevchosen) {        # If there are enough problems in the problem file,
	    if ($j==$_) {           # check to see if $j is equal to one of the nums in @prevchosen.
		next QUIZNUMS;      # If so, try another number...
	    }
	}
	@selected=(@selected,$j);   # If not, then $j isn't a repeat, so tack it onto @selected ...
	$i++;                       # and increment $i.
    }
    push @prevchosen, @selected;

    $cgi->param('prevchosen',@prevchosen);
    $j=0;

### Print out the form ###

#    local $subtitle = "Exercise $section$part";
    local $subtitle = "Exercise $exercise";
    local $instructions = "";

    &start_polpage();
    &pol_header($subtitle,$instructions);  # create outer table, print the PoL header

    print
	$cgi->startform();

### Generate the quiz

    print
	"<table border=0>\n",
	"<tr><td align=left>\n",
	 $preamble,
	"</td></tr>\n",
	"</table>\n";

    print
	"<table border=0>\n";

    for(@selected){
	$j++;
	$rlqz="$rlqz$questions[$_]$qsep";
	($ques,$err,$ans)=split($sep,$questions[$_],3);
	$qnum=$j;
	&answer_form;
    }

    print 
	"</table>\n";

    print
	"<hr width=98%>\n",
	"<center>",
	$cgi->submit(-name=>'action',-value=>'Check answers!'),
	$cgi->hidden('quiz',$quiz),
	$cgi->hidden('qtype',$qtype),
	$cgi->hidden('rlqz',&rot($rlqz)),
	$cgi->hidden('prevchosen',@prevchosen),
	$cgi->hidden('section',$section),
	$cgi->hidden('part',$part),
	$cgi->hidden('exercise',$TR::exercise),
	$cgi->end_form,
	$short_pol_footer;

    &bye_bye;
}


########################################################
# subroutine to generate each line of the quiz displayed
sub answer_form {

    my @values = split($sep,$values);
    push(@values,'?');
    
    print 
	"<tr><td align=left>\n",
	$cgi->textfield(-name=>"ans_$qnum",
			-style=>'font-family: monospace',
			-size=>30),
	"</td>\n",
	"<td align=left>\n",
	"$qnum.&nbsp;&nbsp;$ques</td>\n",
	"</tr>\n";
}


########################################################################
# subroutine to check answers

sub check_answers {
    my $i=0;
    my $rlqz = &rot($TR::rlqz);
    my $section = $TR::section;
    my $part = $TR::part;
    $part =~ s/i//g;
    my $chapter = $TR::section;
    $chapter =~ s/(\d+)\.\d+/$1/;
    local $nextq;
    local $subtitle = "Evaluation of your answers from Section&nbsp;$section, Part&nbsp;$part";
    local $instructions = "";
    
### Print out PoL logo and header

    &start_polpage('Evaluation of your quiz');

    print 
	startform();

    &pol_header($subtitle,$instructions);

    print
	"<table>\n",  # put it all inside a one-cell table
	"<tr><td align=left>\n",
	h2("The Logic Tutor responds:"), 
	"<dl>\n";

    while ($rlqz) {
	$i++;                                            # question number
	($nextq,$rlqz) = split($qsep,$rlqz,2);           # put first ques in $rlqz in $nextq
	my ($ques,$errmsg,$ans) = split($sep,$nextq,3);  # split $nextq into 3 parts
	my $user_ans = $cgi->param("ans_$i");            # user guess
	$ques =~ s/\+/ /g;                               # replace +'s with spaces in $ques (NECESSARY?)
	my $raw_user_ans = $user_ans;

	$ans =~ s/[\s]//g;
	$user_ans =~ s/[\s]//g;

#	print "Comparing $ans to $user_ans<br>";

	print "<dt>$i. $ques</dt>\n";

	print "<dd><img src=$qmark>&nbsp;<em>You did not answer this question.</em></dd><p>"
	    and next
		if $user_ans =~ /^\s*$/;

	print "<dd><img src=$redx>&nbsp;<em>Your answer</em> &nbsp;`<tt>$raw_user_ans</tt>'&nbsp; <em>is not a wff!</em></dd><p>"
	    and next
		if not &wff($user_ans);

	$ans = "($ans)"           # Add outer parens if missing
	    if &wff("($ans)");
	$user_ans = "($user_ans)"
	    if &wff("($user_ans)");

	print
	    "<dd>",
	    "<img src=$greentick>&nbsp;",
	    "<em>Your answer of</em> &nbsp;`<tt>$raw_user_ans</tt>'&nbsp; <em>is correct!</em></dd><p>"
		and next
		    if &paren_eq($ans,$user_ans);

	$result = &log_true("($ans<->$user_ans)");

	print
	    "<dd>",
	    "<img src=$qmark>&nbsp;",
	    "<em>For theoretical reasons, we are unable to determine precisely whether your answer of</em> &nbsp;`<tt>$raw_user_ans</tt>'&nbsp; <em>is correct.  Be sure your answer is no more complex than it needs to be.</em></dd><p>"
		and next
		    if $result == 2;

	print
	    "<dd>",
	    "<img src=$greentick>&nbsp;",
	    "<em>Your answer of</em> &nbsp;`<tt>$raw_user_ans</tt>'&nbsp; <em>is correct!</em></dd><p>"
		and next
		    if $result == 1;

	print 
	    "<dd>",
	    "<img src=$redx>&nbsp;",
	    "<em>Your answer of</em> &nbsp;`<tt>$raw_user_ans</tt>'&nbsp; <em>is incorrect.</em></dd><p>";
    }

    print
	"</dl>\n",
	"</td></tr>\n",
	"</table>\n";

    print
	"<hr width=98%>\n",
	"<center>",
	$cgi->startform,
	$cgi->hidden(-name=>'exercise', -value=>$TR::exercise),
	$cgi->submit(-name=>'action', -value=>"More problems from Section $TR::section$TR::part?"),
	$cgi->hidden(-name=>'prevchosen',-value=>@TR::prevchosen),
	$cgi->endform,
	"</center>\n";

    print
	$short_pol_footer;

    &bye_bye;
}

###
sub log_true {
    local $completed_open_branch = 0;
    local $calls = 0;
    my $wff = shift;
    my $insts = "";
    my $cons = $wff;
    $cons =~ s/[^a-u]//g;
    $cons = &remove_string_dups($cons);
    my $foo = &ttree(["~".$wff],[$insts],$cons);
#    print "FOO: $foo<br>";
    return $foo;
#    return &ttree(["~".$wff],[$insts],$cons);
}

###
sub paren_eq {

    local $wff1 = $_[0];
    local $wff2 = $_[1];
    $wff1 =~ tr/][/)(/;
    $wff2 =~ tr/][/)(/;
    return 1 if $wff1 eq $wff2 or "($wff1)" eq $wff2 or $wff1 eq "($wff2)";
    return 0;
}
