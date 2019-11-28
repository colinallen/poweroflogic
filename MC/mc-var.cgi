#!/usr/bin/perl
##
## mc_var.cgi
## By Chris Menzel, based loosely on some earlier code by me and Colin Allen


require '../lib/header.pl';
require '../lib/logit.pl';
require '../MC/mc-common.pl';

$program  = $cgi->url;
$fullprog  = $cgi->self_url;

srand; #seed random
$asep = "%%";      # answertype separator
$qsep = "-:-";     # separator b/w questions in $rlqz
$sep = "::";

@questions;
@prev_chosen = ();
push @prev_chosen, @POL::prev_chosen if (@POL::prev_chosen);

####################################################
# ADD LOCAL MENU ITEMS HERE
# $polmenu{"Main Menu"} = "../menu.cgi";

($chapter,$exnum)=split(/\./,$POL::exercise,2);
$polmenu{"More from Ch. $chapter"} = "../menu.cgi?chapter=$chapter"
    if $POL::exercise;

if (@prev_chosen and $POL::action =~ /Check/) {
    my $prev_chosen_string = '&prev_chosen='.join('&prev_chosen=',@prev_chosen) 
      if @prev_chosen < $POL::total_questions;
    if ($POL::user_option =~/random/) {
        $polmenu{"More from Ex. $POL::exercise"} = "$program?exercise=$POL::exercise&action=More$prev_chosen_string";
    } else {
        $polmenu{"More from Ex. $POL::exercise"} = "$program?exercise=$POL::exercise&action=Choose$prev_chosen_string";
    }
}

#####################################################

$POL::probfile = $EXHOME."$chapter/$chapter.$exnum" unless $POL::probfile;

for ($POL::action) {

    /Main/ and do {
	print $cgi->redirect(-uri=>'../menu.cgi');
	last;
    };
    /Check/ and do
      { (&check_answers($POL::user_option,
			$POL::rlqz,
			$POL::exercise,
			$POL::total_questions,
			@POL::probnums)
	 and &bye_bye) };

    /All/ and do
      { (&generate_full_MCV_quiz($POL::probfile,$POL::exercise) and &bye_bye) };

    /More|Random/ and do
      { (&generate_random_MCV_quiz($POL::probfile,$POL::exercise) and &bye_bye) };

    /Choose|User/ and do
      { (&pick_probs($POL::probfile,$POL::exercise) and &bye_bye) };

    /Generate/ and do
      { (&generate_user_choice_MCV_quiz($POL::probfile,$POL::exercise) and &bye_bye) };
    
    &choose_quiz_type($POL::probfile,$POL::exercise);
}
    
&bye_bye;

########################################################################
# subroutine to pick random selection of questions from a problem file ...
# and (with the help of (answer_form) generate an appropriate quiz 

sub generate_random_MCV_quiz {
    local ($probfile,$exercise) = @_;
    my $user_option = 'random';
    local $numqs = 5;

# Determine the number of questions in the quiz file

    $probfile =~ s/\||\.\.//g; # close pipeline exploit; CA 9-17-2004
    open(PROBFILE,$probfile);
    
    while(<PROBFILE>){
	chomp;
	($foo,$qtype) = split(/ /,$_,2) and next if /$qtype_marker/;  #get $qtype and continue
	($preamble .= $_) and ($logstuff .= "$_\n") and next if /\#!preamble/;
	next if /\#/;
	next if /^\s*$/;
	push @questions, $_;
    }

    close PROBFILE;

    $numqs=@questions if @questions<$numqs;
    local $total_questions = @questions;
    my $plural = "s" if $numqs > 1;

    $preamble =~ s/\#!preamble//g;
    $logstuff =~ s/\#!preamble//g;

    my @probnums = &generate_random_question_list;
    push @prev_chosen, @probnums;

### Print out the form ###

    local $subtitle = "Exercise $POL::exercise, Multiple Choice";
    local $instructions = "";

    &start_polpage();
    &pol_header($subtitle,$instructions);  # create outer table, print the PoL header

### Generate the quiz

# DEBUG
#     $num_selected = @probnums;
#     print "num selected: $num_selected<br>";
#     $num_prev_chosen = @prev_chosen;
#    print "num prev chosen: $num_prev_chosen<br>";
#
#     print
#       "selected: @probnums<br>",
#       "prev_chosen: @prev_chosen<br>";
# End DEBUG

    print

	"<table border=0>\n",
	"<tr><td align=left>\n",
	 $preamble,
	"</td></tr>\n",
	"</table>\n";

    print                       # begin the table that will contain the quiz
	$cgi->startform(),
	"<table border=0>\n";    

    my $j=0;
    for(@probnums){
	$j++;
	$rlqz .= "$questions[$_-1]$qsep";  # Can we remove quotes?  (Try later.)
	my ($ques,$answerstuff)=split($sep,$questions[$_-1],2);  # Grab the question and answerstuff
	&display_ques($ques,$answerstuff,$j);
    }

    print 
	"</table>\n";

    $cgi->param('prev_chosen',@prev_chosen);
    $cgi->param('probnums',@probnums);

    print
      "<hr width=98%>\n",
      "<center>",
      $cgi->hidden('user_option',$user_option),
      $cgi->hidden('quiz',$quiz),
      $cgi->hidden('qtype',$qtype),
      $cgi->hidden('rlqz',&rot($rlqz)),
      $cgi->hidden('prev_chosen'),
      $cgi->hidden('logstuff',$logstuff),
      $cgi->hidden('exercise',$exercise),
      $cgi->hidden('total_questions',$total_questions),
      $cgi->hidden('probnums'),
      $cgi->submit(-name=>'action',-value=>'Check answers!'),
      $cgi->end_form;
    
    &pol_footer;                                              # Close the table started by pol_header
    &end_polpage;                                             # Close the table started by start_polpage

}


########################################################
# subroutine to generate each line of the quiz displayed
sub display_ques {

    my ($ques,$answerstuff,$qnum) = @_;
    my @answerstuff = split(/$asep/,$answerstuff);  # Split up the various parts of the problem
    shift @answerstuff;                             # Array will have an empty first element, cuz %% occurs
                                                    # at the beginning of $answerstuff; get rid of it w/ shift
    my $num_answertypes = scalar @answerstuff;

    print 
      	"<tr><td colspan=3></td></tr>",
	"<tr>\n",
	"<td align=left colspan=3>\n",
	"$qnum.&nbsp;&nbsp;$ques",
	"</td>\n",
	"</tr>\n",
	"<tr>\n";

    for ($j=0;$j<$num_answertypes;$j++) {

	$jth_answertype = @answerstuff[$j];
	$jth_answertype =~ s/^(.*?)$sep(.*)/$1/;
	$jth_options = $2;
	$jth_options =~ s/^(.*)$sep(.*)$sep(.*)$sep\s*$/$1/;
	$jth_answer = $2;
	$jth_errormsg = $3;
	@jth_options = split($sep,$jth_options);

	print
	    "<td align=left>";

	if ($jth_answertype =~ /POPUP/) {
    	    print 
		$cgi->popup_menu(-name=>"userans_$qnum.$j",
				 -values=>\@jth_options,
				 -size=>1,
				 -default=>'?'),
	} else {
	    print 
		$cgi->textfield(-name=>"userans_$qnum.$j",
				-size=>30);
	}

	print
	    $cgi->hidden("answer_$qnum.$j",$jth_answer),
	    $cgi->hidden("errormsg_$qnum.$j",$jth_errormsg);

	print
	    "</td>\n";
    }
    print
	"</tr>\n";
}

###################################
### Generate quiz from user choices

sub generate_user_choice_MCV_quiz {

    my ($probfile,$exercise) = @_;

#    my $subtitle = "Exercise $exercise";
    my $user_option = 'user_choice';

    $probfile =~ s/\||\.\.//g; # close pipeline exploit; CA 9-17-2004
    open(PROBFILE,$probfile);
    
    while(<PROBFILE>){
	chomp;
	($foo,$qtype) = split(/ /,$_,2) and next if /$qtype_marker/;  #get $qtype and continue
	($preamble .= $_) and ($logstuff .= "$_\n") and next if /\#!preamble/;
	next if /\#/;
	next if /^\s*$/;
	push @questions, $_;                     # Push each line in $probfile onto @questions
    }

    close PROBFILE;

    $cgi->param('qtype',$qtype);
    
    $preamble =~ s/\#!preamble//g;
    $logstuff =~ s/\#!preamble//g;
    my $total_questions = @questions;

### Print out the form ###

    local $subtitle = "Exercise $POL::exercise, Multiple Choice";
    local $instructions = "";

    &start_polpage('Here\'s Your Quiz!');
    &pol_header($subtitle);  # create outer table, print the PoL header and instructions

    print
      "<table border=0>\n",
      "<tr><td align=left>\n",
      $preamble,
      "</td></tr>\n",
      "</table>\n";

    print
	$cgi->startform(),
	"<table border=0>\n";
    
    my $rlqz;
    my ($ques,$answerstuff);
    my $quiz_qnum=0;


    for ($i=1;$i<=$total_questions;$i++) {  
        next if !$cgi->param("prob_$i");
        push (@prev_chosen, $i);
        $rlqz .= "$questions[$i-1]$qsep";               # We use "$questions[$i-1]" cuz arrays are indexed from 0 
        ++$quiz_qnum;
	my ($ques,$answerstuff)=split($sep,$questions[$i-1],2);  # Grab the question and answerstuff
	&display_ques($ques,$answerstuff,$quiz_qnum);
    }    

    print 
	"</table>\n";

    $cgi->param('prev_chosen',@prev_chosen);

    print
      "<hr width=98%>\n",
      "<center>",
      $cgi->hidden('user_option',$user_option),
      $cgi->hidden('qtype',$qtype),
      $cgi->hidden('rlqz',&rot($rlqz)),
      $cgi->hidden('exercise',$exercise),
      $cgi->hidden('total_questions',$total_questions),
      $cgi->hidden('prev_chosen'),
      $cgi->hidden('probnums'),
#      $cgi->hidden(-name=>'prev_chosen',-value=>@prev_chosen,-override=>1),
#      $cgi->hidden('bar',$bar),
      $cgi->hidden('logstuff',$logstuff),
      $cgi->submit(-name=>'action',-value=>'Check answers!'),
      $cgi->end_form;
    
    &pol_footer;                                              # Close the table started by pol_header
    &end_polpage;                                             # Close the table started by start_polpage

}

##########################################################
# subroutine to generate each line of the user choice quiz

sub user_choice_MCV_answer_form {

    my ($ques,$quiz_qnum) = @_;
    my @values = split($sep,$values);
    push(@values,'?');
    
    print 
	"<tr><td align=left valign=top>\n",
	$cgi->popup_menu(-name=>"ans_$quiz_qnum",
			 -values=>\@values,
			 -size=>1,
			 -default=>'?'),
	"</td>\n",
	"<td align=left>\n",
	"$quiz_qnum.&nbsp;&nbsp;$ques</td>\n",
	"</tr>\n";
}


########################################################################
# subroutine to check answers

sub check_answers {
    local ($user_option,$rlqz,$exercise,$total_questions,@probnums) = @_;
    my $qnum=0;
    $rlqz = &rot($POL::rlqz);
    local $nextq;
    local $subtitle = "Evaluation of your answers from Exercise&nbsp;$POL::exercise";
    local $instructions = "";
    local $mailto = 'random';
    local $logstuff = "$POL::logstuff\n\n";
    my @probs_attempted;
    my @student_answers;
    
    &start_polpage('Evaluation of your quiz');

    &pol_header($subtitle,$instructions);

    print
	"<table>\n",  # put it all inside a one-cell table
	startform(),
	"<tr><td align=left>\n",
	h2("The Logic Tutor responds:"), 
	"<dl>\n";

    while ($rlqz) {   # Peel off the questions in $rlqz
	$qnum++;
	my $probnum = shift @probnums;
	($nextq,$rlqz) = split(/$qsep/,$rlqz,2);   
	my ($ques,$answerstuff) = split(/$sep/,$nextq,2);
	my @answerstuff = split(/$asep/,$answerstuff);  # Split up the options/answer/errmsg strings for this ques
	shift @answerstuff;                             # See comment on similar call in &display_ques
	my $num_answertypes = scalar @answerstuff;

	$logstuff .= "$qnum. $ques\n";
	print "<dt>$qnum. $ques</dt>\n<p>\n";

	for ($i=0;$i<$num_answertypes;$i++) {
	    my $ith_answertype = $answerstuff[$i];
	    $ith_answertype =~ s/^*(.*?)($sep.*)/$1/;
	    my $ith_answer = $2;
	    $ith_answer =~ s/^.*$sep(.+?)$sep(.*?)$sep\s*$/$1/;
	    my $ith_errormsg = $2;
	    my $userans = $cgi->param("userans_$qnum.$i");
	    my $raw_ith_answer = $ith_answer;
	    my $raw_userans = $userans;
	    
	    $ith_answer =~ s/[\s\.\-]//g;      # remove spaces, periods, and dashes ...
	    $userans =~ s/[\s\.\-]//g;         
	    $ith_answer =~ tr/A-Z/a-z/;  # ... and change to lower case
	    $userans =~ tr/A-Z/a-z/;     # to facilitate accurate comparison

	    ### clean up negation contractions (CA 2002-07-21)
	    $userans =~ s/won\'t/willnot/g;
	    $userans =~ s/can\'t/cannot/g;
	    $userans =~ s/n\'t/not/g;

	    if ($userans eq $ith_answer) {
		$logstuff .= "Your answer of \'\'$raw_userans\'\' is correct!\n";
		push @probs_attempted, $probnum;
		push @student_answers, 1;

		print
		    "<dd>",
		    "<img src=$greentick>&nbsp;",
		    "<em>Your answer of </em>\'\'$raw_userans\'\'<em> is correct!</em></dd><p>";
		next;
	    }

	    if ($userans =~ /^(\s*|\?)$/) {
		$logstuff .= "You did not answer this question.\n";
		print 
		    "<dd>",
		    "<img src=$qmark>&nbsp;",
		    "<em>You did not answer this question.</em></dd><p>";
		next;
	    }

	    $logstuff .= "Your answer of </em>\'\'$raw_userans\'\'<em> is incorrect.\n";
	    push @probs_attempted, $probnum;
	    push @student_answers, 0;
	    print 
		"<dd>",
		"<img src=$redx>&nbsp;",
		"<em>",
		"Your answer of </em>\'\'$raw_userans\'\'<em> is incorrect.</em> ";
	    if ($ith_answertype eq "TEXT") {
		print
		    "<em>The correct answer is </em>\'\'$raw_ith_answer''",
	    }

	    print
		"<p>";

	    if ($ith_errormsg) {
		$logstuff .= "$errormsg\n";
		print
		    "<font size=-1><em><strong>Explanation</strong>:  $ith_errormsg</em></font><p>";
	    }
	    print
		"</dd></dl>\n";
	}
    }
    print
	"</td></tr>\n",
	"</table>\n";

    local $num_answered=@prev_chosen;
    if ($num_answered >= $total_questions) {
        $num_answered=$total_questions;
        @prev_chosen = ();
        $cgi->delete('prev_chosen');
    };
                                         
#     print "num_answered: $num_answered<br>";
#     print "total_questions: $total_questions<br>";
#     print "prev_chosen2: @prev_chosen<br>";

    print

      "<hr width=98%>\n",
      "<center>",
      "<font size=-1>",
      "You have seen $num_answered out of a total of $POL::total_questions problems in this section.<br>",
      "</font>",
      $cgi->startform,
      $cgi->hidden(-name=>'exercise', -value=>$exercise);

    if (@prev_chosen) {
        print
          $cgi->hidden(-name=>'prev_chosen',-value=>@prev_chosen)
      }

    if ($user_option =~ /random/) {
        print
          $cgi->submit(-name=>'action', -value=>"More problems from Section $exercise?");
    } else {
        print
          $cgi->submit(-name=>'action', -value=>"Choose more problems from Section $exercise?"),
    }
    print
      $cgi->endform,
      "</center>\n";



    &pol_footer;
    &end_polpage;

}

###
sub string_member {
    my ($string,@array) = @_;
    for (@array) {
	s/\s//g;
	return 1 if $string eq $_;
    }
    return 0;
}
	
########################################################################
# subroutine to pick random selection of questions from a problem file ...
# and (with the help of (answer_form) generate an appropriate quiz 

sub generate_full_MCV_quiz {
    local ($probfile,$exercise) = @_;
    my $user_option = 'random';
    local $numqs = 5;

# Determine the number of questions in the quiz file

    $probfile =~ s/\||\.\.//g; # close pipeline exploit; CA 9-17-2004
    open(PROBFILE,$probfile);
    
    while(<PROBFILE>){
	chomp;
	($foo,$qtype) = split(/ /,$_,2) and next if /$qtype_marker/;  #get $qtype and continue
	($preamble .= $_) and ($logstuff .= "$_\n") and next if /\#!preamble/;
	next if /\#/;
	next if /^\s*$/;
	push @questions, $_;
    }

    close PROBFILE;

    $numqs=@questions if @questions<$numqs;
    local $total_questions = @questions;
    my $plural = "s" if $numqs > 1;

    $preamble =~ s/\#!preamble//g;
    $logstuff =~ s/\#!preamble//g;

    my @probnums = &all_question_list;
    push @prev_chosen, @probnums;

### Print out the form ###

    local $subtitle = "Exercise $POL::exercise, Multiple Choice";
    local $instructions = "";

    &start_polpage();
    &pol_header($subtitle,$instructions);  # create outer table, print the PoL header

### Generate the quiz

# DEBUG
#     $num_selected = @probnums;
#     print "num selected: $num_selected<br>";
#     $num_prev_chosen = @prev_chosen;
#    print "num prev chosen: $num_prev_chosen<br>";
#
#     print
#       "selected: @probnums<br>",
#       "prev_chosen: @prev_chosen<br>";
# End DEBUG

    print

	"<table border=0>\n",
	"<tr><td align=left>\n",
	 $preamble,
	"</td></tr>\n",
	"</table>\n";

    print                       # begin the table that will contain the quiz
	$cgi->startform(),
	"<table border=0>\n";    

    my $j=0;
    for(@probnums){
	$j++;
	$rlqz .= "$questions[$_-1]$qsep";  # Can we remove quotes?  (Try later.)
	my ($ques,$answerstuff)=split($sep,$questions[$_-1],2);  # Grab the question and answerstuff
	&display_ques($ques,$answerstuff,$j);
    }

    print 
	"</table>\n";

    $cgi->param('prev_chosen',@prev_chosen);
    $cgi->param('probnums',@probnums);

    print
      "<hr width=98%>\n",
      "<center>",
      $cgi->hidden('user_option',$user_option),
      $cgi->hidden('quiz',$quiz),
      $cgi->hidden('qtype',$qtype),
      $cgi->hidden('rlqz',&rot($rlqz)),
      $cgi->hidden('prev_chosen'),
      $cgi->hidden('logstuff',$logstuff),
      $cgi->hidden('exercise',$exercise),
      $cgi->hidden('total_questions',$total_questions),
      $cgi->hidden('probnums'),
      $cgi->submit(-name=>'action',-value=>'Check answers!'),
      $cgi->end_form;
    
    &pol_footer;                                              # Close the table started by pol_header
    &end_polpage;                                             # Close the table started by start_polpage

}
