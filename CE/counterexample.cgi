#!/usr/bin/perl
# counterexample.cgi

$mailto='random';

require "../lib/header.pl";
require "./the-world.pl";

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

if (!$POL::exercise) {
    $POL::exercise = '1.2';
    $cgi->param('exercise', $POL::exercise);
}

my ($chapter,$foo) = split(/\./,$POL::exercise,2);

$probfile = "$EXHOME$chapter/$POL::exercise";

$polmenu{"More from Ch. $chapter"} = "../menu.cgi?chapter=$chapter";
$polmenu{"Main Menu"} = "../menu.cgi";

$polmenu{"More from Ex. $POL::exercise"} =
    "counterexample.cgi?exercise=$POL::exercise&prevchosenstring=$prevchosen_string&msfu=".rand;

if ($POL::action =~ /Random/) {
    @probnums = &random_pickprobs($probfile,1); # ask for one problem
    $probnum  = $probnums[0];                   # get it!
    $POL::probnum = $probnum+1;
    $POL::argument = $questions[$probnum];
} elsif (!$POL::argument) {
    if (!$POL::action or $POL::action =~ /Another/) {
	&choose_quiz_type;
    } else {
	&pick_prob;
    }
}

&check_work if ($POL::t11); # we are checking
&counterexample_workspace($POL::argument);


################  BEGIN SUBROUTINES *****************

sub check_work() {
    ($prem1,$prem2,$concl,$argstruc) = &get_argstruc($POL::argument);
    $newarg =  "$q1 $POL::t11 are $n1 $POL::t12. ";
    $newarg .= "$q2 $POL::t21 are $n2 $POL::t22. ";
    $newarg .= ":. $qc $POL::t31 are $nc $POL::t32. ";
    ($newprem1,$newprem2,$newconcl,$newstruc) = &get_argstruc($newarg);

    my $output;

    &start_polpage();    
    &pol_header("Exercise $POL::exercise",
		$cgi->strong("Evaluation of your attempted counterexample:"));

    $newarg =~ s/--choose replacement--/\[<u>missing term<\/u>\]/g;
    print
	"<p>",
	$cgi->center("<em>$newarg</em>"),
	;
    
    if ($newarg =~ /missing term/) {
	$output =
	    "<p>\n
	    <font color=maroon><strong>
	    You did not make all the required selections -
            please try again
	    </strong></font>\n
	    <br>&nbsp;\n";
	print $output;
	&mailit($mailto,$output) if $mailto;
	$score = 0;
    } elsif ($newstruc ne $argstruc) {
	print
	    "<p>",
	    "This argument does not have the same form as the original:",
	    "<p>",
	    $cgi->center("<em>$POL::argument</em>",
			 "<p>",
			 "<font color=maroon>",
			 $cgi->strong("You must substitute terms uniformly throughout.",
				      "Please try again."),
			 "</font>",
			 "<p>"),
	    ;
	&mailit($mailto,$output) if $mailto;
	$score = 0;
    } else {
	$score=1;
	$output =
	    "<p>Your first premise <em>\"$newprem1\"</em> is not true.<br>"
		and $score=0
		    if !&istrue($newprem1);
	$output .=
	    "<p>Your second premise <em>\"$newprem2\"</em> is not true.<br>"
		and $score=0
		    if !&istrue($newprem2);
	$output .=
	    "<p>Your conclusion <em>\"$newconcl\"</em> is true.<br>"
		and $score=0
		    if &istrue($newconcl);
	if (!$score) {
	    $output .= "<p>\n<font color=maroon>".
		$cgi->strong("Remember that a counterexample must have ",
			     "true premises and a false conclusion.\n",
			     "Please try again.").
				 "</font>".
				     "<p>\n";
	}
	print $output;
	&mailit($mailto,$output) if $mailto;
    }

    if ($score) {
	print
	    "<p>",
	    "Original argument: $POL::argument<p>",
	    $cgi->center("<font color=maroon>",
			 $cgi->strong("Congratulations - Your counterexample is correct!"),
			 "<p>\n",
			 $cgi->startform(),
			 $cgi->hidden('prevchosen'),
			 $cgi->hidden('exercise'),
			 $cgi->radio_group(-name=>'action',
					   -values=>['Random','User choice'],
					   -default=>'Random',
					   -rows=>2,
					   -columns=>1,
					   -override=>1),
			 $cgi->submit(-name=>'action',
				      -value=>'Another?')),
	    ;
    } else {
	print &ce_constructor_form(&get_argstruc($POL::argument));
    }

    &pol_footer;
    &end_polpage;

}

sub istrue{
    my ($claim) = @_;
    $claim =~ s/\s//g;
    foreach $fact (@the_world) {
	$fact =~ s/\s//g; #eliminate whitespace to be safe
	return 1 if $claim eq $fact;
    }
    return 0;
}

###########
sub counterexample_workspace {
    my ($prem1,$prem2,$concl,$argstruc) = &get_argstruc($POL::argument);

    &error_out("The argument \"$POL::argument\" is not in standard form.")
	if $argstruc == -1;

    &start_polpage();
    $preamble = &get_preamble($probfile);
    &pol_header("Exercise $POL::exercise,  Problem ". $POL::probnum,
		"$preamble");
    print &ce_constructor_form($prem1,$prem2,$concl,$argstruc);
    &pol_footer;
    &end_polpage;
}

sub ce_constructor_form {
    my ($prem1,$prem2,$concl,$argstruc) = @_;
    my $form;
    $form .= "<center>";
    $form .= $cgi->startform();
    $form .= "<table cellpadding=1 cellspacing=1 border=0 align=\"center\">";
    $form .= "<!-- Start Counter example builder table -->\n";

    $form .= Tr(th({-colspan=>4,
		    -align=>'center',
		    -bgcolor=>$LEFTPAGECOLOR},
		   "<font color=white>Premises</font>"));
    $form .= &substituter($prem1,1);
    $form .= &substituter($prem2,2);
    $form .= Tr(th({-colspan=>4,
		    -align=>'center',
		    -bgcolor=>$LEFTPAGECOLOR},
		   "<font color=white>Conclusion</font>"));
    
    $form .= &substituter($concl,3);
    $form .= $cgi->hidden('argument',$POL::argument);
    $form .= $cgi->hidden('probnum',$POL::probnum);
    $form .= $cgi->hidden('prevchosen');
    $form .= $cgi->hidden('exercise');
    $form .= Tr(td({-align=>'center', -colspan=>4},
		   $cgi->submit(-name=>'action',
				-value=>'Click here to check counterexample')));
    $form .= "</table><!--End CE Builder Table-->\n";
    $form .= $cgi->endform();
    $form .= "</center>";
    
    return $form;
}

sub substituter {
    my ($sentence,$sentnum) = @_;
    my ($qntfr,$term1,$negat,$term2) = &get_parts($sentence);
    my $popup1 = &selector($term1,$sentnum,1);
    my $popup2 = &selector($term2,$sentnum,2);
    my $verb = 'are';
    $verb = 'are&nbsp;not' if $negat;
    return Tr({-bgcolor=>$RIGHTPAGECOLOR},
	      td({-valign=>middle, -align=>center},
		 ["<font size=+2>$qntfr</font>",
		  $popup1,
		  "<font size=+2>$verb</font>",
		  $popup2]));
}

sub selector {
    my ($term,$snum,$tnum) = @_;
    my $result;
    $result .= "<select name=t$snum$tnum>\n";
    foreach $type (@types) {
	if (${"POL::t$snum$tnum"} eq $type) {
	   $result .= "<option selected>$type\n";
       } else {
	   $result .= "<option>$type\n";
       }
    }
    if (!${"POL::t$snum$tnum"} or ${"POL::t$snum$tnum"} =~ /choose/) {
        # undefined
        $result .= "<option selected>--choose replacement--\n";
    } else {
	$result .= "<option>--choose replacement--\n";
    }
    $result .= "</select>\n";
    $result .= "<br><strong>$term</strong>\n";
    return $result;
}

sub get_parts {
    my ($sentence) = @_;
    $sentence =~ /(\w*)\s+(.*)\s+are\s+(not\s+)?(.*)$/;
    return $1,$2,$3,$4;
}

sub get_argstruc {
    my($arg)=@_;
    $arg =~ s/\.:|:\.//;
    $arg =~ /^(.+)\.\s+(.+)\.\s+(.+)\./;
    
    my $p1 = $1;
    my $p2 = $2;
    my $c = $3;
    
    ($q1,$p1t1,$n1,$p1t2)=&get_parts($p1);
    ($q2,$p2t1,$n2,$p2t2)=&get_parts($p2);
    ($qc,$ct1,$nc,$ct2)=&get_parts($c);
    
    return $p1,$p2,$c,&get_pattern("$p1t1,$p1t2,$p2t1,$p2t2,$ct1,$ct2,");
}

sub get_pattern {
    my ($sentence) = @_;
    my $varcount=1;

    my $result = $sentence;
    $result =~ s/\s//g;
    while ($result =~ /[\D]/) {
	$result =~ /[\d,]*([-\w]+),/;
	my $next = $1;
	$result =~ s/$next,/$varcount/g;
	++$varcount;
	return -1 if $varcount > 6; # not in standard form which has 6 terms only
    }
    $result =~ s/\,//g;
    return $result;
}

#################
sub random_pickprobs {
    my ($probfile,$numqs) = @_;
    
    # Determine the number of questions in the quiz file
    $probfile =~ s/\||\.\.//g; # close pipeline exploit; CA 9-17-2004
    open(PROBFILE,$probfile);
    while(<PROBFILE>){
	chop;
	next if /^\#/;
	next if /^\s*$/;
	push @questions, $_;   # Push each line in $probfile onto @questions
    }
    close PROBFILE;

    ### The following chunk of code generates a random list of quiz questions w/o duplicates
    ### It also checks that no previously chosen questions show up in later rounds

    if (@POL::prevchosen >= @questions) {           # If user has already been quizzed on all 
	$cgi->delete('prevchosen');              # of the questions, make prevchosen nil;
    }
    @prevchosen = $cgi->param('prevchosen');   # find out what nums have already been used

    my @selected;  # Variable to store random indices for selecting quiz questions
    my $i=0;

  QUIZNUMS: while ($i<$numqs) {
      my $candidate=int(rand @questions)+1; #  a human numbered probnum
      next QUIZNUMS if grep /^$candidate$/, @selected; # seen this before

      if (@questions<=@selected+@prevchosen) {   # Check that we've got enough problems in the 
	  push @selected, $candidate;            # problem file to avoid repeats from previous 
	                                         # rounds, and if not,
	  $i++;                                  # just tack $j onto @selected directly ...
	  next QUIZNUMS;                         # and find the next number to put in @selected
      }
      for (@prevchosen) {         # If there are enough problems in the problem file,
	  if ($candidate==$_) {   # check to see if $j is equal to one of the nums in @prevchosen.
	      next QUIZNUMS;      # If so, try another number...
	  }
      }
      push @selected, $candidate;   # If not, then $j isn't a repeat, so tack it onto @selected ...
      $i++;                         # and increment $i.
  }
    push @prevchosen, @selected;
    
    $cgi->param('prevchosen',@prevchosen);
    return @selected;
}

sub member {
    my $item = shift;
    my $list = @_;
    for (@list) {
	return 1 if $item eq $_;
    }
    return 0;
}

sub error_out {
    my ($message) = @_;

    &start_polpage();
    &pol_header("Program Error!");
    print
	h3($message),
	"<center><font color=maroon><strong>",
	"Webmaster has been notified.",
	"</strong><font color=maroon></center>",
	;
    &pol_footer;
    &mailit($mailto,$message);
    &end_polpage;
}

sub get_preamble {
    my ($probfile) = @_;
    $probfile =~ s/\||\.\.//g; # close pipeline exploit; CA 9-17-2004
    open (FILE,$probfile);
    while (<FILE>) {
	next unless /^#!preamble/;
	s/^#!preamble//;
	$result .= $_;
    }
    return $result;
}

############################################################
sub choose_quiz_type {
    my $exercise = $POL::exercise;
    my $subtitle = "Exercise $exercise: Counterexamples";
    my $instructions = "<strong><font color=$INSTRUCTCOLOR>Choose a quiz type!</font></strong>  \"User choice\" lets you pick which problem from Exercise $exercise to work on.  \"Random\" selects one problem at random from Exercise $exercise.";

    &start_polpage('Choose a quiz type!');  
    &pol_header($subtitle,$instructions);

    print
	#"<table border=0><!--begin instructions table-->\n",    # table for the instructions
	#"<tr><td align=left>\n",
	#$instructions,
	#"</td></tr>\n",
	#"</table><!--end instructions table-->\n",              # end of table for instructions
	"<center>",
	"<table border=0 width=\"100%\"><!--begin radio buttons table-->\n",   # table for the radio buttons
	"<tr>\n",
	"<td align=\"center\">\n",
	$cgi->startform(),
	$cgi->radio_group(-name=>'action',
			  -values=>['Random','User choice'],
			  -default=>'Random',
			  -rows=>2,
			  -columns=>1,
			  -override=>1),
	"</td>\n",
	"</tr>\n",
	"<tr><td align=\"center\">",
	"<hr>",
	$cgi->submit(-value=>'Invalidity Detector Ready!'),
	"</tr></td>",
	"</table><!--end radio buttons table-->\n",           # end of table for radio buttons
	"</center>",
	$cgi->hidden(-name=>'exercise',-value=>$POL::exercise),
	$cgi->hidden('prevchosen'),
	$cgi->endform;

    &pol_footer; 
    &end_polpage;
}	


############################################################
sub pick_prob {
    my @problems;
    my ($chapter) = split(/\./,$POL::exercise,2);
    my $probfile = "$EXHOME$chapter/$POL::exercise";
    my $exercise = $POL::exercise;
    $exercise =~ s/i//g;
    my $subtitle = "Exercise $exercise: Counterexamples";
    my $preamble = "";
    
    $cgi->delete('problem'); # delete any previous selection
    $cgi->delete('problem_num'); # delete problem number for any previous selection

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

    &start_polpage('Pick argument');
    &pol_header($subtitle);  # create outer table, print the PoL header and instructions

    print
	table({-border=>0},
	      Tr(td({-align=>'left',-colspan=>2},
		    "<font color=$LEFTPAGECOLOR>",
		    strong("Pick an argument"),
		    "</font>",
		 ))),
	$PREVCHOICEINSTRUCTION,
	;


    print    # create a table containing all the problems in the exercise
	"<table width=\"100%\" border=0>\n";

    my $count=0;
    foreach $problem (@problems) {
	++$count;
	my $button_image = $prevchosen{$count} ? $smallgreyPoLogo : $smallPoLogo;
	print
	    "<tr>",
	    $cgi->startform,
	    "\n<td width=5% valign=\"top\" align=\"left\" bgcolor=\"white\">\n",
	    $cgi->hidden(-name=>'argument',-value=>$problem),
	    $cgi->hidden(-name=>'exercise',-value=>$POL::exercise),
	    $cgi->hidden(-name=>'prevchosen'),
	    $cgi->hidden(-name=>'probnum',-value=>$count),
	    $cgi->image_button(-name=>'usrchc',-src=>$button_image),
	    "\n</td>",
	    $cgi->endform,

	    
	    "\n<td width=5% valign=\"middle\" align=\"left\" bgcolor=$RIGHTPAGECOLOR>\n",
	    "\n<font size=-1>\n",
	    strong("#$count"),
	    "</font>",
	    "\n</td>",

	    "\n<td valign=\"middle\" align=\"left\">\n",
	    "\n<font size=-1>\n",
	    $problem,
	    "</font>\n</td>",
	    "</tr>",
	    ;
    }
    print "\n</table><!-- end selection table -->";

    &pol_footer;
    &end_polpage;

#    &footer();                       # close the outer table, print the footer message   
#    &bye_bye();
}

