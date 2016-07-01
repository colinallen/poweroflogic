#! /usr/bin/perl -w
# mc-common.pl
# Common code for generating multiple choice quizzes for various MC exercise types
# Menzel created the file on 4 Jun 02; who know who wrote what at this point...

############################################################
# Common global MC variables

$qsep = "-:-";
$sep = "::";
$qtype;
$values;
$qtype_marker = "\#!qtype";
$preamble_marker = "\#!preamble";
$topic_marker = "\#!topic";
$preamble;


############################################################
sub choose_quiz_type {
#    my ($exercise,$topic) = @_;
    my ($probfile,$exercise) = @_;
    my $subtitle = "Exercise $exercise";
    my $instructions = "<strong><font color=\"$LEFTPAGECOLOR\">Choose a quiz type!</font></strong>  \"User choice\" lets you pick which problem from Exercise $exercise to work on.  \"Random\" selects several problems at random for you from Exercise $exercise.";
    my @prev_chosen;

    &start_polpage('Choose a quiz type!');  
    &pol_header($subtitle);

    print
	#"<table border=0><!--begin instructions table-->\n", # table for the instructions
	#"<tr><td align=left>\n",
	$instructions,
	#"</td></tr>\n",
	#"</table><!--end instructions table-->\n", # end of table for instructions

	$cgi->startform(),
	"<center>",
	$cgi->radio_group(-name=>'action',
			  -values=>['Random','User choice'],
			  -default=>'Random',
			  -rows=>2,
			  -columns=>1,
			  -override=>1),
	"<hr />",
	$cgi->submit(-value=>'Show me the Problems!'),
	"</center>",
	
	$cgi->hidden(-name=>'probfile',-value=>$probfile),
	$cgi->hidden(-name=>'exercise',-value=>$exercise),
	$cgi->hidden('prev_chosen',@prev_chosen),
	$cgi->endform;
    
    &pol_footer; 
    &end_polpage;
}	



############################################################
sub pick_probs {

    my ($probfile,$exercise) = @_;
    my $user_option = 'user_choice';
    my ($chapter) = split(/\./,$exercise,2);
    my $ex = $exercise;
    $ex =~ s/i//g;
    my $subtitle = "";
    my $instructions = "Choose the sentences you\'d like to be quizzed on and click on the button below, or on one of the small images to the left of the problems, to generate your quiz!";
    my $instructions3 = "\<img src=$smallgreyPoLogo\> = previously selected during this session.";
    
    my @problems;

    $probfile =~ s/\||\.\.//g; # close pipeline exploit; CA 9-17-2004
    open(FILE,$probfile) || die "Could not open problem file $probfile\n";
    while (<FILE>) {
	next if /^\s*$|^\#/;
	chomp;
	push @problems, $_;
    }
    close(FILE);

    @prev_chosen = sort { $a <=> $b } &remove_array_dups(@prev_chosen);

    if (@prev_chosen >= @problems) {
        $instructions2 = "You have attempted all of the problems in this exercise -- but feel free to keep going!";
        $cgi->delete('prev_chosen');
        @prev_chosen = ();
    }

    $cgi->delete('problem'); # delete any previous selection
    $cgi->delete('problem_num'); # delete problem number for any previous selection

#    my $subtitle = "Exercise $ex: $topic";
    $subtitle = "Exercise $ex";

    &start_polpage('Pick argument');
    &pol_header($subtitle);  # create outer table, print the PoL header and instructions

    print
      "<table border=0>\n",
      "<tr><td align=left>\n",
      "<strong><font color=$LEFTPAGECOLOR>",
      $instructions,
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

    my @temp = @prev_chosen;
    foreach $problem (@problems) {
        $problem =~ s/^(.*?)::.*/$1/;
        my $logo = ($count == $temp[0] and shift(@temp)) ? $smallgreyPoLogo : $smallPoLogo;

        print # Image button
          "\n<tr>\n",
          "<td width=5% valign=\"center\" align=\"right\" bgcolor=\"white\">\n",
          $cgi->image_button(-name=>'Click to generate quiz!',
			     -value=>'Generate my quiz!',-src=>$logo,
			     -style=>"border: 1px dotted gray;"),"\n",
          "</td>\n";
        
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

    $cgi->param('prev_chosen',@prev_chosen);
    print
      "\n</table><!-- end selection table -->",
      "\n<p>\n",
      "<hr>\n",
      "<center>",
      $cgi->hidden(-name=>'user_option',-value=>$user_option),
      $cgi->hidden(-name=>'exercise',-value=>$exercise),
      $cgi->hidden('prev_chosen'),
      $cgi->submit(-name=>'action',-value=>'Generate my quiz!'),
      "</center>",
      $cgi->endform;
    
    &pol_footer;
    &end_polpage;

#    &footer();                       # close the outer table, print the footer message   
#    &bye_bye();
}


############################################################

### The following chunk of code generates a random list of quiz questions w/o duplicates
### It also checks that no previously chosen questions show up in later rounds

sub generate_random_question_list {

    if (@prev_chosen >= @questions) {           # If user has already been quizzed on all 
	$cgi->delete('prev_chosen');            # of the questions, make prev_chosen nil;
    }

    my $j;
    my @selected;  # Variable to store random indices for selecting quiz questions
    $i=0;
    QUIZNUMS: while ($i<$numqs) {         
	                                  
	$j=int(rand @questions);
        $j++;
        $cgi->param('foo',$j);
	for ($n=0;$n<$i;$n++) {           
	    if ($j==$selected[$n]) {
		next QUIZNUMS;
	    }
	}
	if (@questions<=@selected+@prev_chosen) {  # Check that we've got enough problems in the 
	    push @selected, $j;              # problem file to avoid repeats from previous
                                                   # rounds, and if not,
	    $i++;                                  # just tack $j onto @selected directly ...
	    next QUIZNUMS;                         # and find the next number to put in @selected
	}
	for (@prev_chosen) {        # If there are enough problems in the problem file,
	    if ($j==$_) {           # check to see if $j is equal to one of the nums in @prev_chosen.
		next QUIZNUMS;      # If so, try another number...
	    }
	}
	push @selected, $j;   # If not, then $j isn't a repeat, so tack it onto @selected ...
	$i++;                       # and increment $i.
    }
    return @selected;
}

1;
