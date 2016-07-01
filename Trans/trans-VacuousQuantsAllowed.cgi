#!/usr/bin/perl
##
## trans.cgi - translation module
## Chris Menzel

use IPC::Open2;
require '../lib/header.pl';
require '../TT/calculate-tv.pl';
require '../lib/wff-subrs.pl';
require '../lib/qlwff-subrs.pl';
require '../Trans/ttree.pl';
require '../Trans/trans-subrs.pl';

$program  = $cgi->url;
$fullprog  = $cgi->self_url;
local %pageoutdata = %pageoutid;

@prev_chosen = @POL::prev_chosen if @POL::prev_chosen;
shift @prev_chosen if (@prev_chosen and !$prev_chosen[0]); # get rid of that damn empty first element

####################################################
# ADD LOCAL MENU ITEMS HERE
# $polmenu{"Main Menu"} = "../menu.cgi";

$polmenu{"Help"} = "../help.cgi?help.html";

my $chapter;

if ($POL::exercise) { # add menu items
    ($chapter,$rest)=split(/\./,$POL::exercise,2);
    if ($POL::action !~ /New/) {
        $prev_chosen_string = '&prev_chosen='.join('&prev_chosen=',@prev_chosen);
        $polmenu{"More from Ex. $POL::exercise"} = "$program?exercise=$POL::exercise&action=New$prev_chosen_string";
    }
    ($chapter)=split(/\./,$POL::exercise);
    $polmenu{"More from Ch. $chapter"} = "../menu.cgi?chapter=$chapter";
}

#####################################################

srand; #seed random
$qsep = "-:-";
$sep = "::";

$debug=0;
# $probfile = $EXHOME."$chapter/$chapter.$exnum";
$probfile = $EXHOME."$chapter/$POL::exercise";

for ($POL::action) {

    /Main/ and do { 
	print $cgi->redirect(-uri=>'../menu.cgi');
	last
    };

    /Return/ and do { 
	print $cgi->redirect(-uri=>"../menu.cgi?chapter=$chapter");
	last
    };

    /Choose|User|Another|New/ and do {
	&pick_trans(); 
	last
    };

    /Random/ and do {
 	&generate_quiz($probfile); 
 	last
     };

    /Problem|Check/ and do {
	&user_choice;
	last
    };

}

&bye_bye;

############################################################
sub choose_quiz_type {
    my $exercise = $POL::exercise;
    my $subtitle = "Exercise $exercise: Symbolization";
    my $instructions = "<strong><font color=$LEFTPAGECOLOR>Choose a quiz type!</font></strong>  \"User choice\" lets you pick which problem from Exercise $exercise to work on.  \"Random\" picks a problem at random from Exercise $exercise.";

    &start_polpage('Choose a quiz type!');  
    &pol_header($subtitle);

    print
	"<table border=0><!--begin instructions table-->\n",    # table for the instructions
	"<tr><td align=left>\n",
	$instructions,
	"</td></tr>\n",
	"</table><!--end instructions table-->\n",              # end of table for instructions
	"<center>",
	"<table border=0 width=\"100%\"><!--begin radio buttons table-->\n",   # table for the radio buttons
	"<tr>\n",
	"<td align=\"center\">\n",
	$cgi->startform(),
	$cgi->radio_group(-name=>'action',
			  -values=>['User choice','Random'],
			  -default=>'User choice',
			  -rows=>2,
			  -columns=>1,
			  -override=>1),
	"</td>\n",
	"</tr>\n",
	"<tr><td align=\"center\">",
	"<hr>",
	$cgi->submit(-value=>'I\'m ready to symbolize!'),
	"</tr></td>",
	"</table><!--end radio buttons table-->\n",           # end of table for radio buttons
	"</center>",
	$cgi->hidden(-name=>'exercise',-value=>$POL::exercise),
	$cgi->endform;

    &pol_footer;                                              # Close the table started by pol_header
    &end_polpage;                                             # Close the table started by start_polpage
}	


############################################################
sub pick_trans {
    my @problems;
    my ($chapter) = split(/\./,$POL::exercise,2);
    my $probfile = "$EXHOME$chapter/$POL::exercise";
    my $exercise = $POL::exercise;
    $exercise =~ s/i//g;
    my $subtitle = "Exercise $exercise: Symbolization";
    my $instructions = "<center><strong><font color=\"$INSTRUCTCOLOR\">Pick a sentence to symbolize!</font></strong></center>";
    my $preamble = "";
    
    $cgi->delete('problem'); # delete any previous selection
    $cgi->delete('problem_num'); # delete any previous selection

    $probfile =~ s/\||\.\.//g; # close pipeline exploit; CA 9-17-2004
    open(FILE,$probfile) || &html_error("Could not open problem file $probfile");
    while (<FILE>) {
	$preamble .= $_ and next if /^\#!preamble/;
	next if /^\s*$|^\#/;
	chomp;
	push @problems, $_;
    }
    close(FILE);
    $preamble =~ s/\#!preamble//g;

    &start_polpage('Pick a sentence');
    &pol_header($subtitle);  # create outer table, print the PoL header and instructions

    print
      "<table border=0>\n",
	"<tr><td align=left>\n",
	$preamble,
	"</td></tr>\n",
	"<tr><td align=left>\n",
	$instructions,
	"</td></tr>\n",
	"</table>\n";

    if (@prev_chosen) {
            print            # Note that $smallgreyPoLogo indicates previous selection
              "<table border=0>\n",
              "<tr><td align=left>\n",
              "<img src=$smallgreyPoLogo> = <font size=-2>previously selected in this session</font>\n",
              "</td></tr>\n",
              "</table>\n";
        }

    # create a table containing all the problems in the exercise
    print
	"<table width=100% border=0>\n";

    my $count=0;
    foreach $problem (@problems) {
	++$count;
	my $sentence = $problem;
	$sentence =~ s/^(.*?\.).*/$1/;             # (([A-Z]*[a-z]*):.*$//;
	print 
	    "<tr>\n",
	    "<td>\n";

        my $logo = $smallPoLogo;
        $logo = $smallgreyPoLogo if (grep {$count == $_} @prev_chosen);

	print  
	    $cgi->startform(),
	    "<td valign=\"middle\" align=\"right\">",
	    $cgi->hidden(-name=>'action', -value=>"Problem",-override=>1),
	    $cgi->image_button(-name=>'void',-src=>$logo),
	    $cgi->hidden(-name=>'exercise',-value=>$POL::exercise),
	    $cgi->hidden(-name=>'problem_num',-value=>$count),
            $cgi->hidden(-name=>'problem',-value=>&rot($problem)),
            $cgi->hidden(-name=>'msg',-value=>"Translate the sentence using the given scheme of abbreviation."),
	    $cgi->hidden(-name=>'prev_chosen',-value=>[ @prev_chosen ], override=>1),"\n",
#            $cgi->hidden(-name=>'user_trans',-value=>"nada"),
	    "</td>",
	    $cgi->endform;
	
	print
	    "<td valign=\"center\" align=\"left\">",
	    "$count.",
	    "</td>",
	    "<td valign=\"center\" align=\"left\">",
	    "$sentence",
	    "</td>\n",
	    "</tr>\n";
    }
    
    print
	"</table>\n";

    &pol_footer;
    &end_polpage;

#    &footer();                       # close the outer table, print the footer message   
#    &bye_bye();
}

########################################################################
# subroutine to generate an input box for symbolizing the user's chosen
# sentence; the routine also does evaluation of the user's symbolization 
# and gives the user 3 chances to get it right before revealing the 
# answer.

sub user_choice {
    local $problem = &rot($POL::problem);
    local $problem_num = $POL::problem_num;
    local $msg = $POL::msg;                      # vble to hold error message if translation is missed
    local $num_attempts = $POL::num_attempts;    # how many attempts at translation so far
    local $print_this = '';
    local $exercise = $POL::exercise;
    local $part = $POL::part;

### prev_chosen maintenance
    push (@prev_chosen, $POL::problem_num) if $POL::problem_num;
    @prev_chosen = &remove_array_dups(@prev_chosen);
    $cgi->param('prev_chosen',@prev_chosen);

    $probfile = shift;
    $section = $probfile;
    $section =~ s/^.*(\d+\.\d+)[A-Z]/$1/;
    $part = $probfile;
    $part =~ s/^.*\d+\.\d+([A-Z])/$1/;

    $qtype_marker = "\#!qtype";
    $preamble_marker = "\#!preamble";

    local ($sentence_scheme,$errmsg,$raw_trans) = split($sep,$problem,3);
    local $sentence = $sentence_scheme;
    $sentence =~ s/^(.*?\.)\s*(.*)$/$1/;
    $scheme = $2;
    $scheme =~ s/[\(\)]//g;
    my $user_trans = $POL::user_trans;
    my $pretty_user_trans = ascii2utf_html($user_trans);
    my $pretty_trans = ascii2utf_html($raw_trans);

    $user_trans =~ s/[\s]//g;
    $raw_trans =~ s/[\s]//g;          # prolly unnecessary...

    my $trans = $raw_trans;

    if ($user_trans) {
	$trans = "($trans)"           # Add outer parens if missing
	    if &wff("($trans)");
	$user_trans = "($user_trans)"
	    if &wff("($user_trans)");
    }

  CASE: {
	if ($msg =~ /^Translate/) {
	    $action = "Check answer!";
	    last CASE
	}

	if ($user_trans =~ /^\s*$/) {
	    $msg = "You did not provide a translation.  Translate the sentence using the scheme of abbreviation provided.";
	    $action = "Check answer!";
	    last CASE 
	}
    
	if (not &wff($user_trans)) {
	    $msg = "Your answer &nbsp;&lsquo;<tt>$pretty_user_trans</tt>&rsquo;&nbsp; <em>is not a wff!</em>";
	    $msg .= "  Remember that you must use CAPITAL letters for statement letters and predicate letters."
		if $user_trans !~ /[A-Z]/;
	    $msg .= "\n<p>";
	    $action = "Check answer!";
	    last CASE
	}

	my $overloaded_pred = '';
	# any wff formed from $trans and $user_trans will do here:
	$overloaded_pred = &overloaded_pred("$trans<->$user_trans"); 
	if ($overloaded_pred) {
	    $msg = "<em>In your symbolization</em> &nbsp;&lsquo;<tt>$pretty_user_trans</tt>&rsquo;&nbsp; <em>you are using the predicate letter</em> &lsquo;<tt>$overloaded_pred</tt>&rsquo; <em>in a way that does not square with the given scheme of abbreviation.  Try again!</em>";
	    $msg .= "\n<p>";
	    $action = "Check answer!";
	    last CASE
	  }

	my $extraORmissing_pred = '';
	$extraORmissing_pred = &extraORmissing_pred($trans,$user_trans);
	if ($extraORmissing_pred) {
	    my $pred = substr($extraORmissing_pred,0,1);
	    if ($extraORmissing_pred =~ /extra/) {
	    $msg = "<em>Your symbolization</em> &nbsp;&lsquo;<tt>$pretty_user_trans</tt>&rsquo;&nbsp; <em>contains the predicate or statement letter</em> &lsquo;<tt>$pred</tt>&rsquo; <em>, which does not occur in the given scheme of abbreviation.</em>";
	    $msg .= "\n<p>";
	    $action = "Check answer!";
	    last CASE
	  } else {  # $extraORmissing_pred =~ /missing/ in this case
	  $msg = "<em>Your symbolization</em> &nbsp;&lsquo;<tt>$pretty_user_trans</tt>&rsquo;&nbsp; <em>is missing the predicate or statement letter</em> &lsquo;<tt>$pred</tt>&rsquo; <em>, which occurs in the given scheme of abbreviation and hence is needed in a good translation.</em>";
	    $msg .= "\n<p>";
	    $action = "Check answer!";
	    last CASE
	  }
	}
	  
	my $extraORmissing_cons = '';
	$extraORmissing_cons = &extraORmissing_cons($trans,$user_trans);
	if ($extraORmissing_cons) {
	  my $cons = substr($extraORmissing_cons,0,1);
	  if ($extraORmissing_cons =~ /extra/) {
	    $msg = "<em>Your symbolization</em> &nbsp;&lsquo;<tt>$pretty_user_trans</tt>&rsquo;&nbsp; <em>contains the individual constant </em> &lsquo;<tt>$cons</tt>&rsquo; <em>, which does not occur in the given scheme of abbreviation.</em>";
	    $msg .= "\n<p>";
	    $action = "Check answer!";
	    last CASE
	  } else {  # $extraORmissing_cons =~ /missing/ in this case
	    $msg = "<em>Your symbolization</em> &nbsp;&lsquo;<tt>$pretty_user_trans</tt>&rsquo;&nbsp; <em>is missing the individual constant</em> &lsquo;<tt>$cons</tt>&rsquo; <em>, which occurs in the given scheme of abbreviation and hence is needed in a good translation.</em>";
	    $msg .= "\n<p>";
	    $action = "Check answer!";
	    last CASE
	  }
	}

	# Check to see if the user's answer matches the canned answer exactly (save
	# perhaps for parens)
	if (&paren_eq($trans,$user_trans)) {
            &do_pageout($POL::exercise,$POL::problem_num,'1');
	    $print_this = "<center><h1>Correct!</h1></center>
<em>Your symbolization</em> &nbsp;&lsquo;<tt>$pretty_user_trans</tt>&rsquo;&nbsp; <em>of the sentence</em><p><center>$sentence</center><p /><em>using the scheme of abbreviation</em><p /><center>$scheme</center><p /><em>is correct.</em>";
	    $action = "Another problem from Exercise $exercise?";
	    last CASE
	  }

	# Some useful debugging vars
	# $USERTRANS = "USERTRANS: $user_trans";
	# $USERTRANS<br>$FOO<br>$PROVER9WFF<br>$PROVER9INPUT<br>$POLwff<br>$EXIT<br>$PROVER9OUTPUT $MACE4OUTPUT

	# check whether user's answer is logically equivalent to the canned answer
	my $result = &log_equiv($trans,$user_trans);

	if ($result == 1) {
            &do_pageout($POL::exercise,$POL::problem_num,'1');
	    $print_this = "<center><h1>Correct!</h1></center>
<em>Your symbolization</em> &nbsp;&lsquo;<tt>$pretty_user_trans</tt>&rsquo;&nbsp; <em>of the sentence</em><p><center>$sentence</center></p> <em>using the scheme of abbreviation</em><p><center>$scheme</center><p><em>is correct!</em>";
	    $action = "Another problem from Exercise $exercise?";
	    last CASE
	}

	if ($result == 2) {
            &do_pageout($POL::exercise,$POL::problem_num,'0');
	    $print_this = "$MACE4OUTPUT<center><h1>Timed out!</h1></center>
<em>For theoretical reasons, we are unable to determine precisely whether your symbolization</em><p><center><tt>$pretty_user_trans</tt></center><p><em>of the sentence</em><p><center>$sentence</center><p><em>is correct. However, it is <em>likely</em> that your answer is incorrect if the Web Tutor did not find it to be correct within a few seconds. It is suggested, therefore, that you try it again and CONTINUE READING ONLY IF YOU WANT TO KNOW THE ANSWER: Anything logically equivalent to </em><p><center><tt>$pretty_trans</tt></center><p><em> (using all and only the vocabulary of the given abbreviation scheme) is considered a correct symbolization</em>.</em>";
	    $action = "Another problem from Exercise $exercise?";
	    last CASE
	}

	# If we're here, Mace4 has found a counterexample that shows that the user's answer is wrong.
	local $num_left = 3 - (++$num_attempts);
	$msg = "";
	if ($num_attempts < 3) {
	    $msg = "<img src=$redx>&nbsp;<em>Your answer of</em> &nbsp;&lsquo;<tt>$pretty_user_trans</tt>&rsquo;&nbsp; <em>is incorrect.  Try again!</em> ";
	    my $tag = "<em>($num_left attempts left!)</em>";
	    $tag = "<em>(1 attempt left!)</em>" if $num_attempts == 2;
	    $msg .= $tag;
	    $action = "Check answer!";
	} else {
            &do_pageout($POL::exercise,$POL::problem_num,'0');
	    $print_this = "<center><h1>The Answer</h1></center><em>
Your symbolization</em> &lsquo;<tt>$pretty_user_trans</tt>&rsquo; <em>of the sentence</em> <p /><center>$sentence</center><p /> <em>using the scheme of abbreviation</em> <p /><center>$scheme</center><p /><em>is not correct.  Anything logically equivalent to </em><p><center><tt>$pretty_trans</tt></center><p><em> (using all and only the vocabulary of the given abbreviation scheme) is considered a correct symbolization.</em>";
	    $action = "Another problem from Exercise $exercise?";
	}
    }  # end CASE


### Print out the form (if new, or correct (or intractable) answer not given on previous submission ###

    local $subtitle = "Exercise $exercise, Problem $problem_num\n";
    local $instructions = "<font color=\"$INSTRUCTCOLOR\">$msg</font>";
    
    &start_polpage();
    &pol_header($subtitle,$instructions); # create outer table, print the PoL header
    
    print
	"<script language=\"javascript\" type=\"text/javascript\" src=\"/4e/javascript/replace.js\" charset=\"UTF-8\"></script>",
	$cgi->startform(-onsubmit=>"replaceCharsRev(document.getElementById('user_trans'))");
	
    print
	"<table width=100% border=0>\n";

    if ($action =~ /Check/) {
	&user_choice_answer_form($problem_num,$sentence_scheme)
    } else {
	print 
	    "<tr><td>\n",
	    $print_this;
    }

    print 
	"</table>\n";

    print
	"<hr width=98%>\n",
	"<center>",
	$cgi->submit(-name=>'action',-value=>$action,-override=>1),
	$cgi->hidden(-name=>'action',-value=>$action,-override=>1),
	$cgi->hidden(-name=>'UserchoiceOrRandom',-value=>$POL::UserchoiceOrRandom),
	$cgi->hidden(-name=>'num_attempts',-value=>$num_attempts,-override=>1),
#	$cgi->hidden('qtype',$qtype),
	$cgi->hidden('section',$section),
	$cgi->hidden('part',$part),
	$cgi->hidden(-name=>'exercise',-value=>$POL::exercise,-override=>1),
	$cgi->hidden(-name=>'problem',-value=>&rot($problem),-override=>1),
	$cgi->hidden(-name=>'problem_num',-value=>$problem_num,-override=>1),
	$cgi->hidden(-name=>'prev_chosen',-value=>[ @prev_chosen ], override=>1),"\n",
	$cgi->end_form;
#	$short_pol_footer;

    &pol_footer;
    &end_polpage;

#    &bye_bye;
}


########################################################
# subroutine to generate each line of the quiz displayed
sub user_choice_answer_form {

    my ($problem_num,$sentence_scheme) = @_;
    print 
#	"<table border=0>",
	"<tr><td align=left>\n",
	"<input onSelect=\"\" onkeyup=\"process(this)\" id=\"user_trans\" name=\"user_trans\" style=\"font-family: monospace\" size=\"40\" default=\"\">",	
	#$cgi->textfield(-name=>"user_trans",
	#		-style=>'font-family: monospace',
	#		-default =>"",
	#		-size=>"40"),
	"</td>\n",
	"<td align=left>&nbsp;&nbsp;",
	"</td>\n",
	"<td align=left>\n",
	"$sentence_scheme</td>\n",
	"</tr>\n";
#	"</table>";
}


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
    local $exercise = $POL::exercise;
    $exercise =~ s/i//g;

    my @prevchosen = @POL::prevchosen;

    $qtype;
    $values;
    $qtype_marker = "\#!qtype";
    $preamble_marker = "\#!preamble";
    $preamble;
    my $numqs = 1;
#    $numqs = 3 if $POL::exercise eq '9.5B';

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


    if (@POL::prevchosen >= @questions) {           # If user has already been quizzed on all 
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
	for (@prevchosen) {         # If there are enough problems in the problem file,
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
    local $subtitle = "Exercise $exercise: Symbolization";
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
	$cgi->hidden('UserchoiceOrRandom',-value=>'Random'),
	$cgi->hidden('quiz',$quiz),
	$cgi->hidden('qtype',$qtype),
	$cgi->hidden('rlqz',&rot($rlqz)),
	$cgi->hidden('prevchosen',@prevchosen),
	$cgi->hidden('section',$section),
	$cgi->hidden('part',$part),
	$cgi->hidden('exercise',$POL::exercise),
	$cgi->end_form;
#	$short_pol_footer;

    &pol_footer;
    &end_polpage;

#    &bye_bye;
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
#	"$qnum.&nbsp;&nbsp;$ques</td>\n",
	"$ques</td>\n",   # Removed $qnum since we're only displaying one problem at a time
	"</tr>\n";
}


# USEFUL DEBUG VARS
# $PROVER9WFF = "PROVER9 WFF: $p9wff";
# $P9INPUT = "P9INPUT: $p9input<br>";  #debug info
# $PROVER9OUTPUT = "PROVER9 OUTPUT: $prover9output<br>"; # debug info
# $MACE4OUTPUT = "MACE4 OUTPUT: $mace4output<br>";  # debug info


sub make_prover9_input {
    my $polwff = shift;
    my $p9wff = &pol2p9($polwff);
    my $p9input = "if(Prover9).\n";
    $p9input .= "assign(max_seconds,3).\nset(auto).\nclear(auto_denials).\n";
    $p9input .= "end_if.\n";
    $p9input .= "if(Mace4).\nassign(max_seconds,2).\nend_if.\n\n";
    $p9input .= "formulas(goals).\n" . $p9wff . ".\nend_of_list.\n";
    return $p9input;
}

sub log_equiv {
  my ($trans,$user_trans) = @_;

  # If we can find a proof of $trans->$user_trans, return 1 if we can also
  # find one for its converse.  If we can't, return 0 if we find a
  # countermodel for the converse and return 2 if we fail to find one.

  if (&provable("$trans->$user_trans")) {
    return 1
      if &provable("$user_trans->$trans");
    return 0
      if &refutable("$user_trans->$trans");
    return 2;
  }

  # If we're here, we were not able to find a proof of
  # $trans->$user_trans. So all we can do is try to refute it or (failing
  # that) its converse.  If we can, return 0; if we can't return 2.

  return 0
    if (&refutable("$trans->$user_trans") or &refutable("$user_trans->$trans"));
  return 2;
}

sub provable {
    my $polwff = shift;
    my $p9input = &make_prover9_input($polwff);

    # Construct a unique filename out of UNIX time and process ID
    my $uniqueID = time;
    $uniqueID .= $$ . '.in';
    open (P9INPUTFILE, ">>/tmp/p9inputfile$uniqueID");
    print P9INPUTFILE $p9input;
    close(P9INPUTFILE);

    my $prover9output = `/usr/local/bin/prover9 -f /tmp/p9inputfile$uniqueID`;
    system('rm', "/tmp/p9inputfile$uniqueID");
    return 1
      # Under some conditions Prover9 finds a proof and then keeps
      # searching for another proof; if it fails, it does not output
      # "THEOREM PROVED"; it only reports, e.g., "Exiting with 1 proof".
      # Added later: Asked about this on P9 forum; McCune advised
      # addition of "clear(auto_denials)" to input preamble.
#      if $prover9output =~ /Exiting with \d* proof/;
      if $prover9output =~ /THEOREM PROVED/;
    return 0;
}

sub refutable {
    my $polwff = shift;
    my $p9input = &make_prover9_input($polwff);
    
    my $uniqueID = time;
    $uniqueID .= $$ . '.in';
    open (P9INPUTFILE, ">>/tmp/p9inputfile$uniqueID");
    print P9INPUTFILE $p9input;
    close(P9INPUTFILE);

    my $mace4output = `/usr/local/bin/mace4 -f /tmp/p9inputfile$uniqueID`;
    system('rm', "/tmp/p9inputfile$uniqueID");
    return 1
      if $mace4output =~ /Exiting with 1 model/;
    return 0;
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

###
sub do_pageout {
    my ($exercise,$probnum,$score) = @_;
#    if (%pageoutdata && $probnum && $score) { # send result to pageout
    if (%pageoutdata && $probnum) { # send result to pageout
        $pageoutdata{'vendor_assign_id'} = $exercise;
        $pageoutdata{'assign_probs'} = [ $probnum ];
        $pageoutdata{'student_score'} =[ $score ];
        &send_to_pageout(%pageoutdata);
    }
}

###
sub html_error { # dirty exit
    my ($err_msg) = @_;

#    &mailit("webmaster\@poweroflogic.com",$err_msg);
    &start_polpage("Error");
    &pol_header("ERROR");
    print
	h2($err_msg),
	$cgi->startform,
	$cgi->submit(-name=>'void',-value=>'Click to continue'),
	$cgi->endform,
	$cgi->Dump;
    &pol_footer;

    &end_polpage;
}


#### NOTHING BELOW IS USED ANYMORE ####

sub log_true {
    my $polwff = shift;
    my $p9input = &make_prover9_input($polwff);
#    $P9INPUT = "P9INPUT: $p9input<br>";  #debug info
    
    my $uniqueID = time;
    $uniqueID .= $$ . '.in';  # Construct a unique filename out of UNIX time and process ID
    open (P9INPUTFILE, ">>/tmp/p9inputfile$uniqueID");
    print P9INPUTFILE $p9input;
    close(P9INPUTFILE);
    my $prover9output = `/usr/local/bin/prover9 -f /tmp/p9inputfile$uniqueID`;
#    $PROVER9OUTPUT = "PROVER9 OUTPUT: $prover9output<br>"; # debug info

    if ($prover9output =~ /THEOREM PROVED/) {
	system('rm', "/tmp/p9inputfile$uniqueID");
	return 1
    }

    my $mace4output = `/usr/local/bin/mace4 -f /tmp/p9inputfile$uniqueID`;
#    $MACE4OUTPUT = "MACE4 OUTPUT: $mace4output<br>";  # debug info
    if ($mace4output =~ /Exiting with 1 model/) {
	system('rm', "/tmp/p9inputfile$uniqueID");
	return 0 
    }

    return 2;
}

###
sub OLD_log_true {
    local $completed_open_branch = 0;
    local $calls = 0;
    my $wff = shift;
    my $insts = "";
    my $cons = $wff;
    $cons =~ s/[^a-u]//g;
    $cons = &remove_string_dups($cons);

    my $foo = &ttree_wrapper(["~".$wff],[$insts],$cons);
    return $foo;
}

sub OLD_log_equiv {
  # If we can't show that $trans->$user_trans is provable check to see if
  # either it or its converse is refutable and, if so, return 0.
  # Otherwise, return 2 ("Timeout").

  if (&provable("$trans->$user_trans") == 2) {
    return 0
      if (&refutable("$trans->$user_trans") or &refutable("$user_trans->$trans"));
    return 2;
  }

  # If we're here, $trans->$user_trans is a theorem.
  # So check to see if its converse is provable.  If it is, return 1.
  # If we can't show it's provable, see if it's refutable and return
  # 0 or 2 accordingly.

  return 1
    if &provable("$user_trans->$trans");
  return &refutable("$user_trans->$trans");
}

sub OLDER_log_equiv {
  my ($trans,$user_trans) = @_;

  my $r2l = &log_true("$user_trans->$trans");
  return $r2l
    if !$r2l;
  $l2r = &log_true("$trans->$user_trans");
  return $l2r
    if !$l2r;
  return 2
    if ($l2r == 2 or $r2l == 2);
  return 1;
}

