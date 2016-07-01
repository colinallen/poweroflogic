#!/usr/bin/perl
##
## arithmetic.cgi
## By Colin Allen
## hacked from mc by Chris Menzel,
##  based loosely on some earlier code by me and Colin Allen

use CGI qw(:standard :html3);
require '../lib/header.pl';

$cgi = new CGI;
$cgi->import_names('BR');
$program  = $cgi->url;
$fullprog  = $cgi->self_url;

####################################################
# ADD LOCAL MENU ITEMS HERE
# $polmenu{"Main Menu"} = "../menu.cgi";

($chapter,$exnum)=split(/\./,$POL::exercise,2);
$polmenu{"More from Ch. $chapter"} = "$cgibase/menu.cgi?chapter=$chapter"
    if $POL::exercise;
$polmenu{"More from Ex. $POL::exercise"} = "$program?exercise=$POL::exercise"
    if $POL::prob;
#####################################################

srand; #seed random
$qsep = "-:-";
$sep = "::";

$POL::probfile = $EXHOME."$chapter/$chapter.$exnum" unless $POL::probfile;

for ($POL::action) {
    
    /Main/ and do { 
	print $cgi->redirect(-uri=>'../menu.cgi');
	last;
    };
    /Return/ and do { 
	print $cgi->redirect(-uri=>"../menu.cgi?chapter=7");
	last;
    };
    /Check/ and do { &check_answers };
    &generate_quiz($POL::probfile);
}
    
########################################################################
# subroutine to pick random selection of questions from a problem file ...
# and (with the help of (answer_form) generate an appropriate quiz 

sub generate_quiz {
    $probfile = $_[0];
    $probfile =~ /^.*\/(\d+\.\d+)([A-Z]?)/;
    $section = $1;
    $part = $2;

    my @prevchosen = @POL::prevchosen;

    $qtype;
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
	($foo,$qtype) = split(/ /,$_,2) and next if /$qtype_marker/;  #get $qtype and continue
	($foo,$values) = split(/ /,$_,2) and next if /values/;
	($preamble .= $_) and next if /$preamble_marker/;
	next if /\#/;
	next if $_ =~ /^\s*$/;
	push @questions, $_;                     # Push each line in $probfile onto @questions
    }

    my $total_questions = @questions;

    $values =~ s/\s+$//;
    $values =~ s/\s+/ /;

    close PROBFILE;
    $cgi->param('qtype',$qtype);
    
    $numqs=@questions if @questions<$numqs;
    my $plural = "s" if $numqs > 1;
    
    $preamble =~ s/\#!preamble//g;

### The following chunk of code generates a random list of quiz questions w/o duplicates
### It also checks that no previously chosen questions show up in later rounds


    if (@POL::prevchosen >= @questions) {           # If user has already been quizzed on all 
#	$cgi->param('prevchosen','');              # of the questions, make prevchosen nil;
	$cgi->delete('prevchosen');
    }

    @prevchosen = $cgi->param('prevchosen');   # find out what nums have already been used

    my @selected;  # Variable to store random indices for selecting quiz questions
    $i=0;

  QUIZNUMS: while ($i<$numqs) {         
	                                  
      my $candidate=int(rand @questions)+1; # get human probnum
      next QUIZNUMS if grep /^$candidate$/, @selected; # seen this before
      
      if (@questions<=@selected+@prevchosen) {   # Check that we've got enough problems in the 
	  # problem file to avoid repeats from previous  rounds, and if not,
	  push @selected, $candidate;            # just tack $condidate onto @selected directly ...
	  $i++;                                  
	  next QUIZNUMS;                         # and find the next number to put in @selected
      }

      next QUIZNUMS if grep /^$candidate$/, @prevchosen ; # seen this before
      for (@prevchosen) {        # If there are enough problems in the problem file,
	  if ($candidate==$_) {  # check to see if $candidate is equal to one of the nums in @prevchosen.
	      next QUIZNUMS;      # If so, try another number...
	  }
      }
      push @selected, $candidate;   # If not, then $candidate isn't a repeat, so tack it onto @selected ...
      $i++;                         # and increment $i.
  }
    push @prevchosen, @selected;
    
    $cgi->param('prevchosen',@prevchosen);
    $cgi->param('probnums',@selected);
    
### Print out the form ###
    
    local $subtitle = "Exercise $section";
    $subtitle .= "$part: Probability" if $part;
    local $instructions = "";

    &start_polpage();
    &pol_header($subtitle,$instructions);  # create outer table, print the PoL header

    print $cgi->startform();

### Generate the quiz

    print table({-border=>0},
		Tr(td({align=>left},
		      $preamble)));

    print
	"<table border=0>\n",
	Tr(td({-colspan=>2},
	      "<strong>",
	      "Type number or formula for correct answer in the space provided \n",
	      "<br>",
	      "(e.g. <tt>0.25</tt> or ",
	      "<tt>1/4</tt> or <tt>13/52</tt> or <tt>(12+1)/(4*13)</tt>)\n",
	      "</strong>"));
    

    my $j=0;
    for(@selected){
	# $_-1 gives array index for @questions
	$rlqz="$rlqz$questions[$_-1]$qsep";
	($ques,$err,$ans)=split($sep,$questions[$_-1],3);
	$qnum=++$j; 
	$rlqz =~ s/ /+/g;
	&answer_form;
    }

    print 
	"</table>\n";

    $rlqz = &rot($rlqz);
    print
	"<hr width=98%>\n",
	"<center>",
	$cgi->submit(-name=>'action',-value=>'Check answers!'),
	$cgi->hidden('quiz',$quiz),
	$cgi->hidden('qtype',$qtype),
	$cgi->hidden('rlqz',$rlqz),
	$cgi->hidden('prevchosen',@prevchosen),
	$cgi->hidden('section',$section),
	$cgi->hidden('part',$part),
	$cgi->hidden('probfile',$probfile),
	$cgi->hidden('total_questions',$total_questions),
	$cgi->hidden('exercise'),
	$cgi->hidden('probnums'),
	"</center>",
	$cgi->endform,
	;

    &pol_footer;
    &end_polpage;
}


########################################################
# subroutine to generate each line of the quiz displayed
sub answer_form {

    my @values = split($sep,$values);
    push(@values,'?');
    
    print 
	Tr(td({-align=>'left'},
	      [ $cgi->textfield(-name=>"ans_$qnum",
				-style=>"font-family: monospace",
				-size=>8),
		"$qnum.&nbsp;&nbsp;$ques</td>\n",
		]));
}


########################################################################
# subroutine to check answers

sub check_answers {
    local $i=0;
    my $rlqz = $POL::rlqz;
    $rlqz = &rot($rlqz);
    local $nextq;
    local $subtitle = "Evaluation of your answers from Section&nbsp;$POL::section";
    $subtitle .= ", Part&nbsp;$POL::part" if $POL::part;
    local $instructions = "";
    
### Print out PoL logo and header

    &start_polpage('Evaluation of your quiz');

    &pol_header($subtitle,$instructions);

    print
	"<table>\n",  # put it all inside a one-cell table
	"<tr><td align=left>\n",
	h2("The Logic Tutor responds:"), 
	"<dl>\n";

    my @probs_attempted;
    my @student_answers;
    while ($rlqz) {
	$i++;      # question number
        $probnum = shift @POL::probnums;
	($nextq,$rlqz) = split($qsep,$rlqz,2);           # put first ques in $rlqz in $nextq
	my ($ques,$errmsg,$ans) = split($sep,$nextq,3);  # split $nextq into 3 parts
	my $guess = $cgi->param("ans_$i");               # user guess
#	my $guess = $POL::$ans."_".$i;
	$ques =~ s/\+/ /g;                               # replace +'s with spaces in $ques
	my $rawguess = $guess;

	print "<dt>$i. $ques\n";

	if ($guess =~ /^\s*$/) {
	    print 
		"<dd>",
		"<img src=$qmark>&nbsp;",
		"<em>You did not answer this question.</em><p>";
	} elsif ($guess =~ /[A-z]/) { # do this to stop bad stuff from being eval'ed next
	    print 
		"<dd>",
		"<img src=$redx>&nbsp;",
		"<em>Your answer of </em>``$rawguess\'\'<em> does not appear to be a number.</em><p>";
	} elsif (eval($guess) == eval($ans) or
		 eval($guess) eq eval($ans)) {
	    print
		"<dd>",
		"<img src=$greentick>&nbsp;",
                "<em>Your answer of </em><tt>$rawguess</tt> ";

	    if ($rawguess !~ /^\d*\.?\d*$/) {
		my $rounded = &rounded4($guess);
		print " (";
		print "~" if eval($guess) != $rounded;
		print "=$rounded)";
	    }
	    
	    print " </em>is correct!</em><p>";
		    
	    push @probs_attempted, $probnum+1;
            push @student_answers, "1";
	    $currscore++;
	} else {
	    $errmsg =~ s/\+/ /g;
	    print 
		"<dd>",
		"<img src=$redx>&nbsp;",
                "<em>Your answer of </em><tt>$rawguess</tt>";

	    if ($rawguess !~ /^\d*\.?\d*$/) {
		my $rounded = &rounded4($guess);
		print " (";
		print "~" if eval($guess) != $rounded;
		print "=$rounded)";
	    }
	    
	    print
                "<em> is incorrect! ",
#		"Should be $ans (=",  ## for debugging
#		eval($ans),           ##
#		")",                  ##
		"</em><p>";

	    print "yes" if eval($guess) == eval($ans);
	    if (0 && $errmsg) {
		print
		    "<font size=-1><em>Explanation:  $errmsg</em></font><p>";
	    }
	    push @probs_attempted, $probnum+1;
            push @student_answers, "0";
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
	$cgi->hidden(-name=>'probfile', -value=>$POL::probfile),
	$cgi->submit(-name=>'action', -value=>"More problems from Section $POL::section$POL::part?"),
	$cgi->hidden(-name=>'prevchosen',-value=>@POL::prevchosen),
	$cgi->hidden('exercise'),
	$cgi->hidden('probnums'),
	$cgi->hidden('total_questions',$total_questions),
	$cgi->endform,
	"</center>\n";

    my %pageoutdata = %pageoutid;
    if (%pageoutdata &&  @probs_attempted && @student_answers) { # send result to pageout
        $pageoutdata{'vendor_assign_id'} = $POL::exercise;
        $pageoutdata{'assign_probs'} = [ @probs_attempted ];
        $pageoutdata{'student_score'} = [ @student_answers ];
        &send_to_pageout(%pageoutdata);
    }
    
    &pol_footer;
    &end_polpage;
}

sub rounded4 { # float
    my $rounded = sprintf("%.4f", eval($_[0]));
    $rounded =~ s/\.?0+$//;
    return $rounded;
}
