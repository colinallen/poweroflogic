#!/usr/bin/perl
# grader-check-att.pl -- Standalone Abbreviated TT checker for use
# with grader.pl
#
# Takes two arguments: a sequent ($argument) and an abbreviated TT
# ($answer).  Checks (1) the syntactic form of an ATT (e.g., enough
# rows, correct number of truth values in each row, no inappropriate
# characters in any row, etc); (2) the calculation of truth values in
# each row; (3) the user's evaluation of validity; and (4) the user's
# choice of invalidating row.  An evaluation of validity is not
# necessary, though if a TT is judged invalid, an invalidating row
# must be entered to receive full credit.
#
# To Do
# 1. Call code to reformat user's submitted ATT
# 2. NEED TO CHECK THAT ATOMS HAVEN'T BEEN FUTZED WITH!!
#
# Questions
# 1. Should we reject if an invalidating row has been entereed
# despite an evaluation of "valid"?  (Currrently, a warning is given
# but credit given if the argument is indeed valid.)


############
# Requires #
############

require "../lib/wff-subrs.pl";
require "../Grader/grader-subrs.pl";
require "../TT/extract_nth_subwff.pl";
require "../TT/make-tt-template.pl";
require "../TT/grader-messages.pl";
require "../TT/tt-subrs.pl";


########################
##### MAIN ROUTINE #####
########################

&initialize;

&print_log and exit
  if !&check_user_arg;

&print_log and exit
  if !&check_atoms;

&check_rows;
&print_log and exit
  if ($invalidating_row_identified
      or $invalidating_row_missed
      or $no_rows
      or $bad_form);

&check_att_validity;
&print_log;

#######################
##### Subroutines #####
#######################

sub initialize {

    # Initialize some global vars
    $answer = "";
    $argument = "";
    $atoms = "";
    $atoms_in_conclusion = "";
    $conclusion = "";
    $conclusion_check = 0;
    $correct = 0;
    $dashes = "";
    @invalidating_row_identified = ();
    $invalidating_row_missed;
    @invalidating_rows = ();
    @legit_rows = ();
    $logstuff = "";
    $bad_form = 0;
    $no_rows = 0;
    $num_atoms = 0;
    $num_atoms_in_conclusion = 0;
    $num_rows = 0;
    $num_wffs = 0;
    @premises = ();
    @premise_check = ();
    $premise_check = 0;
    $result_att = 0;
    $result_form_check = 0;
    $result_invalidating = 0;
    $result = 0;
    @rows = ();
    @sequent = ();
    $user_arg = "";
    $user_eval = "";
    $user_invalidating_tva = "";
    @user_tvs = ();

    $argument = <>;
    while (<>) {
	$answer .= $_;
    }

    $logstuff = "<p />\n<strong>Argument:</strong> <tt>$argument</tt><br />\n";
    $logstuff .= "<strong>Student's Answer:</strong>\n" .
      "<pre>\n" . $answer . "</pre>\n";

    # Build student answer components
    for (split(/\n/,$answer)) {
	next if /^\s*$/;
	$dashes = $_ and next
	  if /^[-\s|]*$/;               # ignore blank lines and separator lines
	s/\s*//g;                       # remove whitespace
	$user_eval = $_ and next
	  if /valid/i
	    && !$user_eval;             # Don't accept any evals after the first
	$user_arg = $_ and next         # Extract the first line of the user's ATT
	  if /:\.|\.:/ && !$user_arg;
	push @rows, $_;
	s/^.*?\|\s*([TF].*)$/$1/;       # extract the calculated TVs under the arg
	$_ =~ s/\s*//g;
	push @user_tvs, $_;
    }

#     print "USER_TVS: @user_tvs\n";
    
    # Remove horiz whitespace to form "clean" argument
    $arg = $argument;
    $arg =~ s/\s*//g;
    $atoms = $arg;
    $atoms =~ s/([^A-Z])//g;
    $atoms = &remove_string_duplicates($atoms);
    $atoms = join(//,sort(split(//,$atoms)));
    
    $user_eval =~ tr/A-Z/a-z/;
    $user_arg =~ s/^(.*?)\|(.*)/$2/;
    $user_atoms = $1;
    $num_rows = @rows;

    # Make the ATT template;
    $att_template = &make_att_template($arg);

    # @sequent is an array containing the premises and the conclusion
    $sequent = $arg;
    $sequent =~ s/,|:\.|\.:/ /g;
    @sequent = split(/\s+/,$sequent);

    @premises = @sequent;
    $conclusion = pop @premises;

    $atoms_in_conclusion = $conclusion;
    $atoms_in_conclusion =~ s/[^A-Z]//g; # extract the atoms in $conclusion
    $atoms_in_conclusion = &remove_string_duplicates($atoms_in_conclusion);
    $atoms_in_conclusion =~ s/\s*//g;

    $num_atoms_in_conclusion = length($atoms_in_conclusion);
    $num_atoms = $atoms =~ tr/A-Z/A-Z/;
    $num_wffs = scalar(@sequent);

}

###
sub check_atoms {
    my $arg_comparison = &compare_atoms($atoms,$user_atoms);
    print STDERR "ARG COMP: $arg_comparison\n";

    $logstuff .=
      &msg_wrapper(&msg_CannotFutzWithAtoms($atoms,$user_atoms,$arg_comparison))
	and return 0
	  unless $arg_comparison eq 'ok';
    return 1;
}

###
sub check_user_arg {

    # Check that the original argument hasn't be futzed with
    $logstuff .= &msg_wrapper
      (&msg_CannotFutzWithATTArg($arg,$user_arg))
	and return 0
	  unless &samearg($arg,$user_arg);
    return 1;
}

sub check_rows {

    # Check there are some rows
    if (!@rows) {
	$logstuff .= &msg_wrapper(&msg_NoRows);
	$no_rows = 1;
	return
    }

    # Loop for evaluating each row
  ROW: 
    for ($i=0;$i<$num_rows;$i++) {

	my $row = $rows[$i];
	my $ith_row_user_tvs = $user_tvs[$i];
	local $bad_tv_calculation = 0;
	local $conflicting_assignments = 0;
	local $row_is_invalidating = 1;

	# Extract the TVs assigned to sentence letters in the ith row
	# if there is one
	local $tvs_in_ith_tva = $rows[$i];
	$tvs_in_ith_tva =~ s/^(.*?)\|.*/$1/;
	$tvs_in_ith_tva =~ s/\s*//g;

	local $wff_tv;
	local $ith_tva = "";
	local $row_num = $i+1;
	$ith_user_tva = "";

	# Construct the TVA given in a purportedly invalidating row
	# (so only takes TVs from TVA area)

	$tmp_atoms = $atoms;
	my $tmp_tvs = $tvs_in_ith_tva;

	while ($tmp_tvs) {
	    $ith_tva = chop($tmp_atoms).chop($tmp_tvs)." $ith_tva";

	}
	$ith_tva =~ s/\s*$//g;  # $ith_tva (if nonempty) looks like this:  "AT BF CT"

	local @argument_with_tvs;
	local $k = 0;

	foreach $wff (@sequent) {
	    $num_conns_and_atoms_in_wff = &count_conns_and_atoms($wff);
	    $tvs_assoc_with_wff = substr($ith_row_user_tvs,$k,$num_conns_and_atoms_in_wff);
	    push(@argument_with_tvs,$wff." $tvs_assoc_with_wff");
	    $k += $num_conns_and_atoms_in_wff;
	}

	$conclusion_with_tvs = pop(@argument_with_tvs);
	@premises_with_tvs = @argument_with_tvs;

	$logstuff .= "<strong><em>Row $row_num</em></strong><br />\n";
	$logstuff.= "<strong>Form check:</strong> ";
	&check_form_of_ATT_row($row,$ith_row_user_tvs);

	$logstuff.= "<strong>Conclusion check:</strong> ";
	$conclusion_check = &check_conclusion_correctly_assigned_F;

	$logstuff.= "<strong>Premise check:</strong> ";
	$premise_check = &check_premises_correctly_assigned_T_or_slash;

	# If there are no calculation errors or conflicting asssignment...
	if ($conclusion_check + $premise_check == 2) {
	    # ...mark $row_num as invalidating, if it is.
	    if ($row_is_invalidating) {  # $row_is_invalidating remains set to 1 if no slashes found
		push @invalidating_row_identified, &check_invalidating_row_identified;
	    }
	    # Otherwise, it's a legitimate, noninvalidating row
	    else {
		$logstuff .= "<strong>Row eval: </strong>";
		$logstuff .=
		  "<font color=\"blue\"><em>Row $row_num is a legitimate, noninvalidating row.</em></font><br />\n";
		push(@noninvalidating_user_tvas,$ith_user_tva);
	    }
	}
    }
    # Set $result to 1 if an invalidating row as been identified
    $invalidating_row_identified = 1 and $correct = 1
      if grep {$_ == 1} @invalidating_row_identified;
}

#####################################################################
### Construct a list of those TVAs that make the conclusion false ###
### -- this accords with Principle 2 of Layman's procedure on     ###
### p. 234.  (Note that if the procedure has reached this point,  ###
### *all* TVAs are noninvalidating, i.e., the argument is valid.) ###
#####################################################################
### In more detail: We construct a list of all the TVAs for the
### argument (from make_att_template) and construct a list
### @noninvalidating_tvas_false_conclusion by checking in turn whether
### the TVA we're looking at differs from the TVAs already in the list
### in what it assigns to the atoms in $conclusion, and push it onto
### @noninvalidating_tvas_false_conclusion if, and only it, it does so
### differ.  The idea here is that a student will only have one row
### representing all TVAs that agree on the TVs of the atoms --- but
### there might be multiple such TVAs in a full TT, since there might
### be atoms in the premises that do not occur in the conclusion.  We
### then just need to check the user's list of noninvalidating TVAs
### that make the conclusion false with @noninvalidating_tvas_false_conclusion.
#####################################################################
### NOTE: For completeness need to add a procedure that prunes
### "redundant" TVAs from @noninvalidating_user_tvas, in case the
### user has for some reason added distinct rows whose TVAs assign
### the same TVs to the atoms in the conclusion.  (In such cases
### different premises might end up slashed; or the same premise
### might be slashed for different reasons.)
#####################################################################
sub check_att_validity {

    my @tvas_false_conc = ();

    $logstuff.= "<strong>Validity check:</strong> ";
    @tvas = &get_tvas;

    # Remove TVAs that make conclusion true
    foreach $tva (@tvas) {
	my $tva_hash = $tva;
	$tva_hash =~ s/(\w)(\w)/$1 $2/g;
	%tva = split(/ /,$tva_hash);
	push(@tvas_false_conc,$tva) if &calculate_tv($conclusion,%tva) =~ /F/;
    }

    my @nonredundant_tvas_false_conc = &remove_redundant_tvas(@tvas_false_conc);
    my @truncated_nonredundant_tvas_false_conc =
      &truncate_tvas(@nonredundant_tvas_false_conc);

    my @truncated_noninvalidating_user_tvas =
      &truncate_tvas(@noninvalidating_user_tvas);

    my @can_trunc_noninv_user_tvas =
      &canonize_tvas(@truncated_noninvalidating_user_tvas);

    my @can_trunc_nonred_tvas_false_conc =
      &canonize_tvas(@truncated_nonredundant_tvas_false_conc);

    my @missing_truncated_tvas =
      &find_missing_tvas(\@can_trunc_noninv_user_tvas,\@can_trunc_nonred_tvas_false_conc);

#     print "1. TVAS: @tvas\n";
#     print "2. TVAS: @tvas_false_conc\n";
#     print "3. TVAS: @nonredundant_tvas_false_conc\n";
#     print "4. TVAS: @truncated_nonredundant_tvas_false_conc\n";
#     print "5: TVAS: @can_trunc_nonred_tvas_false_conc\n";
#     print "6. TVAS: @noninvalidating_user_tvas\n";
#     print "7. TVAS: @can_trunc_noninv_user_tvas\n";
#     print "8. TVAS: @missing_truncated_tvas\n";

    $logstuff .=
      &msg_wrapper(&msg_ValidityNotDemonstrated
		   (\@missing_truncated_tvas, sort @legit_rows)) and return
	if @missing_truncated_tvas;

      if ($user_eval =~ /^valid/i) {
        if (!@missing_truncated_tvas) {
	    $correct = 1;
	    $logstuff .= &msg_wrapper(&msg_ATTValid,$correct);
	    return;
        }

	my $num1 = @noninvalidating_user_tvas;
	my $num2 = @nonredundant_tvas_false_conc;
	$correct = 1;
	$logstuff .=
	  &msg_wrapper
	    (&msg_ATTValidWithExtraRows
	     ($num1,$num2,@noninvalidating_user_tvas),$correct);
	return;
	}

    $logstuff .=
      &msg_wrapper(&msg_InvalidATTDeclaredValid);
    $correct = 0;
    return;
}


#############################################################################
# This function checks to see that a given row of a user's abb. truth table #
# has the right form in various respects.                                   #
#############################################################################

sub check_form_of_ATT_row {

    my ($row,$ith_row_user_tvs) = @_;
    my $row_ok = 1;

    # Check for invalid characters
    $logstuff .=
      &msg_wrapper(&msg_InvalidATTChar($row_num,$row))
	and  next ROW
	  if $row =~ /[^TF\|\/]/;

    # Check that there is a vertical bar
    $logstuff .=
	&msg_wrapper(&msg_NoVertBar($row_num))
	and $bad_form = 1
	and next ROW
	  if $row !~ /\|/;

    # Check that there isn't more than one vertical bar
    $logstuff .=
	&msg_wrapper(&msg_TooManyATTVertBars($row_num))
	and $bad_form = 1
	and next ROW
	if $row =~ /\|.*\|/;

    # Check that there isn't more than one slash
    $logstuff .=
	&msg_wrapper(&msg_TooManySlashes($row_num))
	and $bad_form = 1
	and next ROW
	if $row =~ /\/.*\//;

    # Check that there aren't too many TVs in the TVA area in a row
    $logstuff .=
      &msg_wrapper(&msg_TooManyTVsInTVA($row_num))
      and $bad_form = 1
      and next ROW
      if $tvs_in_ith_tva =~ /[TF]/ and length($tvs_in_ith_tva) > length($atoms);

    # Check that there aren't too few TVs in the TVA in a row
    $logstuff .=
      &msg_wrapper(&msg_TooFewTVsInTVA($row_num))
	and $bad_form = 1
	and next ROW
	  if $tvs_in_ith_tva and (length($tvs_in_ith_tva) < length($atoms));

    # Check that the conclusion hasn't been assigned a slash
    $logstuff .=
      &msg_wrapper(&msg_SlashAssignedToConclusion($row_num,$conclusion))
	and $bad_form = 1
	and next ROW
	  if $conclusion_with_tvs =~ /\//;

    # Check that there is no TVA for rows that do contain a / .
    # Currently set only to yield a warning -- $row_ok no set to
    # 0. User's answer will be accepted if answer is correct in
    # all other respects.
    $logstuff .= "WARNING: " .
      &msg_wrapper(&msg_InappropriateTVA($row_num))
	if $tvs_in_ith_tva =~ /[TF]/ && $row =~ /\//;

    # Check that the user TVs in a row don't outnumber the atoms
    # and connectives in the argument
    $logstuff .=
      &msg_wrapper(&msg_TooManyTVsInATTRow($row_num))
	and $bad_form = 1
	and next ROW
	  if &count_conns_and_atoms($argument) < &count_TVs_and_slashes($ith_row_user_tvs);

    # Check that the user TVs in a row are not outnumbered by the
    # atoms and connectives in the argument
    $logstuff .= 
      &msg_wrapper(&msg_TooFewTVsInATTRow($row_num))
	and $bad_form = 1
	and next ROW
	  if &count_conns_and_atoms($argument) > &count_TVs_and_slashes($ith_row_user_tvs);

    $logstuff .= "Basic form of Row $row_num is ok.<br />\n";
    return 1;
}

### Check that the conclusion was assigned F -- note that
### &evaluate_wff_with_tvs first checks that the TV assigned
### to a WFF by the user was calculated correctly.

# Returns 1 if OK, adds error to logstuff and returns if not

sub check_conclusion_correctly_assigned_F {

    my $wff_tv = &evaluate_wff_with_tvs($conclusion_with_tvs);
    $logstuff .=
      &msg_wrapper(&msg_TAssignedToConclusion($row_num,$conclusion))
	and return 0
	  if $wff_tv eq "T";

    return 0 if $bad_tv_calculation or $conflicting_assignments;

    $logstuff .= "Conclusion correctly assigned <tt>F</tt>";
    $logstuff .= " and truth values calculated correctly"
      if !&atomic($conclusion);
    $logstuff .= ".<br />\n";
    return 1;
}

sub check_premises_correctly_assigned_T_or_slash {
    my $premise_tvs = "";

    foreach $premise_with_tvs (@premises_with_tvs) {
	my $premise_tv = &evaluate_wff_with_tvs($premise_with_tvs);
	my ($premise,$tvs) = split(' ',$premise_with_tvs);
	my $got_slashes;

	# Check for bad slashes
	&check_for_slashes_not_under_main_connective($premise,$tvs)
	  and $row_is_invalidating = 0
	    if $tvs =~ /\// and !&atomic($premise);

	$logstuff .=
	  &msg_wrapper(&msg_FAssignedToPremise($row_num,$premise))
	    and $row_is_invalidating = 0
	      if $premise_tv eq "F";

	# Row can't be invalidating if / has been correctly applied to a premise
	$row_is_invalidating = 0
	  if $premise_tv eq '/';
    }

    return 0
      and $logstuff .=
	"Truth value calculation or incorrect truth value assignment detected.<br />\n"
	  if $conflicting_assignments or $bad_tv_calculation;
    push @legit_rows, $row_num;
    $logstuff .= "Premises assigned \'<tt>T</tt>\' or \'/\'";
    $logstuff .= " and calculated correctly"
      if grep !&atomic($_), @premises;
    $logstuff .= ".<br />\n";
    return 1;
}

sub check_invalidating_row_identified {
    # This routine is called only if $invalidating = 1, which
    # means that the current row is indeed invalidating, i.e., that
    # the premises have correctly been assigned T and the conclusion
    # correctly assigned F. So all we have do here is check to see
    # that the user has inserted a TVA for the invalidating row in the
    # TVA area to the left of the vertical bar and has asserted
    # "invalid" below the ATT.  If so, a "Correct" evaluation msg is
    # added to $logstuff and the $result_invalidating flag set to 1.
    # If not, an appropriate error msg is generated.

    if (!$ith_tva) {
	$ith_user_tva =~ s/\s*$//;         # remove trailing whitespace
	$ith_user_tva = join(' ',sort(split(/\s+/,$ith_user_tva)));
	my $ith_user_tvs = $ith_user_tva;
	$ith_user_tvs =~ s/[A-Z]([TF])/$1/g;
	my $atoms_with_spaces = $ith_user_tva;
	$atoms_with_spaces =~ s/([A-Z])[TF]/$1/g;
	$logstuff .= &msg_wrapper
	  (&msg_InvalidatingRowButNoTVA($row_num,$atoms_with_spaces,$ith_user_tvs));
	$invalidating_row_missed = 1;
	return 0;
    }

    # Following routines should be called only after all rows are evaluated.

    $logstuff .= &msg_wrapper(&msg_InvalidatingRowButNoEval($row_num))
      and $invalidating_row_missed = 1
	and return 0
	  if !$user_eval;

    $logstuff .= &msg_wrapper(&msg_InvalidATTDeclaredValid($row_num))
      and $invalidating_row_missed = 1
	and return 0
	  if $user_eval eq 'valid';

    push @invalidating_rows, $row_num
      and $logstuff .= "<strong>Validity check: </strong>" . &msg_wrapper(&msg_CorrectATTInvalid(@invalidating_rows),1)
	and return 1
	  if ($user_eval eq 'invalid');

}

### %%################## evaluate_wff_with_tvs #######################
### This routine takes a string of the form "<wff> <TVs>", where <TVs>
### is a the string of TVs assigned to the atoms and connectives of
### <wff>, and checks that the TV calculations are all correct.  If
### so, the routine returns the truth value assigned to the main
### connective of <wff> (or to <wff> itself if it's atomic).  If not,
### the routine returns a 0 and writes an error msg to $logstuff.  We
### let the script keep running to find other errors in order to get
### as complete an evalution msg for the submitted ATT as possible.
### ##################################################################
sub evaluate_wff_with_tvs {
    my ($wff_with_tvs) = @_;
    my ($wff,$tvs) = split(/ /,$wff_with_tvs);
    my $wff_type = &wff($wff);
    my $wff_tv = &get_tv_for_wff($wff,$tvs);

  EVAL:
    {
	# When $wff is an atom, the routine tacks the string
	# "$wff$wff_tv " onto the end of $ith_user_tva if it is not a
	# duplicate and generates and error if it conflicts with an
	# earlier assignment to $wff or with the assignment to $wff by
	# the TVA the user has given for the row (stored in $ith_tva).
	# If there is no conflict, then the row is confirmed as
	# invalidating if the argument makes it through this procedure
	# for the entire argument.

	if ($wff_type eq "atomic") {

	    # Check that another occurrence of $wff has not already been
	    # assigned a conflicting TV
	    if ($ith_user_tva =~ /$wff[TF]/ and
		$ith_user_tva !~ /($wff$wff_tv)|($wff\/)/ and
		$wff_tv ne '/') {
		$logstuff .=
		  &msg_wrapper(&msg_ConflictingAssignments1($wff,$row_num));
		$conflicting_assignments = 1;
	    }

	    # Check that the TV user has assigned to $wff doesn't conflict
	    # with the TVA given for the row (if there is one)
#        print "WFF:WFF_TV: $wff:$wff_tv\nITH_tva: $ith_tva\n";
	    if ($ith_tva =~ /$wff[TF]/ and
		$ith_tva !~ /$wff$wff_tv/) {
		$logstuff .=
		  &msg_wrapper(&msg_ConflictingAssignments2($wff,$wff_tv,$row_num));
		$conflicting_assignments = 1;
	    }

	    $ith_user_tva .= "$wff$wff_tv "   # $ith_user_tva looks like this: "PT QF RF "
	      if $ith_user_tva !~ /$wff$wff_tv/ and $wff_tv ne "/";

	    print STDERR "Truth value $wff_tv assigned to $wff.\n";
	    return $wff_tv;
	}

	if ($wff_type eq "negation") {

	    my $noneg_wff = $wff;
	    $noneg_wff =~ s/^~(.*)/$1/;
	    my $noneg_wff_tv = &evaluate_wff_with_tvs($noneg_wff." ".substr($tvs,1));
	    if ($wff_tv eq $noneg_wff_tv) {
		$bad_tv_calculation = 1;
		$logstuff .=
		&msg_wrapper
		  (&msg_BadNegation($wff,$wff_tv,$noneg_wff,$row_num));
		next ROW;
	    }
	      # Case where $wff_tv is a slash
	    if ($wff_tv eq '/' and $noneg_wff_tv eq "F") {
		$logstuff .=
		  &msg_wrapper
		    (&msg_BadNegationWithSlash($wff,$noneg_wff,$row_num));
		next ROW;
	    }
	    return $wff_tv;
	}

	my $lhs = &lhs($wff);
	my $rhs = &rhs($wff);

	my $num_lhs = &count_conns_and_atoms($lhs);
	my $lhs_tv = &evaluate_wff_with_tvs($lhs." ".substr($tvs,0,$num_lhs));
	my $rhs_tv = &evaluate_wff_with_tvs($rhs." ".substr($tvs,$num_lhs+1));

	if ($wff_type eq "conjunction") {
	    $conj_tv = &conj($lhs_tv,$rhs_tv);
	    # $wff_tv is a TV or a /
	    if ($conj_tv ne $wff_tv) {
		# Case where $wff_tv is a TV
		if ($wff_tv ne '/') {
		    $bad_tv_calculation = 1;
		    $logstuff .=
		      &msg_wrapper
			(&msg_BadConjunction($wff,$wff_tv,$lhs,$rhs,$lhs_tv,$rhs_tv,$row_num));
		    next ROW;
		}
		# Case where $wff_tv is a slash
		if ($conj_tv eq "T") {
		    $bad_tv_calculation = 1;
		    $logstuff .=
		      &msg_wrapper
			(&msg_BadConjunctionWithSlash
			 ($wff,$wff_tv,$lhs,$rhs,$lhs_tv,$rhs_tv,$row_num));
		    next ROW;
		}
	    }
	}

	if ($wff_type eq "disjunction") {
	    $disj_tv = &disj($lhs_tv,$rhs_tv);
	    if ($disj_tv ne $wff_tv) {
		if ($wff_tv ne '/') {
		    $bad_tv_calculation = 1;
		    $logstuff .=
		      &msg_wrapper
			(&msg_BadDisjunction($wff,$wff_tv,$lhs,$rhs,$lhs_tv,$rhs_tv,$row_num));
		    next ROW;
		}
		if ($disj_tv eq "T") {
		    $bad_tv_calculation = 1;
		    $logstuff .=
		      &msg_wrapper
			(&msg_BadDisjunctionWithSlash
			 ($wff,$wff_tv,$lhs,$rhs,$lhs_tv,$rhs_tv,$row_num));
		    next ROW;
		}
	    }
	}
	
	if ($wff_type eq "conditional") {
#    	    print "COND WFF: $wff\n";
#  	    print "COND WFF TV: $wff_tv\n";
#    	    print "LHS: $lhs\n";
#    	    print "LHS_TV: $lhs_tv\n";
#    	    print "RHS: $rhs\n";
#    	    print "RHS TV: $rhs_tv\n";

	    my $cond_tv = &cond($lhs_tv,$rhs_tv);
	    if  ($cond_tv ne $wff_tv) {
		if ($wff_tv ne '/') {
		    $bad_tv_calculation = 1;
		    $logstuff .=
		      &msg_wrapper
			(&msg_BadConditional($wff,$wff_tv,$lhs,$rhs,$lhs_tv,$rhs_tv,$row_num));
		    next ROW;
		}			
		if ($cond_tv eq "T") {
		    $bad_tv_calculation = 1;
		    $logstuff .=
		      &msg_wrapper
			(&msg_BadConditionalWithSlash
			 ($wff,$row_num));
		    next ROW;
		}
	    }
	}
	
	if ($wff_type eq "biconditional") {
	    my $bicond_tv = &bicond($lhs_tv,$rhs_tv);
	    if ($bicond_tv ne $wff_tv) {
		if ($wff_tv ne '/') {
		    $bad_tv_calculation = 1;
		    $logstuff .=
		      &msg_wrapper
			(&msg_BadBiconditional($wff,$wff_tv,$lhs,$rhs,$lhs_tv,$rhs_tv,$row_num));
		    next ROW;
		}
		if ($bicond_tv eq "T") {
		    $bad_tv_calculation = 1;
		    $logstuff .=
		      &msg_wrapper
			(&msg_BadBiconditionalWithSlash
			 ($wff,$wff_tv,$lhs,$rhs,$lhs_tv,$rhs_tv,$row_num));
		    next ROW;
		}
	    }
	}
    } # end EVAL

    print STDERR "Truth value $wff_tv assigned to $wff";
    print STDERR " is ok"
      unless $wff_tv eq '/';
    print STDERR ".\n";
    return $wff_tv;
}

###

sub check_for_slashes_not_under_main_connective {
    my ($wff,$tvs) = @_;
    $wff_type = &wff($wff);

    my $lhs = "";
    $lhs = &lhs($wff) if $wff_type !~ /neg/;
    my $num_lhs = &count_conns_and_atoms($lhs);
    my $lhs_tvs = substr($tvs,0,$num_lhs);
    my $rhs_tvs = substr($tvs,$num_lhs+1);

    # return 1 if there are no bad slashes
    return 1 if ($lhs_tvs.$rhs_tvs) !~ /\//;

    my $subwff;
    if ($wff_type =~ /neg/) {
	$subwff = $wff;
	$subwff =~ s/^~(.*)$/$1/;
    } else {
	$subwff = &rhs($wff);
	$subwff = $lhs if $lhs_tvs =~ /\//;
    }

    $logstuff .=
      &msg_wrapper(&msg_BadSlash($row_num,$subwff,$wff));

    return;
}

###

sub check_invalidating_row {

    my @foo;
    my $bar = $user_invalidating_tva;
    $bar =~ s/:/ /g;
    @user_invalidating_tva = split(/\s+/,$bar);

    foreach $fla (@sequent) {
      push @foo, &calculate_tv($fla,@user_invalidating_tva);
    }

    $result_invalidating_row = &invalidating(@foo);
    $result = $result_invalidating_row;
    $logstuff .= "<strong>Invalidating assignment:</strong> ";
    $logstuff .= &msg_Invalidating . "<br />\n", if $result_invalidating_row;
    $logstuff .= &msg_wrapper(&msg_NotInvalidating), if !$result_invalidating_row;
}

###

sub user_invalidating_tva_is_ok {

    if ($user_eval =~ /invalid/i && !$user_invalidating_tva) {
	$logstuff .= "<strong>Form: </strong>" .
          &msg_wrapper(&msg_NoInvalidatingAssignment);
	return 0;
    }

 ### THIS SHOULD BECOME UNNECESSARY IF WE SORT ATOMS FROM THE GIT-GO
    @ats = split(//,$atoms);
    my @sorted_ats = sort @ats;
    my $ats = join(' ',@sorted_ats);

    my $example_inv_row = join(":_ ",@ats);
    $example_inv_row .= ":_";

    my $foo = $user_invalidating_tva;

    my @check_tva_form = split(/\s+/,$foo);
    foreach (@check_tva_form) {
	if (!/^\w:[TF]$/) {
	    $logstuff .= "<strong>Form: </strong>" .
              &msg_wrapper(&msg_InvAssignmentNotProperForm($example_inv_row,$foo));
	    return 0;
	}
    }

    # Extract the atoms from the invalidating assignment and clean up
    $foo =~ s/:[TF]//g;
    $foo =~ s/^\s*(.*)\s*$/$1/;

    # Sort the atoms  ## SHOULD BE UNNECESSARY NOW
    @foo = split(/\s+/,$foo);
    my @user_ats = sort @foo;
    my $user_ats = join(' ',@user_ats);

    if (@user_ats < @ats) {
	$logstuff .= "<strong>Form: </strong>" .
          &msg_wrapper(&msg_NotEnoughAtoms($ats,$user_ats));
	return 0;
    }

    if (@user_ats > @ats) {
	$logstuff .= "<strong>Form: </strong>" .
          &msg_wrapper(&msg_TooManyAtoms($ats,$user_ats));
	return 0;
    }

    if ($user_ats ne $ats) {
	$logstuff .= "<strong>Form: </strong>" .
          &msg_wrapper(&msg_DifferentAtoms($ats,$user_ats));
	return 0;
    }

    return 1;
}

###

sub print_log {

    $logstuff .= "<strong>Overall problem evaluation:</strong> ";
    $logstuff .= "<b><i>Correct</i></b>\n<p />\n" if $correct;
    $logstuff .= "<b><i>Incorrect</i></b>\n<p />\n" if !$correct;
    print $logstuff;
}

###
# Runs through TVs assigned to premises and conclusion in a row
# Returns 1 iff premises are assigned T and conclusion assigned F

sub invalidating {

    return 0 if pop eq "T";
    while (@_) {
	return 0 if pop eq "F";
    }
    return 1;
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

sub htmlify_answer {
    my ($answer) = @_;
    $answer =~ s/\n/\n<br \/>/gs;
    return $answer;
}

1;
