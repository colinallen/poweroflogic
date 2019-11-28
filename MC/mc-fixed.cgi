#!/usr/bin/perl
##
## mc_fixed.cgi
## By Chris Menzel, based loosely on some earlier code by me and Colin Allen
## ver 0.1, 15 Sept 98
## Currently still pretty messy...
## ver 0.2  17 June 02

$ENV{PATH} = "/bin:/usr/bin";
delete @ENV{ 'IFS', 'CDPATH', 'ENV', 'BASH_ENV' };

push @INC, cwd;
require '../lib/header.pl';
require '../lib/logit.pl';
require '../lib/wff-subrs.pl';
require '../MC/mc-common.pl';


$program  = $cgi->url;
$fullprog  = $cgi->self_url;

if (!$POL::exercise) {
    &cant_be_done;
}

@questions;
@prev_chosen = ();
push (@prev_chosen, @POL::prev_chosen) if ($POL::prev_chosen[0]); 

# for some reason, length of @prev_chosen = 1 (even though the list
# itself appears empty when printed) if @POL::prev_chosen is empty, so
# can't use (@POL::prev_chosen) as test

####################################################
# ADD LOCAL MENU ITEMS HERE
# $polmenu{"Main Menu"} = "../menu.cgi";

($chapter,$exnum)=split(/\./,$POL::exercise,2);
$polmenu{"More from Ch. $chapter"} = "../menu.cgi?chapter=$chapter"
    if $POL::exercise;
    
    my $subtitle = "Exercise $exercise";


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

srand; #seed random

$debug=1;

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
    /Check/ and do
    { (&check_answers($POL::user_option,$POL::exercise,$POL::total_questions,$POL::rlqz,,@POL::probnums) and &bye_bye) };
    
    /All/ and do
    { (&generate_full_MC_quiz($POL::probfile,$POL::exercise) and &bye_bye) };
    
    /More|Random/ and do
    { (&generate_random_MC_quiz($POL::probfile,$POL::exercise) and &bye_bye) };
    
    /Generate/ and do
    { (&generate_user_choice_MC_quiz($POL::probfile,$POL::exercise) and &bye_bye) };
    
    /Choose|User/ and do
    { (&pick_probs($POL::probfile,$POL::exercise) and &bye_bye) };
    
    &choose_quiz_type($POL::probfile,$POL::exercise);
    
}
    
&bye_bye;

########################################################################
# subroutine to pick random selection of questions from a problem file ...
# and (with the help of (answer_form) generate an appropriate quiz 

sub generate_random_MC_quiz {
    local ($probfile,$exercise) = @_;
    local $user_option = 'random';
    local $numqs = 5;
    local $values;

    # Determine the number of questions in the quiz file
    $probfile =~ s/\||\.\.//g; # close pipeline exploit; CA 9-17-2004
    open(PROBFILE,$probfile);
    
    while(<PROBFILE>){
	chomp;
	($foo,$qtype) = split(/ /,$_,2) and next if /$qtype_marker/;
	($foo,$values) = split(/ /,$_,2) and next if /\#!values/;
	($preamble .= $_) and ($logstuff .= "$_\n") and next if /$preamble_marker/;
	next if /\#/;
	next if $_ =~ /^\s*$/;
	push @questions, $_;                     # Push each line in $probfile onto @questions
    }

    $values =~ s/\s+$//;
    $values =~ s/\s+/ /;

    close PROBFILE;
    $cgi->param('qtype',$qtype);
    
    $numqs=@questions if @questions<$numqs;
    $total_questions = @questions;
    
    $preamble =~ s/$preamble_marker//g;
    $logstuff =~ s/$preamble_marker//g;

### Generate a list of random question numbers and add to @prev_chosen list

    my @random_probnums = &generate_random_question_list;
    push @prev_chosen, @random_probnums;
    
### Print out the form ###

    my $subtitle = "Exercise $POL::exercise: Multiple Choice";
    $subtitle = "Exercise $POL::exercise: True/False" if $values =~ /True::False/;

    #local $instructions = "";
    local $instructions = $preamble;
    
    &start_polpage();
    &pol_header($subtitle,$instructions);  # create outer table, print the PoL header
    print "<script language=\"javascript\" type=\"text/javascript\" src=\"$JSDIR/replace.js\" charset=\"UTF-8\"></script>";



# DEBUG
#     print "\$probfile: $probfile<br>";
#     print "\@selected: @selected<br>";
#     print "\@prev_chosen: @prev_chosen<br>";
# END DEBUG

### Generate the quiz

    print
	$cgi->startform(), 
	;

    print
	"<table border=0>\n";

#    my $random_probnums;
    
    local $j=0;
    for(@random_probnums){
	$j++;
	$rlqz.="$questions[$_-1]$qsep";
	($ques,$err,$ans)=split($sep,$questions[$_-1],3);
	$qnum=$j;
	$rlqz =~ s/ /+/g;
	&random_MC_answer_form($ques);
    }

    print 
	"</table>\n";

    $cgi->param('prev_chosen',@prev_chosen);
    $cgi->param('probnums',@random_probnums);
    print
      "<hr width=98%>\n",
      "<center>",
      $cgi->hidden('user_option',$user_option),
      $cgi->hidden('quiz',$quiz),
      $cgi->hidden('qtype',$qtype),
      $cgi->hidden('rlqz',&rot($rlqz)),
      $cgi->hidden('probnums'),
      $cgi->hidden('logstuff',$logstuff),
      $cgi->hidden('subtitle',$subt),
      $cgi->hidden('exercise',$exercise),
      $cgi->hidden('prev_chosen'),
      $cgi->hidden('total_questions',$total_questions),
      $cgi->submit(-name=>'action',-value=>'Check answers!'),
      $cgi->end_form;
    
    &pol_footer;                                              # Close the table started by pol_header
    &end_polpage;                                             # Close the table started by start_polpage

#    &footer();
#    &bye_bye;
}


########################################################
# subroutine to generate each line of the quiz displayed
# mods by CA on 1/15 to accommodate logical symbols

sub random_MC_answer_form {

    my @values = split($sep,$values);
    push(@values,'?');

    my $uques = $ques; # CA asks: why is $ques global?

    # here we recode ascii version of logical symbols as utf
    if ($uques =~ /^<tt>(.*)<\/tt>$/) {
	my $form = $1;
	$form =~ s/&gt;/>/g;
	$form =~ s/&lt;/</g;
	$uques = "<span style=\"font-size:16px\">".ascii2utf_html($form)."</span";
    } else {
	#$uques = ascii2utf_html($uques);
    }
    
    print 
	"<tr><td style=\"text-align:left; vertical-align: top\">\n",
	$cgi->popup_menu(-name=>"ans_$qnum",
			 -values=>\@values,
			 -size=>1,
			 -default=>'?'),
	"</td>\n",
	"<td align=left>\n",
	"$qnum.&nbsp;&nbsp;",
	$uques,
	"</td>\n",
	"</tr>\n";
}


###################################
### Generate quiz from user choices

sub generate_user_choice_MC_quiz {

    my ($probfile,$exercise) = @_;

    my $user_option = 'user_choice';
    my @probnums;

    $probfile =~ s/\||\.\.//g; # close pipeline exploit; CA 9-17-2004
    open(PROBFILE,$probfile);
    
    while(<PROBFILE>){
	chomp;
	($foo,$qtype) = split(/ /,$_,2) and next if /$qtype_marker/;  #get $qtype and continue
	($foo,$values) = split(/ /,$_,2) and next if /\#!values/;
	($preamble .= $_) and ($logstuff .= "$_\n") and next if /$preamble_marker/;
	next if /^\#/;
	next if /^\s*$/;
	push @questions, $_;                     # Push each line in $probfile onto @questions
    }

    $preamble =~ s/\#!preamble//g;
    $values =~ s/\s+$//;
    $values =~ s/\s+/ /;
    my $total_questions = @questions;

    close PROBFILE;

    for ($i=1;$i<=$total_questions;$i++) {  
        next if !$cgi->param("prob_$i");
        push (@prev_chosen, $i);
        push @probnums, $i;
    }
    
    &pick_probs($probfile,$exercise) if not @probnums;
    $subtitle .= $POL::exercise;

    &start_polpage('Here\'s Your Quiz!');

    &pol_header($subtitle,$preamble);  # create outer table, print the PoL header and instructions

    print
	"<div style=\"clear: both;\"></div>",
	$cgi->startform(),
	"<table border=0>\n";
    
    my $rlqz;
    my ($ques,$err,$ans);
    my $quiz_qnum=0;


# Some debug stuff
#    my $foo1 = @prev_chosen;
#    print "length of \@prev_chosen: $foo1<br>";
#    print "\@prev_chosen: @prev_chosen<br>";
#    print "\@_: @_<br>";

    for $i (@probnums) {  

        # Debug
#        print "\$i: $i<br>";
#        print "\@prev_chosen: @prev_chosen<br>";

        $rlqz .= "$questions[$i-1]$qsep";               # We use "$questions[$i-1]" cuz arrays are indexed from 0 
        ++$quiz_qnum;
 	($ques,$err,$ans)=split($sep,$questions[$i-1],3);
	
	&user_choice_MC_answer_form($ques,$quiz_qnum);
    }

    print 
	"</table>\n";

    $cgi->param('prev_chosen',@prev_chosen);
    $cgi->param('probnums',@probnums);

    print
      "<hr width=98%>\n",
      "<center>",
      $cgi->hidden('user_option',$user_option),
      $cgi->hidden('qtype',$qtype),
      $cgi->hidden('rlqz',&rot($rlqz)),
      $cgi->hidden('probnums'),
      $cgi->hidden('exercise',$exercise),
      $cgi->hidden('total_questions',$total_questions),
      $cgi->hidden('prev_chosen'),
      $cgi->hidden('probfile'),
      $cgi->hidden('logstuff',$logstuff),
      $cgi->submit(-name=>'action',-value=>'Check answers!'),
      $cgi->end_form,
      "</div>", #end of form
      ;
    
    &pol_footer;                                              # Close the table started by pol_header
    &end_polpage;                                             # Close the table started by start_polpage

}

##########################################################
# subroutine to generate each line of the user choice quiz

sub user_choice_MC_answer_form {

    my ($ques,$quiz_qnum) = @_;
    my @values = split($sep,$values);
    push(@values,'?');

    my $uques = $ques; 

    # here we recode  ascii version of logical symbols as utf
    if ($uques =~ /^<tt>(.*)<\/tt>$/) {
	my $form = $1;
	$form =~ s/&gt;/>/g;
	$form =~ s/&lt;/</g;
	$form = &prettify($form);
	$uques = "<span style=\"font-size:16px\">".ascii2utf_html($form)."</span>";
    }

    
    print 
	"<tr><td style=\"text-align:left; vertical-align: top\">\n",
	$cgi->popup_menu(-name=>"ans_$quiz_qnum",
			 -values=>\@values,
			 -size=>1,
			 -default=>'?'),
	"</td>\n",
	"<td align=left>$quiz_qnum.&nbsp;&nbsp;$uques</td>\n",
	"</tr>\n";
}


########################################################################
# subroutine to check answers

sub check_answers {
    local ($user_option,$exercise,$total_questions,$rlqz,@probnums) = @_;
    local $i=0;
    local $nextq;
    my $subtitle = "Evaluation of your answers from Section&nbsp;$exercise";
    local $instructions = "<span style=\"color: $INSTRUCTCOLOR; font-weight: bold\">The Logic Tutor responds...</span>";
    local $logstuff = "$POL::logstuff\n\n";
    local $mailto = 'random';

    $rlqz = &rot($rlqz);
    @prev_chosen = &remove_array_dups(@prev_chosen);
    
### Print out PoL logo and header

    &start_polpage('Evaluation of your quiz');
    print "<script language=\"javascript\" type=\"text/javascript\" src=\"$JSDIR/replace.js\" charset=\"UTF-8\"></script>";

    &pol_header($subtitle,$instructions);

    print
	"<table>\n",  # put it all inside a one-cell table
	"<tr><td align=left>\n",
	"<dl>\n";

    my $probnum;
    my $i;
    my @probs_attempted;
    my @student_answers;
    while ($rlqz) {
	$i++;                                            # question number
        $probnum = shift @probnums;
	($nextq,$rlqz) = split($qsep,$rlqz,2);           # put first ques in $rlqz in $nextq
	my ($ques,$errmsg,$ans) = split($sep,$nextq,3);  # split $nextq into 3 parts
	my $guess = $cgi->param("ans_$i");               # user guess
	$ques =~ s/\+/ /g;                               # replace +'s with spaces in $ques
	# here we recode ascii version of logical symbols as utf
	$uques=$ques;
	if ($uques =~ /^<tt>(.*)<\/tt>$/) {
	    my $form = $1;
	    $form =~ s/&gt;/>/g;
	    $form =~ s/&lt;/</g;
	    $uques = "<span style=\"font-size:16px\">".ascii2utf_html($form)."</span>";
	} else {
	    #$uques =ascii2utf_html($uques);
	}
    

	my $rawguess = $guess;

	$ans =~ s/[+\s]//g;   # Necessary?
	my @ans = split($sep,$ans);
	$guess =~ s/[+\s]//g;
	chomp $guess;

	my $correct = 0;

	for (@ans) {
          $correct = 1 and last if $guess eq $_;
	}
	
	$logstuff .= "$i. $ques\n";

	if ($guess eq "?") {
	    $logstuff .= "You did not answer this question.\n";
	    print "<dd>$i. $uques<dd>&nbsp;";
	    print "<dd><img src=$qmark>&nbsp;<em>You did not answer this question.</em><dd>&nbsp;";
	} elsif ($correct) {
	    $logstuff .= "Your answer of ``$rawguess\'\' is correct!\n";
	    print "<dd>$i. $uques<dd>&nbsp;";
	    print
              "<dd>",
              "<img src=$greentick>&nbsp;",
              "<em>Your answer of </em>&ldquo;$rawguess&rdquo;<em> is correct!</em><dd>&nbsp;",
              ;
            push @probs_attempted, $probnum;
            push @student_answers, "1";
	} else {
	    $errmsg =~ s/\+/ /g;
	    $logstuff .= "Your answer of ``$rawguess\'\' is incorrect!\n";
	    print "<dd>$i. $uques<dd>&nbsp;";
	    print 
              "<dd>",
              "<img src=$redx>&nbsp;",
              "<em>Your answer of </em>&ldquo;$rawguess&rdquo;<em> is incorrect.</em><p>",
              ;
            push @probs_attempted, $probnum;
            push @student_answers, "0";
	    if ($errmsg) {
		$logstuff .= "$errmsg\n";
		print
		    "<font size=-1><em><strong>Explanation</strong>:  $errmsg</em></font><p>";
	    }
	}
    }
    print
	"</dl>\n",
	"</td></tr>\n",
	"</table>\n";

    print
      "<hr width=98%>\n",
      "<center>";

    local $num_answered=@prev_chosen;

    if ($num_answered >= $total_questions) {
        $num_answered=$total_questions;
        undef @prev_chosen;
        $cgi->delete('prev_chosen');
    };
                                         

    print
      "<font size=-1>",
      "You have seen $num_answered out of a total of $total_questions problems in this section.",
      "</font>",
      "<br>",
      $cgi->startform,
      $cgi->hidden(-name=>'prev_chosen',-value=>@prev_chosen),
      $cgi->hidden(-name=>'exercise', -value=>$exercise);

    if ($user_option =~ /random/) {
        print
          $cgi->submit(-name=>'action', -value=>"More problems from Exercise $exercise?");
    } else {
        print
          $cgi->submit(-name=>'action', -value=>"Choose more problems from Exercise $exercise?"),
    }

    print
      $cgi->endform,
      "</center>\n";
    
    &pol_footer;
    &end_polpage;
}


sub generate_full_MC_quiz {
    local ($probfile,$exercise) = @_;
    local $user_option = 'random';
    local $numqs = 5;
    local $values;

    # Determine the number of questions in the quiz file
    $probfile =~ s/\||\.\.//g; # close pipeline exploit; CA 9-17-2004
    open(PROBFILE,$probfile);
    
    while(<PROBFILE>){
	chomp;
	($foo,$qtype) = split(/ /,$_,2) and next if /$qtype_marker/;
	($foo,$values) = split(/ /,$_,2) and next if /\#!values/;
	($preamble .= $_) and ($logstuff .= "$_\n") and next if /$preamble_marker/;
	next if /\#/;
	next if $_ =~ /^\s*$/;
	push @questions, $_;                     # Push each line in $probfile onto @questions
    }

    $values =~ s/\s+$//;
    $values =~ s/\s+/ /;

    close PROBFILE;
    $cgi->param('qtype',$qtype);
    $numqs=@questions 
    ;$numqs=@questions if @questions<$numqs;
    $total_questions = @questions;
    
    $preamble =~ s/$preamble_marker//g;
    $logstuff =~ s/$preamble_marker//g;

### Generate a list of random question numbers and add to @prev_chosen list

    my @random_probnums = &all_question_list;
    push @prev_chosen, @random_probnums;
    
### Print out the form ###

    my $subtitle = "Exercise $POL::exercise: Multiple Choice";
    $subtitle = "Exercise $POL::exercise: True/False" if $values =~ /True::False/;

    #local $instructions = "";
    local $instructions = $preamble;

    &start_polpage();
    print "<script language=\"javascript\" type=\"text/javascript\" src=\"$JSDIR/replace.js\" charset=\"UTF-8\"></script>";

    &pol_header($subtitle,$instructions);  # create outer table, print the PoL header

# DEBUG
#     print "\$probfile: $probfile<br>";
#     print "\@selected: @selected<br>";
#     print "\@prev_chosen: @prev_chosen<br>";
# END DEBUG

### Generate the quiz
    print
	$cgi->startform(), 
	;

    print
	"<table border=0>\n";

#    my $random_probnums;
    
    local $j=0;
    for(@random_probnums){
	$j++;
	$rlqz.="$questions[$_-1]$qsep";
#        $random_probnums .= "$i ";
	($ques,$err,$ans)=split($sep,$questions[$_-1],3);
	$qnum=$j;
	$rlqz =~ s/ /+/g;
	&random_MC_answer_form;
    }

    print 
	"</table>\n";

    $cgi->param('prev_chosen',@prev_chosen);
    $cgi->param('probnums',@random_probnums);
    print
      "<hr width=98%>\n",
      "<center>",
      $cgi->hidden('user_option',$user_option),
      $cgi->hidden('quiz',$quiz),
      $cgi->hidden('qtype',$qtype),
      $cgi->hidden('rlqz',&rot($rlqz)),
      $cgi->hidden('probnums'),
      $cgi->hidden('logstuff',$logstuff),
      $cgi->hidden('subtitle',$subtitle),
      $cgi->hidden('exercise',$exercise),
      $cgi->hidden('prev_chosen'),
      $cgi->hidden('total_questions',$total_questions),
      $cgi->submit(-name=>'action',-value=>'Check answers!'),
      $cgi->end_form;
    
    &pol_footer;                                              # Close the table started by pol_header
    &end_polpage;                                             # Close the table started by start_polpage

#    &footer();
#    &bye_bye;
}


