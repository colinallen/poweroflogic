#!/usr/bin/perl
##
## sv-cond.cgi

use CGI qw(:standard :html3);
require '../lib/header.pl';
require '../lib/logit.pl';

$mailto = 'random';

$cgi = new CGI;
$cgi->import_names('BR');
$program  = $cgi->url;
$fullprog  = $cgi->self_url;

####################################################
# ADD LOCAL MENU ITEMS HERE
# $polmenu{"Main Menu"} = "../menu.cgi";

($chapter,$exnum)=split(/\./,$BR::exercise,2);
$polmenu{"More from Ch. $chapter"} = "../menu.cgi?chapter=$chapter"
    if $BR::exercise;
$polmenu{"More from Ex. $BR::exercise"} = "$program?exercise=$BR::exercise&msfoo=".rand
    if $BR::rlqz;
#####################################################

srand; #seed random
$qsep = "-:-";
$sep = "::";

$debug=1;
$probfile = $EXHOME."$chapter/$chapter.$exnum";

for ($BR::action) {
    
    /Main/ and do { 
	print $cgi->redirect(-uri=>'../menu.cgi');
	last;
    };
    /Return/ and do { 
	print $cgi->redirect(-uri=>"../menu.cgi?chapter=7");
	last;
    };
    /Check/ and do { &check_answers };
    &generate_quiz($probfile);
}
    
########################################################################
# subroutine to pick random selection of questions from a problem file ...
# and (with the help of (answer_form) generate an appropriate quiz 

sub generate_quiz {
    $probfile = $_[0];
    my @prevchosen = @BR::prevchosen;

    $values;
    $qtype_marker = "\#!qtype";
    $preamble_marker = "\#!preamble";
    $preamble;
    my $numqs = 5;

    # Determine the number of questions in the quiz file

    $probfile =~ s/\||\.\.//g; # close pipeline exploit; CA 9-17-2004
    open(PROBFILE,$probfile);
    
    while(<PROBFILE>){
	chop;
	next if /$qtype_marker/;  #get $qtype and continue
	($preamble .= $_) and next if /$preamble_marker/;
	next if /\#/;
	next if $_ eq "";
	push @questions, $_;                     # Push each line in $probfile onto @questions
    }

    $values =~ s/\s+$//;
    $values =~ s/\s+/ /;

    close PROBFILE;
    
    $numqs=@questions if @questions<$numqs;
    my $plural = "s" if $numqs > 1;
    
    $preamble =~ s/\#!preamble//g;

### The following chunk of code generates a random list of quiz questions w/o duplicates
### It also checks that no previously chosen questions show up in later rounds


    if (@BR::prevchosen >= @questions) {           # If user has already been quizzed on all 
#	$cgi->param('prevchosen','');              # of the questions, make prevchosen nil;
	$cgi->delete('prevchosen');
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

    local $subtitle = "Exercise $BR::exercise, Conditional Forms";
    local $instructions = "";

    &start_polpage();
    &pol_header($subtitle,$instructions);  # create outer table, print the PoL header

### Generate the quiz

    print
	"<table border=0>\n",
	$cgi->startform(),
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
	$rlqz =~ s/ /+/g;
	&answer_form($ques,$ans);
    }

    print 
	"</table>\n";

    print
	"<hr width=98%>\n",
	"<center>",
	$cgi->submit(-name=>'action',-value=>'Check answers!'),
	$cgi->hidden('quiz',$quiz),
	$cgi->hidden('rlqz',&rot($rlqz)),
	$cgi->hidden('prevchosen',@prevchosen),
	$cgi->hidden('exercise',$BR::exercise),
	$cgi->end_form,
	;

    &pol_footer;

    &end_polpage;
}


########################################################
# subroutine to generate each line of the quiz displayed
sub answer_form {
    my ($q,$a) = @_;
    $a =~ s/^If //;
    $a =~ s/\.$//;
    my @values = split(', then ',$a);
    push(@values,'?');

    print 
	"<tr>",
	"<td align=left>\n",
	"$qnum.&nbsp;&nbsp;$ques",
	"<br>",
	"<table><tr>",
	"<td>&nbsp;&nbsp;If</td>",
	"<td>",
	$cgi->hidden(-name=>"ans_$qnum",-value=>"If "),
	$cgi->popup_menu(-name=>"ans_$qnum",
			 -values=>\@values,
			 -size=>1,
			 -default=>'?'),
	",</td></tr><tr><td>&nbsp;&nbsp;then</td><td>",
	$cgi->hidden(-name=>"ans_$qnum",-value=>", then "),
	$cgi->popup_menu(-name=>"ans_$qnum",
			 -values=>\@values,
			 -size=>1,
			 -default=>'?'),
	".</td></tr></table>\n",
	$cgi->hidden(-name=>"ans_$qnum",-value=>"."),
	"</td>\n",
	"</tr>\n";
}


########################################################################
# subroutine to check answers

sub check_answers {
    local $i=0;
    my $rlqz = &rot($BR::rlqz);
    local $nextq;
    local $subtitle = "Evaluation of your answers from Section&nbsp;$BR::exercise";
    local $instructions = "";
    local $logstuff = "$BR::exercise\n\n";
    
### Print out PoL logo and header

    &start_polpage('Evaluation of your quiz');
    &pol_header($subtitle,$instructions);

    print
	"<table>\n",  # put it all inside a one-cell table
	startform(),
	"<tr><td align=left>\n",
	h2("The Logic Tutor responds:"), 
	"<dl>\n";

    while ($rlqz) {
	$i++;                                            # question number
	($nextq,$rlqz) = split($qsep,$rlqz,2);           # put first ques in $rlqz in $nextq
	my ($ques,$errmsg,$ans) = split($sep,$nextq,3);  # split $nextq into 3 parts
	my @guess = $cgi->param("ans_$i");               # user guess
	my $guess = join "", $cgi->param("ans_$i");
	$ques =~ s/\+/ /g;                               # replace +'s with spaces in $ques
	my $rawguess = $guess;

	$ans =~ s/[+\s]//g;   # Necessary?
	$guess =~ s/[+\s]//g;

	my $correct = 0;
	$correct = 1 if $guess eq $ans;
	
	print "<dt>$i. $ques</dt>\n";
	$logstuff .= "$i. $ques\n";

	if ($guess =~ /\?/){
	    $logstuff .= "You did not answer this question.\n";
	    print "<dd><img src=$qmark>&nbsp;<em>You did not answer this question.</em></dd><p>";
#	} elsif ($guess eq $ans) {
	} elsif ($correct) {
	    $logstuff .= "Your answer of ``$rawguess\'\' is correct!\n";
	    print
		"<dd>",
		"<img src=$greentick>&nbsp;",
		"<em>Your answer of </em>``$rawguess\'\'<em> is correct!</em></dd><p>";
	    $currscore++;
	} else {
	    $errmsg =~ s/\+/ /g;
	    $logstuff .= "Your answer of ``$rawguess\'\' is incorrect!\n";
	    print 
		"<dd>",
		"<img src=$redx>&nbsp;",
		"<em>Your answer of </em>``$rawguess\'\'<em> is incorrect.</em></dd><p>";
	    if ($errmsg) {
		$logstuff .= "$errmsg\n";
		print
		    "<font size=-1><em>Explanation:  $errmsg</em></font><p>";
	    }
	}
    }
    print
	"</dl>\n",
	"</td></tr>\n",
	"</table>\n";

    print
	"<hr width=98%>\n",
	"<center>",
	$cgi->startform,
	$cgi->hidden(-name=>'exercise', -value=>$BR::exercise),
	$cgi->submit(-name=>'action', -value=>"More problems from Section $BR::exercise?"),
	$cgi->hidden(-name=>'prevchosen',-value=>@BR::prevchosen),
	$cgi->endform,
	"</center>\n";

    &pol_footer;
    &mailit($mailto,$logstuff);
    &end_polpage;
}

