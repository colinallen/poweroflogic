#!/usr/bin/perl -w
# evaluate-taut.pl
#
# This module contains two main functions: evaluate_taut_tt and
# taut_contra_or_contingent.  The first checks a submitted truth table
# for proper form, and for proper calculation of the truth values in
# the table.  If the truth table passes these tests, it is passed to
# taut_contra_or_contingent, which generates a new page that brings up
# the validated truth table and asks the user to determine whether the
# sentence in question is tautologous, contradictory, or contingent.
# Submitting that page calls check-taut.pl.
#
# This code was cloned from evaluate-tt.pl, so there are things going on that
# don't make a great deal of sense -- e.g., a single wff comes in instead of
# a sequent, nonetheless we construct a @sequent list whose only element is 
# the incoming wff.  This doesn't break the old code, so, for now at least, 
# it seems wiser just to let sleeping dogs lie.


######################################
# Material for standalone testing... #
######################################

#F G | ~(F v G) <-> (~F . ~G)
#----|-----------------------
#T T | F   T     T   F  F F
#T F | F   T     T   F  F T
#F T | F   T     T   T  F F
#F F | T   F     T   T  T T

# Library
#use CGI qw(:standard :html3);
#use IPC::Open2;
#require "../lib/header.pl";
#require "evaluate-taut.pl";
#require "make-tt-template.pl",
#require "check-taut.pl";
#require "extract_nth_subwff.pl";
#require "pol-template.pl";
#require "messages.pl";
#require "../lib/header.pl";
#require "wff-subrs.pl";

#$tt = "F G | ~(F v G) <-> (~F . ~G)\n----|-----------------------\nT T | F   T     T   F  F F       \nT F | F   T     T   F  F T        \nF T | F   T     T   T  F F      \nF F | T   F     T   T  T T        ";

#$atoms = "FG";

#$pretty_wff = "~(F v G) <-> (~F . ~G)";

#$dashes = "----|-----------------------";

#$assigned_tvs = "T T|T F|F T|F F|";

#&evaluate_taut_tt;

###

sub evaluate_taut_tt {

# initialize some global variables

    local $logstuff="";
    local $ith_tva="";
    local $jth_tv="";
    local $shortest_subwff_with_wrong_tv = "";
    local $shortest_tv = "";		# Holds the TV of the shortest subwff w/ wrong TV on a given row
    local $wff="";
    local $subwff="";
    local $current_row=0;
    local $probref = "$POL::exercise "."Problem $POL::problem_num" if $POL::exercise;

# process the input

    local $tt = $POL::tt;
    $tt =~ s/\n\n+/\n/g;  # remove multiple newlines -- necessary?
    local $orig_tt = $tt;
#    $tt =~ s/([TF])\s*\n/$1\n/sg;
    $tt =~ s/([TF])\s*\n/$1\n/g;
    $tt =~ s/\r//g;
    local $att = $tt;
    $logstuff = $tt;

    $tt_rows = $tt;
    $tt_rows =~ s/(.*?\n){2}(.*)/$2/sm;

    local $atoms = $POL::atoms;
    $atoms =~ s/[ \t]//g;

    local $pretty_wff = $POL::pretty_wff;
    local $sequent = $pretty_wff;
    local @sequent = ();

    if ($sequent =~ /^\s*(:\.|\.:)/) {       # case where there are no premises in RYO sequent
	$sequent =~ s/(:\.)|(\.:)//g;
	$sequent =~ s/ //g;
	@sequent = ($sequent);
    } else {                                 # case where there are both premises and conclusion
	$sequent =~ s/(:\.)|(\.:)//g;
	$sequent =~ unprettify($sequent);
	$sequent =~ s/  / /g;
	$sequent =~ s/\s*$//;
	@sequent = split(/ /,$sequent);      # @sequent now just contains the unprettified formulas in the argument
    }

    local $dashes= $POL::dashes;

    local $assigned_tvs = $POL::assigned_tvs;
    $assigned_tvs =~ s/\s//g;
    $assigned_tvs =~ s/([TF])/$1 /g;
    local @assigned_tvs = split(/\|/,$assigned_tvs);

    local $num_atoms = $atoms =~ tr/A-Z/A-Z/;
    local $num_rows = 2**$num_atoms;
    local $num_wffs = scalar(@sequent);
    local @tvas = &get_tvas;
    local @user_tvs = &get_user_tvs;

    &start_polpage;

# DEBUG
#    print 
#      "<pre>",
#	"@assigned_tvs<br>",
#	"atoms: $atoms<br>", 
#	"sequent: $sequent<br>",
#	"sequent array: @sequent<br>",
#	"dashes: $dashes<br>", 
#	"tt_rows: $tt_rows<br>",
#	"tt: $tt<br>",
#	"tvas: @tvas<br>",
#	"user_tvs: @user_tvs<br>",
#        "POL::argument: $POL::argument",
#          "</pre>",
#            ;
# END DEBUG

    &check_form_of_tt;

  FOO:
    for ($i=0;$i<$num_rows;$i++) {
	$shortest_tv = "";
	$current_row = $i+1;
	$ith_tva = $tvas[$i];
	$ith_tva =~ s/(\w)(\w)/$1 $2/g;	# put spaces between atoms and tv's, e.g., "A T B F C T"
	chop $ith_tva;                  # remove the last space
	@ith_tva = split(/ /,$ith_tva);
	local $j = 0;                   # the column we're in; used to extract user tv
	local $seq = $sequent;

	while ($seq) {
	    ($wff,$seq) = split(/ /,$seq,2);
	    chomp($wff);
#	    $wff =~ s/^(.*)$/\($1\)/ if ($wff !~ /^[\(\[].*[\)\]]$/ and $wff =~ /[\.>v]/);  # add parens if missing
#	    print "wff: $wff<br>";
#	    &bye_bye();

	    $num_connectives_in_wff = &count_connectives($wff);
	    my $atomic = !$num_connectives_in_wff;
	    for ($k=1;$k<=$num_connectives_in_wff||$atomic;$k++) {
		$subwff = &extract_nth_subwff($wff,$k);  # &ext... just returns $wff if atomic
		$jth_tv = substr($user_tvs[$i],$j,1);

# The following "if" clause finds shortest subwff with the wrong tv

		if (&calculate_tv($subwff,@ith_tva) ne $jth_tv) {
		    if ((not $shortest_tv) or         
			&count_connectives($subwff) < 
			&count_connectives($shortest_subwff_with_wrong_tv)) {
			$shortest_subwff_with_wrong_tv = $subwff;
			$shortest_tv = $jth_tv; # tv of shortest subwff w/ wrong tv
		    }
		}
		$j++;
		$vbar[$i]{$wff} = $jth_tv if &paren_eq($wff,$subwff);
		$atomic = 0;
	    }
	    last FOO if $shortest_tv;   # stop loop if you've found a bad truth value in row $i 
	                                # (and hence have assigned T or F to $shortest_tv)
	}
    }
    if ($shortest_tv) {
	$shortest_subwff_with_wrong_tv =~ s/ //g;
	if (&paren_eq($shortest_subwff_with_wrong_tv,$wff) || 
	    &paren_eq($shortest_subwff_with_wrong_tv,"($wff)"))
	    {

	    &pol_template($head_IncorrectTV,
			  &msg_IncorrectTV($shortest_tv,&prettify($wff),$current_row),
			  $probref,
#			  '&tt_form($POL::argument)');  # Single quotes are correct here!  Arg is to be eval'd...
#			  '&tt_form($wff)');  # Single quotes are correct here!  Arg is to be eval'd...
			  '&tt_form($POL::original_wff)');  # Single quotes are correct here!  Arg is to be eval'd...

	    $logstuff .= &msg_IncorrectTV($shortest_tv,&prettify($wff),$current_row);
	    &bye_bye("cmenzel",$logstuff);
	} else {
	    $pretty_subwff = &prettify($shortest_subwff_with_wrong_tv);
	    my $pretty_wff = &prettify($wff);

	    &pol_template($head_IncorrectSubwffTV,
			  &msg_IncorrectSubwffTV($shortest_tv,$pretty_subwff,$pretty_wff,$current_row),
			  $probref,
			  '&tt_form($POL::original_wff)');

	    $logstuff .= &msg_IncorrectSubwffTV($shortest_tv,$pretty_subwff,$pretty_wff,$current_row);
	    &bye_bye("cmenzel",$logstuff);
	}
    }

    &taut_contra_or_contingent($tt) unless $POL::exercise eq '7.5B';                        

# Simply confirms the TT is correct for probs in 7.5B (Logical Equivalences)


    local %pageoutdata = %pageoutid;
    &do_pageout($POL::exercise,$POL::problem_num,1);

    &pol_template($head_ItsATautologyAlright,
		  &msg_ItsATautologyAlright($wff),
		  $probref,
		  'display');

    &bye_bye;
}


#############################################################
# $flag is used to indicate that the function is being called
# from check-taut.pl to redisplay the TT after an error msg.
# Hence, when $flag is present, pol_header and the following
# two print blocks will be suppressed.

sub taut_contra_or_contingent {

#    local $tt = &cleanup(pop(@_));  # start with $tt, removing any spaces before newlines
    my ($tt,$flag) = @_;
    $tt=&cleanup($tt);
    $tt =~ s/\n\n+/\n/g;
    local $subtitle = "Exercise $probref\n" if $probref;

    $cgi->param('prev_chosen',@prev_chosen);
    &pol_header($subtitle) if not $flag;                                           # table 1 -- outer table

    print  # Announce the point (more loudly now than $instructions in &pol_header)
	"<center>",
	h2("Tautology, Contradiction, or Contingent Statement?"),
	"</center>"
	    if not $flag;  # Don't print the header if user is past first attempt (error msg prints instead)

    print  # instructions -- looks best if put inside its own table
	"<center>",
	"<table cellpadding=5 border=0 cellspacing=0 width=100%>",               # table 2 -- instructions
	"<tr><td>",
	"Your truth table is correct.  Now, using the truth table, ",
	"determine whether or not the sentence in the truth table is ",
	"a tautology, a contradiction, or a contingent statement, ",
	"and click the relevant button below.",
	"</td></tr>\n",
	"</table>\n",                                                              # end table 2
	"</center>\n"
	    if not $flag;  # Don't print msg if user is past first attempt (error msg prints instead)

    print
	$cgi->startform,
	"\n";
    
    print  # start the truth table (surrounded by table-in-table)
	"<center>\n",
	"<table cellpadding=5 border=3>\n",            # table 3 -- smaller single-cell table for the truth table
	"<tr><td>\n";

    print
	"<pre>\n",
	$tt,
	"</pre>\n";

    print		  
	"</td></tr>\n",                  # close the single cell containing truth table
	"</table>\n";                    # end table 3 -- close the single-cell TT table


    print  # radio buttons for choosing valid or invalid
	"<p>",
	$cgi->submit(-name=>'action',-value=>'Tautology'),"\n",
	$cgi->submit(-name=>'action',-value=>'Contradiction'),"\n",
	$cgi->submit(-name=>'action',-value=>'Contingent'),"\n",
	"</center>\n";
    
    print
	"<center>",
	$cgi->hidden(-name=>'tt',-value=>$tt),"\n",
	$cgi->hidden(-name=>'exercise',-value=>"$POL::exercise"),"\n",
	$cgi->hidden(-name=>'problem_num',-value=>"$POL::problem_num"),"\n",
	$cgi->hidden(-name=>'num_rows',-value=>$num_rows),"\n",
	$cgi->hidden(-name=>'tt_rows',-value=>$tt_rows),"\n",
	$cgi->hidden('prev_chosen'),"\n",
	$cgi->hidden(-name=>'wff',-value=>$wff);
    print
	$cgi->endform;

    &footer();  # end tables 2 and 1

# DEBUG
    print $cgi->Dump if $debug;

    &bye_bye();
}

###
# This subroutine takes the displayed sequent and forms a string 
# that is easier to process in the above routine that calls it

sub make_temp_arg_string {
    local $temp_arg = $pretty_wff;
    $temp_arg =~ s/(^[A-Z])  /$1\^  /;
    $temp_arg =~ s/(^[A-Z]) :\./$1\^ :\./;
    $temp_arg =~ s/  ([A-Z])  /  $1\^  /g;
    $temp_arg =~ s/  ([A-Z]) :\./  $1\^ :\./;
    $temp_arg =~ s/:\. ([A-Z])\s*$/:\. $1\^/;
    $temp_arg =~ s/([^:])(\.)/$1&/g;
    return $temp_arg;
}
	

###
sub cleanup {
    local $tt = $_[0];
    $tt =~ s/\s*\n/\n/g;
    return $tt;
}   

###
# This function checks to see that the user has entered a
# syntactically correct truth table

sub check_form_of_tt {

    local $num_atomic_wffs_in_seq;

    local $user_arg = $orig_tt;
    $user_arg =~ s/^(.*?)--.*/$1/s;
    $user_arg =~ s/^.*\|(.*)/$1/;
    $user_arg =~ s/\s//g;
    local $prob_arg = $pretty_wff;
    $prob_arg =~ s/\s//g;

# xxx

    if ($user_arg ne $prob_arg) {
	&pol_template (
		       $head_CannotFutzWithArg,
		       &msg_CannotFutzWithArg($probref,$pretty_wff,&prettify($user_arg)),
		       $probref,
		       '&tt_form($POL::original_wff)');
	$logstuff .= &msg_CannotFutzWithArg($probref,$pretty_wff,&prettify($user_arg));
	&bye_bye("cmenzel",$logstuff);
    }

    foreach $fla (@sequent) {  
	$num_atomic_wffs_in_seq++ if &atomic($fla);
    }

    local $num_tvs_expected_in_row = &count_connectives($sequent)+$num_atomic_wffs_in_seq;

# Check the rows of the TT to make sure they have the right form

    local @tt_rows = split(/\n/,$tt_rows);
    local $tva;
    $i=1;
    foreach $row (@tt_rows) {
	if ($i>$num_rows) {
	    &pol_template($head_TooManyRows,
			  &msg_TooManyRows($num_rows),
			  $probref,
			  '&tt_form($POL::original_wff)');
	    $logstuff .= &msg_TooManyRows($num_rows);
	    &bye_bye("cmenzel",$logstuff);
	}
	if ($row =~ /[^TF\|\s]/) {
	    &pol_template($head_InvalidChar,
			  &msg_InvalidChar($i),
			  $probref,
			  '&tt_form($POL::original_wff)');
	    $logstuff .= &msg_InvalidChar($i);
	    &bye_bye("cmenzel",$logstuff);
	}
	if ($row !~ /\|/) {
	    &pol_template($head_NoVertBar,
			  &msg_NoVertBar($i),
			  $probref,
			  '&tt_form($POL::original_wff)');
	    $logstuff .= &msg_NoVertBar($i);
	    &bye_bye("cmenzel",$logstuff);
	}
	if ($row =~ /\|.*\|/) {
	    &pol_template($head_TooManyVertBars,
			  &msg_TooManyVertBars($i),
			  $probref,
			  '&tt_form($POL::original_wff)');
	    $logstuff .= &msg_TooManyVertBars($i);
	    &bye_bye("cmenzel",$logstuff);
	}	    
	$tva = $row;
	$tva =~ s/^(.*?)\s*\|.*/$1/;              # extract the TVA in the row
	$tva =~ s/\s//g;
	$tva =~ s/([TF])/$1 /g;
	chop($tva);
	chop($assigned_tvs[$i-1]);
	if ($tva ne $assigned_tvs[$i-1]) {
	    &pol_template($head_MungedTVA,
			  &msg_MungedTVA($i,$assigned_tvs[$i-1],$tva),
			  $probref,
			  '&tt_form($POL::original_wff)');
	    $logstuff .= &msg_MungedTVA($i,$assigned_tvs[$i-1],$tva);
	    &bye_bye("cmenzel",$logstuff);
	}
	$row =~ s/^.*?\|\s*(.*)/$1/;              # strip out the TVA and | in that row
	local $num_tvs_in_row = $row =~ tr/TF/TF/;      # count the number of Ts and Fs
	if ($num_tvs_in_row < $num_tvs_expected_in_row) {

	    &pol_template($head_Incomplete,
			  &msg_Incomplete($i),
			  $probref,
			  '&tt_form($POL::original_wff)');
	    $logstuff .= &msg_Incomplete($i);
	    &bye_bye("cmenzel",$logstuff);
	}
	if ($num_tvs_in_row > $num_tvs_expected_in_row) {
	    &pol_template($head_TooManyTVs,
			  &msg_TooManyTVs($i),
			  $probref,
			  '&tt_form($POL::original_wff)');
	    $logstuff .= &msg_TooManyTVs($i);
	    &bye_bye("cmenzel",$logstuff);
	}
	$i++;
    }
    if ($i<=$num_rows) {
	    &pol_template($head_NotEnoughRows,
			  &msg_NotEnoughRows($i-1,$num_rows),
			  $probref,
			  '&tt_form($POL::original_wff)');
	    $logstuff .= &msg_NotEnoughRows($i-1,$num_rows);
	    &bye_bye("cmenzel",$logstuff);
	}
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

sub atomic {
    return 1 if &count_connectives($_[0]) == 0;
}

###
sub get_atoms {
    local $at = $tt;
    $at =~ s/(.*?)\|.*/$1/s;  # strip off the atoms from the rest of the truth table
    $at =~ s/[ \t]//g;        # remove spaces (and tabs), if any
    return $at;
}

###

sub old_get_atoms {
    local $at = $tt;
    $at =~ s/(.*?) \|.*/$1/s;
    return $at;
}

### This subroutine now appears to be unnecessary

sub get_sequent {
    local $seq = $_[0];
    local $wffs;
    $seq =~ s/^.*?\|\s*(.*?\n)(.|\n)*/$1/;    # extract the sequent
    chomp($seq);

# Check that the conclusion of the argument is a WFF

    $conclusion = $seq;
    $conclusion =~ s/.*:\.\s*(.*)/$1/;
    &pol_template($head_ConclusionNotWff,&msg_ConclusionNotWff) and exit if !&wff($conclusion);
    
    $seq =~ s/:\.//g;                   # remove :.
    while ($seq) {                      # got to find the formulas cuz no delimiters and ...
	local $wff = $seq;              # there are (possibly) spaces b/w binary connectives ...
	until (&wff($wff) or !$wff) {   # as well as the wffs in $seq
	    chop $wff;
	}
	&pol_template($head_PremiseNotWff,&msg_PremiseNotWff) and exit if !$wff;  # Check for WFFness
	$esc_wff = $wff;                   
	$esc_wff =~ s/\(/\\\(/g;          # got to escape the parens in $wff ...
	$esc_wff =~ s/\)/\\\)/g;          # ...
	$esc_wff =~ s/\[/\\\[/g;          # got to escape the parens in $wff ...
	$esc_wff =~ s/\]/\\\]/g;          # ...
	$seq =~ s/$esc_wff//g;            # in order to use it as a sub pattern
	$wff =~ s/ //g;
	if ($seq) {
	    $wffs .= "$wff ";
	} else {
	    $wffs .= "$wff";
	}
    }
    return $wffs;
}

###

sub get_tvas {
    local @tvas = ();
    for ($i=1;$i<=$num_rows;$i++) {
	local $tva;
	local $tvs = $tt;
	local $ats = $atoms;
	$tvs =~ s/.*?\n(.*)/$1/;	           # strip off the sequent
	$tvs =~ s/(.*?\n){$i}(.*?)\|.*/$2/s;       # get the tvs from the ith row (was "s" flag needed?)
	$tvs =~ s/[ \t]//g;                        # remove spaces (and tabs), if any
	while ($ats) {
	    $tva = chop($ats) . chop($tvs) . " " . $tva;
	}
	push @tvas, $tva;
    }
    return @tvas;
}

###

sub get_user_tvs {
    local @user_tvs;
    local $user_tvs = $tt;
    $user_tvs =~ s/.*?\n.*?\n(.*)/$1/;        # strip off the sequent and separator
    $user_tvs =~ s/.*?\|\s*(\w.*?)$/$1/mg;    # strip out tva's (/m allows $ to match at newlines...
                                              # ...; $ is used (rather than \n) in case no \n at end of $tt
    $user_tvs =~ s/[ \t]//g;                  # remove tabs and spaces
    @user_tvs = split(/\n/,$user_tvs);
    
    return @user_tvs;
}	

############################################################
# subroutine for counting the number of connectives in a wff
#
sub count_connectives {
    $_ = $_[0];
    tr/>~\.v/>~\.v/;
}

#####################################################################################
# Subroutine for calulating TV of a sentence on a given truth value assignment
# Taken from Quizmaster code; should put this into a separate module
# Question for later: why does a space get inserted after the conclusion in the
# sequent when TT is submitted from tt.cgi?

sub calculate_tv {
    local %local_tva;
    $_ = $_[0];
#    s/^(.*)$/\($1\)/ if ($_ !~ /^[\(\[].*[\)\]]$/ and /[\.>v]/);  # add parens if missing

    for ($n=1;$n<@_;$n=$n+2) {	         # Reconstruct the tva hash
	$local_tva{$_[$n]} = $_[$n+1];
    }
    s/([A-Z])/$local_tva{$1}/g;	         # substitute the given tv's for sentences letters

    while (/[.~\-v]/) {		         # Calculate til all connectives are gone
	&doitnow($_);
    }
    $_ =~ s/\s//;

    return $_;
}

# the TV calculation engine
sub doitnow {
    $_ = $_[0];
    s/(.*?)~~(.*)/$1$2/g;  
    s/~T/F/g;
    s/~F/T/g;
    s/[\[\(]T\.T[\]\)]/T/g;
    s/[\[\(]T\.F[\]\)]/F/g;
    s/[\[\(]F\.T[\]\)]/F/g;
    s/[\[\(]F\.F[\]\)]/F/g;
    s/[\[\(]TvT[\]\)]/T/g;
    s/[\[\(]TvF[\]\)]/T/g;
    s/[\[\(]FvT[\]\)]/T/g;
    s/[\[\(]FvF[\]\)]/F/g;
    s/[\[\(]T->T[\]\)]/T/g;
    s/[\[\(]T->F[\]\)]/F/g;
    s/[\[\(]F->T[\]\)]/T/g;
    s/[\[\(]F->F[\]\)]/T/g;
    s/[\[\(]T<->T[\]\)]/T/g;
    s/[\[\(]T<->F[\]\)]/F/g;
    s/[\[\(]F<->T[\]\)]/F/g;
    s/[\[\(]F<->F[\]\)]/T/g;

#    s/[\[\(]([TF])[\]\)]/$1/g;
}


###

sub prettify {
    $_[0] =~ s/([\.v]|->|<->|:\.|\.:)/ $1 /g; # Add some spaces b/w binary operators to pretty up $seq
    return $_[0];
}

###
sub unprettify {
    $_[0] =~ s/ ([\.v]|->|<->) /$1/g;
}

###
#sub bye_bye {
#    &footer();
#    print "<hr>",$cgi->Dump if $debug;
#    print end_html;
#    &logit;
#    exit;
#}

1;
