#! /usr/bin/perl -w
# quiz-generator.pl
# General code for generating multiple choice quizzes for various exercise types
# Menzel created the file on 4 Jun 02; who knows who wrote what at this point...

############################################################
sub choose_quiz_type {
#    my ($exercise,$topic) = @_;
    my ($exercise) = @_;
    my $subtitle = "Exercise $exercise";
    my $instructions = "<strong><font color=$LEFTPAGECOLOR>Choose a quiz type!</font></strong>  \"User choice\" lets you pick which problem from Exercise $exercise to work on.  \"Random\" selects several problems at random for you from Exercise $exercise.";
    my @prev_chosen;

    &start_polpage('Choose a quiz type!');  
    &pol_header($subtitle,$instructions);

    print
	"<table border=0><!--begin instructions table-->\n",    # table for the instructions
	"<tr><td align=left>\n",
	#$instructions,
	"</td></tr>\n",
	"</table><!--end instructions table-->\n",              # end of table for instructions
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
	$cgi->submit(-value=>'Show me the Problems!'),
	"</tr></td>",
	"</table><!--end radio buttons table-->\n",           # end of table for radio buttons
	"</center>",
	$cgi->hidden(-name=>'exercise',-value=>$exercise),
      $cgi->hidden('prev_chosen',@prev_chosen),
	$cgi->endform;

    &pol_footer; 
    &end_polpage;
}	



############################################################
sub pick_probs {

    my $exercise = shift @_;
    my @prev_chosen = @_ if (@_);
#   my ($exercise,@prev_chosen) = @_;
    my $user_option = 'user_choice';
    my ($chapter) = split(/\./,$exercise,2);
    my $probfile = "$EXHOME$chapter/$exercise";
    my $ex = $exercise;
    $ex =~ s/i//g;
    my $subtitle = "";
    my $instructions = "Choose the items you\'d like to be quizzed on and click on the button below, or on one of the small images to the left of the problems, to generate your quiz!";
    my $instructions3 = "\<img src=$smallgreyPoLogo\> = previously selected during this session.";
    
    my @problems;

    open(FILE,$probfile) || &html_error("Could not open problem file $probfile");
    while (<FILE>) {
	next if /^\s*$|^\#/;
	chomp;
	push @problems, $_;
    }
    close(FILE);

    @prev_chosen = sort { $a <=> $b } &remove_array_dups(@prev_chosen);

    if (@prev_chosen == @problems) {
        $instructions2 = "You have attempted all of the problems in this exercise -- but feel free to keep going!";
        $cgi->delete('prev_chosen');
        @prev_chosen = ();
    }

#         } else {
#             @chosen_so_far = sort { $a <=> $b } @prev_chosen;
#             $chosen_so_far = join(', ', @chosen_so_far);
#             $instructions2 = "Problems attempted in this session: $chosen_so_far.";
#         }
#    }
    
    $cgi->delete('problem'); # delete any previous selection
    $cgi->delete('problem_num'); # delete problem number for any previous selection

#    my $subtitle = "Exercise $ex: $topic";
    $subtitle = "Exercise $ex";

    &start_polpage('Pick argument');
    &pol_header($subtitle,$instructions);  # create outer table, print the PoL header and instructions

    print
      "<table border=0>\n",
      "<tr><td align=left>\n",
      "<strong><font color=$LEFTPAGECOLOR>",
      #$instructions,
      "</font></strong>",
      "</td></tr>";

    if ($instructions2) {
        print
          "<tr><td>\n",
          "<table border=1 align=center width=80%>",
          "<tr valign=center><td valign=center align=center bgcolor=$RIGHTPAGECOLOR>",
          "<font size=\"-1\">\n",
          "&nbsp;<br><i>\n",
          "$instructions2\n",
          "</i>\n",
          "</font>\n",
          "</td></tr>",
          "</table>",
          "</td></tr>\n\n";
    }

    if (@prev_chosen) {
        print
          "<tr><td valign=center>\n",
          "<font size=-2>$instructions3</font></p>\n",
          "</td></tr>\n";
    }
        
    print
      "</table>\n";

    print                                   # create a table containing all the problems in the exercise
      $cgi->startform,
      $cgi->hidden(-name=>'action',-value=>'Generate my quiz!',-override=>1),
      "<table width=\"100%\" border=0>\n";
    my $count=1;
    my $probnum=1;

    my @temp_prev_chosen = @prev_chosen;
    foreach $problem (@problems) {
        my $yes = "";
        $yes = shift(@temp_prev_chosen) if ($count == $temp_prev_chosen[0]);
        my $attempted = "";
#        my $attempted = "Already\<br\>Attempted" if $yes;
#        my $attempted = "<img src=$check4>" if $yes;
        $problem =~ s/^(.*?)::.*/$1/;

        if ($yes) {

            print # Grey image button, for previously selected problems
          
              "\n<tr>\n",
              "<td width=5% valign=\"center\" align=\"left\" bgcolor=\"white\">\n",
              $cgi->image_button(-name=>'Click to generate quiz!',-value=>'Generate my quiz!',-src=>$smallgreyPoLogo),"\n",
              "</td>\n";
        } else {
            print # Noral image button, for previously unselected problems
          
              "\n<tr>\n",
              "<td width=5% valign=\"center\" align=\"left\" bgcolor=\"white\">\n",
              $cgi->image_button(-name=>'Click to generate quiz!',-value=>'Generate my quiz!',-src=>$smallPoLogo),"\n",
              "</td>\n";
        }

        print
          
          # Problem number
          "\n<td width=5% valign=\"center\" align=\"left\" bgcolor=$RIGHTPAGECOLOR>\n",
          "<font size=-1>\n",
          strong("#$probnum"),"\n",
          "</font>\n",
          "</td>\n",

          # The checkbox
          "\n<td width=5% valign=center align=left>\n",
          "<font size=-1>\n",
          "<input type=checkbox name=prob_$count value=$count>\n",
          "</font>\n",
          "</td>\n",

#           # Note the problem has been attempted, if it has
#           "\n<td valign=center align=center>\n",
#           "<font size=-2>",
#           $attempted,
#           "</font>\n",
#           "</td>\n",

          # The problem
          "\n<td valign=center align=left>\n",
          "<font size=-1>\n",
          $problem,"\n",
          "</font>\n",
          "</td>\n",
          "</tr>\n",
          ;

	++$count;
        ++$probnum;
    }
    print
      "\n</table><!-- end selection table -->",
      "\n<p>\n",
      "<hr>\n",
      "<center>",
      $cgi->hidden(-name=>'user_option',-value=>$user_option),
      $cgi->hidden(-name=>'exercise',-value=>$exercise),
      $cgi->hidden(-name=>'prev_chosen',-value=>@prev_chosen),
      $cgi->submit(-name=>'action',-value=>'Generate my quiz!'),
      "</center>",
      $cgi->endform;
    
    &pol_footer;
    &end_polpage;

#    &footer();                       # close the outer table, print the footer message   
#    &bye_bye();
}

### The following chunk of code generates a random list of quiz questions w/o duplicates
### It also checks that no previously chosen questions show up in later rounds

sub generate_random_question_list {

    if (@prev_chosen >= @questions) {           # If user has already been quizzed on all 
	$cgi->delete('prev_chosen');            # of the questions, make prev_chosen nil;
    }

#    @prev_chosen = $cgi->param('prev_chosen');   # find out what nums have already been used

    my $j;
    @selected;  # Variable to store random indices for selecting quiz questions
    $i=0;
    QUIZNUMS: while ($i<$numqs) {         
	                                  
	$j=int(rand @questions);          
	for ($n=0;$n<$i;$n++) {           
	    if ($j==$selected[$n]) {
		next QUIZNUMS;
	    }
	}
	if (@questions<=@selected+@prev_chosen) {   # Check that we've got enough problems in the 
	    @selected=(@selected,$j);              # problem file to avoid repeats from previous 
                                                   # rounds, and if not,
	    $i++;                                  # just tack $j onto @selected directly ...
	    next QUIZNUMS;                         # and find the next number to put in @selected
	}
	for (@prev_chosen) {        # If there are enough problems in the problem file,
	    if ($j==$_) {           # check to see if $j is equal to one of the nums in @prev_chosen.
		next QUIZNUMS;      # If so, try another number...
	    }
	}
	@selected=(@selected,$j);   # If not, then $j isn't a repeat, so tack it onto @selected ...
	$i++;                       # and increment $i.
    }
    return @selected;
}

1;
