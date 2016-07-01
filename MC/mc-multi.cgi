#!/usr/bin/perl
##
## mc_multi.cgi
## By Chris Menzel, based loosely on some earlier code by me and Colin Allen


require '../lib/header.pl';
require '../lib/logit.pl';
require '../MC/mc-common.pl';

$program  = $cgi->url;
$fullprog  = $cgi->self_url;

srand; #seed random
$qsep = "-:-";     # separator b/w questions in $rlqz
$sep = "::";

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
                        $POL::exercise,
                        $POL::total_questions,
                        $POL::valuetype_names,
                        $POL::rlqz,
                        @POL::probnums)
         and &bye_bye) };

    /All/ and do
      { (&generate_full_MCM_quiz($POL::probfile,$POL::exercise) and &bye_bye) };

    /More|Random/ and do
      { (&generate_random_MCM_quiz($POL::probfile,$POL::exercise) and &bye_bye) };

    /Choose|User/ and do
      { (&pick_probs($POL::probfile,$POL::exercise) and &bye_bye) };

    /Generate/ and do
      { (&generate_user_choice_MCM_quiz($POL::probfile,$POL::exercise) and &bye_bye) };

    &choose_quiz_type($POL::probfile,$POL::exercise);
}

&bye_bye;

########################################################################
# subroutine to pick random selection of questions from a problem file ...
# and (with the help of (answer_form) generate an appropriate quiz 

sub generate_random_MCM_quiz {
    my ($probfile,$exercise) = @_;

    local $qtype;
    local $valuetypes;
    local $qtype_marker = "\#!qtype";
    local $preamble_marker = "\#!preamble";
    local $preamble;
    local $logstuff = "";
    local @questions;
    local $numqs = 5;


    # Determine the number of questions in the quiz file

    $probfile =~ s/\||\.\.//g; # close pipeline exploit; CA 9-17-2004
    open(PROBFILE,$probfile);
    
    while(<PROBFILE>){
	chomp;
	($foo,$qtype) = split(/ /,$_,2) and next if /$qtype_marker/;  #get $qtype and continue
	($valuetypes .= $_) and next if /valuetype/;
	($preamble .= $_) and ($logstuff .= "$_\n") and next if /\#!preamble/;
	next if /\#/;
	next if /^\s*$/;
	push @questions, $_;                     # Push each line in $probfile onto @questions
    }

    close PROBFILE;

    $valuetypes =~ s/^\#!valuetype //;
    @valuetypes = split(/\#!valuetype /,$valuetypes);
    $num_valuetypes = scalar(@valuetypes);

    local @valuetype_names = @valuetypes;

    for (@valuetype_names) {            # Extract the value type name for each value type
	s/^(.*?)::.*/$1/;
    }

    my $valuetype_names = join (':',@valuetype_names);

    $cgi->param('qtype',$qtype);
    
    $numqs=@questions if @questions<$numqs;
    local $total_questions = @questions;
    
    $preamble =~ s/\#!preamble//g;
    $logstuff =~ s/\#!preamble//g;

    my @random_probnums = &generate_random_question_list;
    push @prev_chosen, @random_probnums;

### Print out the form ###

    local $subtitle = "Exercise $POL::exercise, Multiple Choice";
    local $instructions = "";

    &start_polpage();
    &pol_header($subtitle,$instructions);  # create outer table, print the PoL header

# DEBUG
#     print
#       "random_probnums: @random_probnums<br>",
#       "prev_chosen: @prev_chosen<br>";

### Generate the quiz

    print
	"<table border=0>\n",
	$cgi->startform(),
	"<tr><td align=left>\n",
	 $preamble,
	"</td></tr>\n",
	"</table>\n";

    print                       # begin the table that will contain the quiz
	"<table border=0>\n";    

    local $j=0;
    local $qnum;
    for(@random_probnums){
	$j++;
	$rlqz .= "$questions[$_-1]$qsep";

	($ques,$ans_error_pairs)=split($sep,$questions[$_-1],2);
	$qnum=$j;                                               

# DEBUG
#	print 
#	    "rlqz: $rlqz<br>",
#	    "ques: $ques<br>",
#	    "ans_error_pairs: $ans_error_pairs<br>";

	&display_ques;
    }

    print 
	"</table>\n";

    $cgi->param('prev_chosen',@prev_chosen);
    $cgi->param('probnums',@random_probnums);
    $cgi->param('user_option','random');

    print
      "<hr width=98%>\n",
      "<center>",
      $cgi->submit(-name=>'action',-value=>'Check answers!'),
      $cgi->hidden('user_option'),
      $cgi->hidden('valuetype_names',$valuetype_names),
      $cgi->hidden('exercise',$POL::exercise),
      $cgi->hidden('total_questions',$total_questions),
      $cgi->hidden('quiz',$quiz),
      $cgi->hidden('qtype',$qtype),
      $cgi->hidden('rlqz',&rot($rlqz)),
      $cgi->hidden('prev_chosen'),
      $cgi->hidden('probnums'),
      $cgi->hidden('logstuff',$logstuff),
      $cgi->end_form;
    
    &pol_footer;                                              # Close the table started by pol_header
    &end_polpage;                                             # Close the table started by start_polpage

}


########################################################
# subroutine to generate each line of the quiz displayed
sub display_ques {

    print 
	"<tr><td colspan=3><hr width=50%></td></tr>"
          unless $qnum == 1;

    print
	"<tr>\n",
	"<td align=left colspan=3>\n",
	"$qnum.&nbsp;&nbsp;$ques</td>\n",
	"</tr>\n",

	"<tr>\n";

    for ($k=0;$k<$num_valuetypes;$k++) {

	@kth_values = split($sep,$valuetypes[$k]);

	if ($num_valuetypes == 1) {
	    print
		"<td align=center>"
	} else {
	    print
		"<td align=left>"
	}

	print 
	    $cgi->popup_menu(-name=>"userans_$qnum.$k",
			     -values=>\@kth_values,  # was \@values[$k],
			     -size=>1,
			     -default=>'?'),
	    "</td>\n",
    }
    print
	"</tr>\n";
}


###################################
### Generate quiz from user choices

sub generate_user_choice_MCM_quiz {

    my ($probfile,$exercise) = @_;
    my $valuetypes;
#    my $subtitle = "Exercise $exercise";
    my $user_option = 'user_choice';

    $probfile =~ s/\||\.\.//g; # close pipeline exploit; CA 9-17-2004
    open(PROBFILE,$probfile);

    while(<PROBFILE>){
	chomp;
	($foo,$qtype) = split(/ /,$_,2) and next if /$qtype_marker/;  #get $qtype and continue
	($valuetypes .= $_) and next if /valuetype/;
	($preamble .= $_) and ($logstuff .= "$_\n") and next if /\#!preamble/;
	next if /\#/;
	next if /^\s*$/;
	push @questions, $_;                     # Push each line in $probfile onto @questions
    }

    close PROBFILE;

    $valuetypes =~ s/^\#!valuetype //;
    @valuetypes = split(/\#!valuetype /,$valuetypes);
    $num_valuetypes = scalar(@valuetypes);

    my @valuetype_names = @valuetypes;

    for (@valuetype_names) {            # Extract the value type name for each value type
	s/^(.*?)::.*/$1/;
    }

    my $valuetype_names = join (':',@valuetype_names);

    $cgi->param('qtype',$qtype);
    $numqs=@questions if @questions<$numqs;
    local $total_questions = @questions;
#    my $plural = "s" if $numqs > 1;
    
    $preamble =~ s/\#!preamble//g;
    $logstuff =~ s/\#!preamble//g;

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
    
    my @probnums;
    my $rlqz;
    local ($ques,$ans_error_pairs);
    local $qnum=0;

    for ($i=1;$i<=$total_questions;$i++) {  
        next if !$cgi->param("prob_$i");
        push (@prev_chosen, $i);
        push @probnums, $i;
        $rlqz .= "$questions[$i-1]$qsep"; # We use "$questions[$i-1]" cuz arrays are indexed from 0
        ++$qnum;
        ($ques,$ans_error_pairs)=split($sep,$questions[$i-1],2); # Grab the question and answerstuff
        &display_ques();
    }

    if (!$rlqz) {
        print
          "<tr><td>",
          "<table align=\"center\" border=\"1\" width=\"90%\">",
          "<tr><td>",
          "<b>You didn\'t pick any problems!</b>  Please go back to the previous page and choose one or more problems from the list.",
          "</td></tr>",
          "</table>",
          "</td></tr>";
    }

    print
      "</table>\n";

    $cgi->param('prev_chosen',@prev_chosen);
    $cgi->param('rlqz',&rot($rlqz));
    $cgi->param('probnums',@probnums);

    print
      "<hr width=98%>\n",
      "<center>",
      $cgi->hidden('user_option',$user_option),
      $cgi->hidden('qtype',$qtype),
      $cgi->hidden('rlqz'),
      $cgi->hidden('probnums'),
      $cgi->hidden('exercise',$exercise),
      $cgi->hidden('total_questions',$total_questions),
      $cgi->hidden('valuetypes',$valuetypes),
      $cgi->hidden('valuetype_names',$valuetype_names),
      $cgi->hidden('prev_chosen'),
      $cgi->hidden('logstuff',$logstuff);

    print
      $cgi->submit(-name=>'action',-value=>'Check answers!'),
        if $rlqz;

    print
      $cgi->end_form;

    &pol_footer;            # Close the table started by pol_header
    &end_polpage;           # Close the table started by start_polpage
}


########################################################################
# subroutine to check answers

sub check_answers {
    my ($user_option,$exercise,$total_questions,$valuetype_names,$rlqz,@probnums) = @_;
    my @valuetype_names = split(/:/,$valuetype_names);
    my $nextq;
    my $subtitle = "Evaluation of your answers from Exercise&nbsp;$POL::exercise";
    my $instructions = "";
    my $mailto = 'random';
    my $logstuff = "$POL::logstuff\n\n";
    
    $rlqz = &rot($rlqz);
    
    &start_polpage('Evaluation of your quiz');

    &pol_header($subtitle,$instructions);

    print
	"<table>\n",  # put it all inside a one-cell table
	startform(),
	"<tr><td align=left>\n",
	h2("The Logic Tutor responds:"), 
	"<dl>\n";

    my $qnum=0;
    my $probnum;
    my @probs_attempted;
    my @student_answers;

    while ($rlqz) {
	$qnum++;
        $probnum = shift @probnums;
	($nextq,$rlqz) = split(/$qsep/,$rlqz,2);
	my ($ques,$ans_errormsg_pairs) = split(/$sep/,$nextq,2);
	$logstuff .= "$qnum. $ques\n";

        print "<dt>$qnum. $ques</dt>\n<p>\n";

# PAGEOUT variables
        my $attempted = 0; # Will == 1 iff at least one element of the problem is attempted
        my $gotit = 1;     # Will == 1 iff *all* elements of the mc-multi problem are answered correctly

	for ($i=0;$i<@valuetype_names;$i++) {
	    my ($ans,$errormsg);
	    ($ans,$errormsg,$ans_errormsg_pairs) = split(/$sep/,$ans_errormsg_pairs,3);
	    my $userans = $cgi->param("userans_$qnum.$i");
	    my $raw_userans = $userans;
	    $ans =~ s/\s//g;      # remove spaces ...
	    $userans =~ s/\s//g;  # to facilitate accurate comparison

	    if ($userans eq $ans) {
		$logstuff .= "Your answer of ``$raw_userans\'\' is correct!\n";
		print
                  "<dd>",
                  "<img src=$greentick>&nbsp;",
                  "<em>Your answer of </em>``$raw_userans\'\'<em> is correct!</em></dd><p>";
                $attempted = 1;
		next;
	    } else {
                $gotit = 0;
            }

# The following condition covers the case where there is only one value type
# but mc-multi rather than mc-fixed format is being used for presentation purposes

	    if (@valuetype_names == 1     
		and &string_member($userans,@valuetype_names)) {
		$logstuff .= "You did not answer this question.\n";
		print 
		    "<dd>",
		    "<img src=$qmark>&nbsp;",
		    "<em>You did not answer this question.</em></dd><p>";
                next;
	    }

	    if (&string_member($userans,@valuetype_names)) {
		$logstuff .= "You did not provide an answer for $raw_userans\n";
		print 
		    "<dd>",
		    "<img src=$qmark>&nbsp;",
		    "<em>You did not provide an answer for</em> $raw_userans.</dd><p>";
		next;
	    }

	    $logstuff .= "Your answer of </em>``$raw_userans\'\'<em> is incorrect.\n";
	    print 
              "<dd>",
		"<img src=$redx>&nbsp;",
                  "<em>Your answer of </em>``$raw_userans\'\'<em> is incorrect.</em></dd><p>";
            $gotit = 0;
            $attempted = 1;
	    if ($errormsg) {
		$logstuff .= "$errormsg\n";
		print
		    "<font size=-1><em><strong>Explanation</strong>:  $errormsg</em></font><p>";
	    }
	}
        if ($attempted) {
            push @probs_attempted, $probnum;
            push @student_answers, $gotit;
        }
    }
    print
	"</dl>\n",
	"</td></tr>\n",
	"</table>\n";

    my $num_answered=@prev_chosen;
    $num_answered=$total_questions
	if $num_answered > $total_questions;

    print
	"<hr width=98%>\n",
	"<center>",
	"<font size=-2>",
	"You have seen $num_answered out of a total of $total_questions problems in this section.<br>",
	"</font>",
	$cgi->startform,
	$cgi->hidden('exercise'),
	$cgi->hidden('user_option',$user_option),
	$cgi->hidden('total_questions'),
	$cgi->hidden(-name=>'prev_chosen',-value=>@prev_chosen);

    if ($user_option =~ /random/) {
        print
          $cgi->submit(-name=>'action',-value=>"More problems from Section $exercise?");
    } else {
        print
          $cgi->submit(-name=>'action',-value=>"Choose more problems from Section $exercise?"),
    }

    print
      $cgi->endform,
      "</center>\n";

# DEBUG
#    print "\$probs_attempted: @probs_attempted<br>";
#    print "\$student_answers: @student_answers<br>";
# END DEBUG

    my %pageoutdata = %pageoutid;
    if (%pageoutdata && @probs_attempted && @student_answers) { # send result to pageout
        $pageoutdata{'vendor_assign_id'} = $exercise;
        $pageoutdata{'assign_probs'} = [ @probs_attempted ];
        $pageoutdata{'student_score'} =[ @student_answers ];
        &send_to_pageout(%pageoutdata);
    }

    &pol_footer;
    &mailit($mailto,$logstuff);
    &end_polpage;

#    &footer();
#    &mailit($mailto,$logstuff);
#    &bye_bye;
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

sub generate_full_MCM_quiz {
    my ($probfile,$exercise) = @_;

    local $qtype;
    local $valuetypes;
    local $qtype_marker = "\#!qtype";
    local $preamble_marker = "\#!preamble";
    local $preamble;
    local $logstuff = "";
    local @questions;
    local $numqs = 5;


    # Determine the number of questions in the quiz file

    $probfile =~ s/\||\.\.//g; # close pipeline exploit; CA 9-17-2004
    open(PROBFILE,$probfile);
    
    while(<PROBFILE>){
	chomp;
	($foo,$qtype) = split(/ /,$_,2) and next if /$qtype_marker/;  #get $qtype and continue
	($valuetypes .= $_) and next if /valuetype/;
	($preamble .= $_) and ($logstuff .= "$_\n") and next if /\#!preamble/;
	next if /\#/;
	next if /^\s*$/;
	push @questions, $_;                     # Push each line in $probfile onto @questions
    }

    close PROBFILE;

    $valuetypes =~ s/^\#!valuetype //;
    @valuetypes = split(/\#!valuetype /,$valuetypes);
    $num_valuetypes = scalar(@valuetypes);

    local @valuetype_names = @valuetypes;

    for (@valuetype_names) {            # Extract the value type name for each value type
	s/^(.*?)::.*/$1/;
    }

    my $valuetype_names = join (':',@valuetype_names);

    $cgi->param('qtype',$qtype);
    
    $numqs=@questions if @questions<$numqs;
    local $total_questions = @questions;
    
    $preamble =~ s/\#!preamble//g;
    $logstuff =~ s/\#!preamble//g;

    my @random_probnums = &all_question_list;
    push @prev_chosen, @random_probnums;

### Print out the form ###

    local $subtitle = "Exercise $POL::exercise, Multiple Choice";
    local $instructions = "";

    &start_polpage();
    &pol_header($subtitle,$instructions);  # create outer table, print the PoL header

# DEBUG
#     print
#       "random_probnums: @random_probnums<br>",
#       "prev_chosen: @prev_chosen<br>";

### Generate the quiz

    print
	"<table border=0>\n",
	$cgi->startform(),
	"<tr><td align=left>\n",
	 $preamble,
	"</td></tr>\n",
	"</table>\n";

    print                       # begin the table that will contain the quiz
	"<table border=0>\n";    

    local $j=0;
    local $qnum;
    for(@random_probnums){
	$j++;
	$rlqz .= "$questions[$_-1]$qsep";

	($ques,$ans_error_pairs)=split($sep,$questions[$_-1],2);
	$qnum=$j;                                               

# DEBUG
#	print 
#	    "rlqz: $rlqz<br>",
#	    "ques: $ques<br>",
#	    "ans_error_pairs: $ans_error_pairs<br>";

	&display_ques;
    }

    print 
	"</table>\n";

    $cgi->param('prev_chosen',@prev_chosen);
    $cgi->param('probnums',@random_probnums);
    $cgi->param('user_option','random');

    print
      "<hr width=98%>\n",
      "<center>",
      $cgi->submit(-name=>'action',-value=>'Check answers!'),
      $cgi->hidden('user_option'),
      $cgi->hidden('valuetype_names',$valuetype_names),
      $cgi->hidden('exercise',$POL::exercise),
      $cgi->hidden('total_questions',$total_questions),
      $cgi->hidden('quiz',$quiz),
      $cgi->hidden('qtype',$qtype),
      $cgi->hidden('rlqz',&rot($rlqz)),
      $cgi->hidden('prev_chosen'),
      $cgi->hidden('probnums'),
      $cgi->hidden('logstuff',$logstuff),
      $cgi->end_form;
    
    &pol_footer;                                              # Close the table started by pol_header
    &end_polpage;                                             # Close the table started by start_polpage

}

