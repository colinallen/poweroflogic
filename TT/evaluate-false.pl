#!/usr/bin/perl
# evaluate-false.pl

require "extract_nth_subwff.pl";
require "pol-template.pl";
require "messages.pl";
require "../lib/wff-subrs.pl";

my $standalone=0;

if ($standalone) {

    ## requires needed for standalone debugging

    require "../lib/header.pl";
    require "make-tt-template.pl";
    require "check-validity.pl";

    &evaluate_false;
}

###

sub evaluate_false {

# Hardcoded object parameters for standalone debugging

    # initialize some global variables

    $debug=1;
    $debug1=1;
    $nomail=1;
    $cgi->param('prev_chosen',@prev_chosen);
    local $print_att="display";
    local $logstuff="";
    local $ith_tva="";
    local $jth_tv="";
    local $wff="";
    local @tvas=();
    local $ith_user_tva;
    local @noninvalidating_user_tvas; # TVAs the user has identified as noninvalidating (by presence of / in row)...
                                      # Will need to be compared with the actual set of noninvalidating TVAs
# process the input

    local $probref = "$POL::exercise "."Problem $POL::problem_num" if $POL::exercise;
    local $att = $POL::att;
    $att =~ s/\s*\n/\n/g;                # remove any unnecessary white space at the end of each row
    $att =~ s/([TF])\s*$/$1\n/s;         # replace all white space at the end of the TT with a single \n
    $att =~ s/\r//g;                     # is this still necessary?
    local $logstuff = $att;

    local $att_rows = $att;
    $att_rows =~ s/(.*?\n){2}(.*)/$2/sm;
    $att_rows =~ s/[ \t]//g;             # remove spaces and tabs
    $att_rows =~ s/\s*$/\n/s;            # put a \n at the end as the only whitespace [Isn't this already done above?]
    local $num_rows = $att_rows =~ tr/\n/\n/;  

    local $atoms = $POL::atoms;
    $atoms =~ s/[ \t]//g;

    local $pretty_arg;
    if ($POL::exercise) {
	$pretty_arg = $POL::pretty_arg;
    } else {
	$pretty_arg = $att;                     # Is this for a roll-yer-own case?
	$pretty_arg =~ s/^.*?\| (.*?)\n.*/$1/s; # extract the argument from tt_template    
	$pretty_arg =~ s/[\t\s]*$//;            # remove any trailing spaces or tabs
	# Might want to make user arg even prettier
    }

    local $argument = $pretty_arg;
    $argument =~ s/,|(:\.)|(\.:)//g;       # remove :. or .:
    $argument =~ unprettify($argument);  # remove any spaces around binary connectives
    $argument =~ s/  +/ /g;              # change double (or more) space to single between wffs
    $argument =~ s/\s*$//;               # remove any trailing whitespace 
                                         # [$argument OF THIS FORM SHOULD ALREADY BE IN POL::argument !!]
    @argument = split(/ /,$argument);    # @argument now just contains the unprettified formulas in the argument
# DEBUG
    print "ARGUMENT: $argument\n"
	if $debug;

    local @premises = @argument;
    local $conclusion = pop(@premises);

    # DEBUG
    if ($debug) {
	print "PREMISES: @premises\n";
	print "CONC: $conclusion\n";
    }

    local $_ = $conclusion;              
    s/[^A-Z]//g;                         # extract the atoms in $conclusion
    while (/(.).*\1/) {                  # remove duplicates
	s/(.)(.*)\1/$1$2/g;
    }
    local $atoms_in_conclusion = $_;
    local $num_atoms_in_conclusion = length($atoms_in_conclusion);
    local $num_atoms = $atoms =~ tr/A-Z/A-Z/;
    local $num_wffs = scalar(@argument);
    local $dashes= $POL::dashes;

# Begin the PoL page

    &start_polpage;
    local @rows = &get_rows;          # the rows of the ATT
    local @user_tvs = &get_user_tvs;  # the truth values the user has entered in all the rows

    &check_att_form;


# Loop for evaluating each row

  FOO: 
    for ($i=0;$i<$num_rows;$i++) {
	local $wff_tv;
	local $ith_tva = "";
	local $row_num = $i+1;
	$ith_user_tva = "";
	local $tvs_in_ith_tva = $rows[$i];
	$tvs_in_ith_tva =~ s/^(.*?)\|.*/$1/;
	$tvs_in_ith_tva =~ s/\s*//g;

	&check_form_of_ATT_row;

### Construct the TVA given in a purportedly invalidating row (so only takes TVs from TVA area)

	my $tmp_atoms = $atoms;
	while ($tmp_atoms) {
	    $ith_tva = chop($tmp_atoms).chop($tvs_in_ith_tva)." $ith_tva";
	}
	$ith_tva =~ s/\s*$//g;  # $ith_tva looks like this:  "AT BF CT"

	local $invalidating = 1;
	local $atomlist;
	local $ith_row_user_tvs = $user_tvs[$i];
	local $temp_ith_row_user_tvs = $ith_row_user_tvs;

# Match up each wff with the string of TVs associated with its atoms and connectives	

	local @argument_with_tvs;
	local $k = 0;

	foreach $wff (@argument) {
	    $num_conns_and_atoms_in_wff = &count_conns_and_atoms($wff);
	    $tvs_assoc_with_wff = substr($ith_row_user_tvs,$k,$num_conns_and_atoms_in_wff);
	    push(@argument_with_tvs,$wff." $tvs_assoc_with_wff");
	    $k += $num_conns_and_atoms_in_wff;
	}
      
######################################################################
### Evaluate each wff with respect to its associated TVs, checking ###
### along the way that premises are assigned T and conclusion F.   ###
######################################################################

	$conclusion_with_tvs = pop(@argument_with_tvs);

## DEBUG
	if ($debug1) {
	    print "conclusion_with_tvs: $conclusion_with_tvs <br>\n";
	}


	&pol_template (
		       $head_TAssignedToConclusion,
		       &msg_TAssignedToConclusion($row_num,$conclusion),
		       $probref,
		       '&att_form($POL::argument,1)'  # Single quotes are correct here!
                                                      # Arg is to be eval'd...);
		       )
          and &bye_bye()
            if &evaluate_wff_with_tvs($conclusion_with_tvs) eq "T";

      }


}

############################################################################
### This function recursively checks to make sure that the truth values  ###
### assigned to the premises and conclusion of an argument, and all of   ###
### their subwffs, have been correctly assigned given the truth values   ###
### assigned to their atomic components.  It does its checking           ###
### "top-down", looking first at the TV assigned to a wff, and then      ###
### checking to see that that TV comports with the TVs assigned to its   ###
### immediate constituents recursively down to the atomic statements.    ###
### (This is necessary because rows that do not produce an invalidating  ###
### assignment do not generate a truth value assignment that can just be ###
### plugged in.)  The function ignores (sub)wffs that have been assigned ###
### /, but it does continue to check their subwffs.  If it finds an      ###
### error, an error message is returned and the program halts;           ###
### otherwise, the function returns 1 and the script continues to its    ###
### next task.                                                           ###
############################################################################

sub evaluate_wff_with_tvs {
    my ($wff_with_tvs) = @_;
    my ($wff,$tvs) = split(/ /,$wff_with_tvs);
    my $wff_tv = &get_tv_for_wff($wff,$tvs);

## DEBUG
    if ($debug) {
	print "WFF: $wff\n";
	print "TVS: $tvs\n";
	print "WFF TV: $wff_tv\n";
    }


# When $wff is an atom, the routine tacks the string "$wff$wff_tv "
# onto the end of $ith_user_tva if it is not a duplicate and it
# doesn't conflict with an earlier assignment to $wff.  $ith_user_tva
# can be compared to the TVA given at the beginning of the row (stored
# in $ith_tva).  If it doesn't match, an error is generated.  If it
# does match, then the row is confirmed as invalidating if the argument
# makes it through this procedure for the entire argument.

  EVAL:
    {
	if (&wff($wff) eq "atomic") {
	    &pol_template (
			   $head_SlashAssignedToAtom,
			   &msg_SlashAassignedtoAtom($wff,$row_num),
			   $probref,
			   '&att_form($POL::argument,1)'
			  )
              and &bye_bye
		    if $wff_tv eq "/";

	    &pol_template (
			   $head_ConflictingAssignments1,
			   &msg_ConflictingAssignments1($wff,$row_num),
			   $probref,
			   '&att_form($POL::argument,1)'
			  )
              &bye_bye()
                if $ith_user_tva =~ /$wff[TF]/
                  and $ith_user_tva !~ /($wff$wff_tv)|($wff\/)/ 
                    and $wff_tv ne '/';

	    &pol_template (
			   $head_ConflictingAssignments2,
			   &msg_ConflictingAssignments2($wff,$wff_tv,$row_num),
			   $probref,
			   '&att_form($POL::argument,1)'
			  )
              and &bye_bye
                if $ith_tva =~ /$wff[TF]/ and $ith_tva !~ /$wff$wff_tv/;

	    $ith_user_tva .= "$wff$wff_tv "   # $ith_user_tva looks like this: "PT QF RF"
		if $ith_user_tva !~ /$wff$wff_tv/ and $wff_tv ne "/";

	    return $wff_tv;
	}
	    
	if (&wff($wff) eq "negation") {
	    my $rhs = $wff;
	    $rhs =~ s/^~(.*)/$1/;
	    local $rhs_tv = &evaluate_wff_with_tvs($rhs." ".substr($tvs,1));

	    &pol_template (
			   $head_BadNegation,
			   &msg_BadNegation($wff,$wff_tv,$rhs,$row_num),
			   $probref,
			   '&att_form($POL::argument,1)'
			  ) 
              and &bye_bye
                if $wff_tv eq $rhs_tv && $wff_tv ne '/';

	    return $wff_tv;
	}

        local $lhs = &lhs($wff);
	local $rhs = &rhs($wff);

## DEBUG
	if ($debug) {
	    print "WFF: $wff\n";
	    print "LHS: $lhs\n";
	    print "RHS: $rhs\n";
	}
##

	local $num_lhs = &count_conns_and_atoms($lhs);

	local $lhs_tv = &evaluate_wff_with_tvs($lhs." ".substr($tvs,0,$num_lhs));
	local $rhs_tv = &evaluate_wff_with_tvs($rhs." ".substr($tvs,$num_lhs+1));

	if (&wff($wff) eq "conjunction") {
	    &pol_template (
			   $head_BadConjunction,
			   &msg_BadConjunction($wff,$wff_tv,$lhs,$rhs,$row_num),
			   $probref,
			   '&att_form($POL::argument,1)'
			  )
              and &bye_bye()
		    if (&conj($lhs_tv,$rhs_tv) ne $wff_tv && $wff_tv ne '/');
	}

	if (&wff($wff) eq "disjunction") {
	    &pol_template (
			   $head_BadDisjunction,
			   &msg_BadDisjunction($wff,$wff_tv,$lhs,$rhs,$row_num),
			   $probref,
			   '&att_form($POL::argument,1)'
			  ) 
              and &bye_bye()
		    if &disj($lhs_tv,$rhs_tv) ne $wff_tv && $wff_tv ne '/';
	}

	if (&wff($wff) eq "conditional") {

	    &pol_template (
			   $head_BadConditional,
			   &msg_BadConditional($wff,$wff_tv,$lhs,$rhs,$row_num),
			   $probref,
			   '&att_form($POL::argument,1)'
			  ) 
              and &bye_bye()
		    if &cond($lhs_tv,$rhs_tv) ne $wff_tv && $wff_tv ne '/';
	}

	if (&wff($wff) eq "biconditional") {
	    &pol_template (
			   $head_BadBiconditional,
			   &msg_BadBiconditional($wff,$wff_tv,$lhs,$rhs,$row_num),
			   $probref,
                           '&att_form($POL::argument,1)'
			  )
              and &bye_bye()
		    if &bicond($lhs_tv,$rhs_tv) ne $wff_tv && $wff_tv ne '/';
	}
    } # end EVAL

# DEBUG    
    print "Truth value $wff_tv assigned to $wff is ok!\n"
	if $debug;

    return $wff_tv;
}

#############################################################################
# This function checks to see that a given row of a user's abb. truth table #
# has the right form in various respects.                                   #
#############################################################################

sub check_form_of_ATT_row {

# Check for invalid characters

    &pol_template (
		   $head_InvalidATTChar,
		   &msg_InvalidATTChar($row_num),
		   $probref,
		   '&att_form($POL::argument,1)'
		  ) 
      and &bye_bye()
	    if $rows[$i] =~ /[^TF\|\/]/; 

# Check that there is a vertical bar

    &pol_template (
		   $head_NoVertBar,
		   &msg_NoVertBar($row_num),
		   $probref,
		   '&att_form($POL::argument,1)'
		  ) 
      and &bye_bye()
	    if $rows[$i] !~ /\|/;

# Check that there isn't more than one vertical bar

    &pol_template (
		   $head_TooManyATTVertBars,
		   &msg_TooManyATTVertBars($row_num),
		   $probref,
		   '&att_form($POL::argument,1)'
		  )
      and &bye_bye()
	    if $rows[$i] =~ /\|.*\|/;

    # Check that there is a TVA if "Valid" pressed

    if ($tvs_in_ith_tva =~ /^\s*$/ && $rows[$i] !~ /\//) {
        &pol_template (
 		   $head_NoTVA_ValidPressed,
 		   &msg_NoTVA_ValidPressed($row_num),
 		   $probref,
 		   '&att_form($POL::argument,1)'
 		  )
          and &bye_bye()
            if $POL::action =~ /^valid/i;

        &pol_template (
                       $head_NoTVA_InvalidPressed,
                       &msg_NoTVA_InvalidPressed($row_num),
                       $probref,
                       '&att_form($POL::argument,1)'
                      )
          and &bye_bye();
    }

# Check that there aren't too many TVs in the TVA area in a row

    &pol_template (
		   $head_TooManyTVsInTVA,
		   &msg_TooManyTVsInTVA($row_num),
		   $probref,
		   '&att_form($POL::argument,1)'
		  )
      and &bye_bye()
        if $tvs_in_ith_tva =~ /[TF]/ and length($tvs_in_ith_tva) > length($atoms);

# Check that there aren't too few TVs in the TVA in a row

    &pol_template (
		   $head_TooFewTVsInTVA,
		   &msg_TooFewTVsInTVA($row_num),
		   $probref,
		   '&att_form($POL::argument,1)'
		  )
      and &bye_bye()
	    if $tvs_in_ith_tva =~ /[TF]/ and length($tvs_in_ith_tva) < length($atoms);

# Check that there is no TVA for rows that do contain a /

    &pol_template (
		   $head_InappropriateTVA,
		   &msg_InappropriateTVA($row_num),
		   $probref,
		   '&att_form($POL::argument,1)'
		  )
      and &bye_bye()
	    if $tvs_in_ith_tva =~ /[TF]/ && $rows[$i] =~ /\//;

# Check that the user TVs in a row don't outnumber the atoms and connectives in the argument

    &pol_template (
		   $head_TooManyTVsInATTRow,
		   &msg_TooManyTVsInATTRow($row_num),
		   $probref
		  )
      and &bye_bye()
	    if &count_conns_and_atoms($argument) < &count_TVs_and_slashes($user_tvs[$i]);

# Check that the user TVs in a row are not outnumbered by the atoms and connectives in the argument

    &pol_template (
		   $head_TooFewTVsInATTRow,
		   &msg_TooFewTVsInATTRow($row_num),
		   $probref,
		   '&att_form($POL::argument,1)'
		  )
      and &bye_bye()
	    if &count_conns_and_atoms($argument) > &count_TVs_and_slashes($user_tvs[$i]);

}

##################################################################
# This subroutine checks various aspects of the ATT's form.

sub check_att_form {

# Look at the first line -- make sure it comports with the original

    local $original_line1 = $POL::att_template;
    $original_line1 =~ s/^(.*?)\n.*/$1/s;       # extract the first line from the original template
    $orig_line1_sans_whitespace = $original_line1;
    $orig_line1_sans_whitespace =~ s/\s//g;
    local $user_line1 = $att;
    $user_line1 =~ s/^(.*?)\n.*/$1/s;           # extract the first line from the user's ATT
    $user_line1_sans_whitespace = $user_line1;
    $user_line1_sans_whitespace =~ s/\s//g;

    &pol_template (
		   $head_CannotFutzWithATTArg,
		   &msg_CannotFutzWithATTArg($original_line1,$user_line1),
		   $probref
		  )
	and &bye_bye()
	    if $orig_line1_sans_whitespace ne $user_line1_sans_whitespace;
    
# Look at the second line -- make sure the dashes are all there

    local $first_2_lines_of_ATT_problem = $POL::att_template;
    $first_2_lines_of_ATT_problem =~ s/^(.*?\n)(-*?\|-*)\n.*$/$1$2/s;
    local $user_line2 = $att;
    $user_line2 =~ s/^.*?\n\s*(.*?)\n.*/$1/s;       # extract the second line from the user's ATT
    $first_2_user_lines = $att;
    $first_2_user_lines =~ s/^(.*?\n)(.*?)\n.*/$1$2/s;

    &pol_template (
		   $head_CannotFutzWithATTDashes,
		   &msg_CannotFutzWithATTDashes($first_2_lines_of_ATT_problem,$first_2_user_lines),
		   $probref,
		   '&att_form($POL::argument,1)'
		  )
      and &bye_bye()
        if $user_line2 !~ /^--*\|--*$/;
    
# Look at the rest of the ATT -- make sure there's something there; if not, make sure $conclusion isn't valid

    pol_template (
		  $head_ValidConclusion,
		  &msg_ValidConclusion($conclusion),
		  $probref,
		   '&att_form($POL::argument,1)'
		  )
      and &bye_bye()
        if $att_rows =~ /^\s*?\|*\s*$/ and &tautology($conclusion);

# Bomb (assuming $conclusion is not valid) if user has not entered anything into the ATT

    pol_template (
		  $head_EmptyATT,
		  &msg_EmptyATT,
		  $probref,
		   '&att_form($POL::argument,1)'
		  )
      and &bye_bye()
        if $att_rows =~ /^\s*?\|*\s*$/;


# Check for duplicate rows.  (Aside from being aesthetically
# unpleasing, duplicate rows (if allowed) could fool the algorithm
# here into thinking that an ATT that had not shown validity HAD
# in fact shown it...)

    if ($num_rows > 1) {
        for ($i=1;$i<=$num_rows;$i++) {
            for ($j=$i+1;$j<=$num_rows;$j++) {
                pol_template (
                              $head_DuplicateRows,
                              &msg_DuplicateRows($i,$j),
                              $probref,
                              '&att_form($POL::argument,1)'
                             ) 
                  and &bye_bye()
                    if $user_tvs[$i-1] eq $user_tvs[$j-1];
            }
        }
    }

}


#######################################################################
### This subroutine checks to see that slashes occur only (at most) ###
### under the main connective of a premise or (in the rare case     ###
### where it is a tautology) the conclusion.  $conclusion_flag      ###
### indicates whether we are checking the conclusion -- we want to  ###
### alter the error message accordingly in that case if a bad slash ###
### shows up.                                                       ###
#######################################################################

sub check_for_slashes_not_under_main_connective {
    my ($wff_with_tvs,$conclusion_flag) = @_;
    my $wff = $wff_with_tvs;
    $wff =~ s/^(.*) .*$/$1/;
    my $tvs = $wff_with_tvs;
    $tvs =~ s/^.*? (.*)$/$1/;
    $wff_type = &wff($wff);

    my $lhs = "";
    $lhs = &lhs($wff) if $wff_type ne 'negation';
    my $num_lhs = &count_conns_and_atoms($lhs);
    my $lhs_tvs = substr($tvs,0,$num_lhs);
    my $rhs_tvs = substr($tvs,$num_lhs+1);

    return 1 if ($lhs_tvs.$rhs_tvs) !~ /\//;  # return 1 if there are no bad slashes

    my $wff_argtype = "premise";
    $wff_argtype = "conclusion" if $conclusion_flag;
    my $subwff;
    if ($wff =~ /^~(.*)$/) {
	$subwff = $1;
    } else {
	my $subwff = &rhs($wff);
	$subwff = $lhs if $lhs_tvs =~ /\//;
    }

    &pol_template (
		   $head_BadSlash,
		   &msg_BadSlash($row_num,$subwff,$wff_argtype,$wff),
		   $probref,
		   '&att_form($POL::argument,1)'
		  );
    &bye_bye;
}

###
sub count_conns_and_atoms {
    my ($wff) = @_;
    my $num;
    $num = $wff =~ tr/A-Z~.v\-/A-Z~.v\-/;
    return $num;
}

###
sub count_TVs_and_slashes {
    my ($user_tvs) = @_;
    my $num;
    $num = $user_tvs =~ tr/TF\//TF\//;
    return $num;
}

###
sub conj {
    local ($arg1,$arg2) = @_;
    return "T" if $arg1.$arg2 eq "TT";
    return "F";
}

###
sub disj {
    local ($arg1,$arg2) = @_;
    return "F" if $arg1.$arg2 eq "FF";
    return "T";
}

###
sub cond {
    local ($arg1,$arg2) = @_;
    return "F" if $arg1.$arg2 eq "TF";
    return "T";
}

###
sub bicond {
    local ($arg1,$arg2) = @_;
    return "T" if $arg1 eq $arg2;
    return "F";
}

###
sub get_tv_for_wff {
    local ($wff,$tvs) = @_;
    return $tvs if $wff =~ /^[A-Z]$/;
    return substr($tvs,0,1) if &wff($wff) =~ /neg/;
    return substr($tvs,&count_conns_and_atoms(&lhs($wff)),1);
}

###

sub get_atoms_and_connectives {
    local ($seq) = @_;
    local @seq;
    $seq =~ s/[()\[\]]//g;
    $seq =~ s/<->/<=>/g;
    $seq =~ s/(\.|v|->|<=>)/ $1 /g;
    $seq =~ s/~/~ /g;
    $seq =~ s/<=>/<->/g;
    @seq = split(/ /,$seq);
    return @seq;
}

###
# This subroutine takes the displayed argument and forms a string 
# that is easier to process in the above routine that calls it

sub make_temp_arg_string {
    local $temp_arg = $pretty_arg;
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
    local $at = $att;
    $at =~ s/(.*?)\|.*/$1/s;  # strip off the atoms from the rest of the truth table
    $at =~ s/[ \t]//g;        # remove spaces (and tabs), if any
    return $at;
}

###

sub old_get_atoms {
    local $at = $att;
    $at =~ s/(.*?) \|.*/$1/s;
    return $at;
}

#############################################################################
### This subroutine constructs all the possible TVAs for sentence letters ###
### in the argument.  The rows that are *not* invalidating and on which   ###
### the conclusion is false will then be extracted & checked against the  ###
### noninvalidating rows that the user has found to make sure that she    ###
### has identified all such rows before declaring the argument valid.     ###
#############################################################################

sub get_tvas {
    my @tvas = ();
    local $tt_template = &make_tt_template($argument);
    local $num_rows_in_tt_template = 2**length($atoms);
    
    $tt_template =~ s/.*?\n(.*)/$1/;	           # strip off the argument

    for ($i=1;$i<=$num_rows_in_tt_template;$i++) {
	local $tva = "";
	local $tvs = $tt_template;
	local $ats = $atoms;
	$tvs =~ s/(.*?\n){$i}(.*?)\|.*/$2/s;       # get the tvs from the ith row (was "s" flag needed?)
	$tvs =~ s/[ \t]//g;                        # remove spaces (and tabs), if any
	while ($ats) {
	    $tva = chop($ats) . chop($tvs) . " " . $tva;  # $tva looks like this: "PT QF RF"
	}
	push @tvas, $tva;
    }
    return @tvas;
}

###

sub get_user_tvs {
    local @user_tvs;
    local $user_tvs = $att;
    $user_tvs =~ s/.*?\n.*?\n(.*)/$1/;          # strip off the argument and separator
    $user_tvs =~ s/.*?\|\s*([\/TF].*?)$/$1/mg;  # strip out tva's (/m allows $ to match at newlines...
                                                # ...; $ is used (rather than \n) in case no \n at end of $att
    $user_tvs =~ s/[ \t]//g;                    # remove tabs and spaces
    @user_tvs = split(/\n/,$user_tvs);
    
    return @user_tvs;
}	

#################################################################
### Subroutine to return the rows beneath the arg and dashes. ###
### Will be used to reconstruct any TVAs given in each row.   ###
### There should be at most one TVA given (for the first      ###
### invalidating row the user finds).                         ###
#################################################################

sub get_rows {
    local @rows;
    local $rows = $att;
    $rows =~ s/.*?\n.*?\n(.*)/$1/;        # strip off the argument and separator
    $rows =~ s/[ \t\r]//g;                # remove tabs and spaces and CR's (so only newlines left)
    @rows = split(/\n/,$rows);
    
    return @rows;
}	

###
sub count_connectives {
    $_ = $_[0];
    tr/>~\.v/>~\.v/;
}

###############################################################################
### Subroutine for calculating whether a wff is valid.  Needed to check     ###
### in those cases where the conclusion is valid and the user has submitted ###
### a blank ATT.  Got to count this as a correct answer (in fact, the best  ###
### answer), since it contains no unneeded rows).                           ###
###############################################################################

sub tautology {
    my ($wff) = @_;
    my @tvas = &get_tvas;

    for (@tvas) {
	s/\s*$//;                        # (I think I already did this)
	my $tva = $_;                    # $_ looks like this: "PF QT RT SF"

	s/(\w)(\w)/$1 $2/g;	         # put spaces between atoms and tv's, e.g., "P F Q T R T S F"
	%tva = split(/ /,$_);            # Need to pass a hash %tva to &calculate_tv
	return 0 if &calculate_tv($wff,%tva) eq "F";
    }
    return 1;
}


#####################################################################################
### Subroutine for calulating TV of a sentence on a given truth value assignment  ###
### Taken from Quizmaster code; should put this into a separate module            ###
### Question for later: why does a space get inserted after the conclusion in the ###
### argument when TT is submitted from tt.cgi?                                    ### 
#####################################################################################

sub calculate_tv {
    local %local_tva;
    $_ = shift;
    $_ = "($_)" if !&iswff($_);

    for ($n=0;$n<@_;$n=$n+2) {	         # Reconstruct the tva hash
	$local_tva{$_[$n]} = $_[$n+1];
    }
    s/([A-Z])/$local_tva{$1}/g;	         # substitute the given tv's for sentences letters

    while (/[.~\-v]/) {		         # Calculate til all connectives are gone
	&doitnow($_);
    }
    $_ =~ s/\s//;

# DEBUG
    print "TV: $_\n" if $debug;

    return $_;
}

# the TV calculation engine
sub doitnow {
    $_ = $_[0];
#    open(LOG,">>/tmp/polfoo");
#    print LOG "reducing $_\n";
#    close LOG;
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
}


1;
