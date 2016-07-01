#!/usr/bin/perl -w

sub msg_ItsATautologyAlright {
    my ($wff) = @_;
    my $lhs = &lhs("($wff)");  # 7.5B doesn't use outer parens in the probset
    my $rhs = &rhs("($wff)");
    my $pretty_wff = &prettify($wff);
    my $pretty_lhs = &prettify($lhs);
    my $pretty_rhs = &prettify($rhs);

    return "Your truth table is correct.  Because <p><center><tt>$pretty_wff</tt></center><p> is true in every row of the truth table, you have thereby demonstrated that <p><center><tt>$pretty_lhs</tt></center><p> and <p><center><tt>$pretty_rhs</tt></center><p> are logically equivalent."
}

###
sub msg_NotContingent {
    my ($wff) = @_;
    my $pretty_wff = &prettify($wff);
    return "You have asserted that the WFF <p><center><tt>$pretty_wff</tt></center><p> is contingent.  However, a contingent statement is one that is true in at least one row of the truth table and false in at least one row.  This is not the case for this wff, so it is not contingent."
}

###
sub msg_CorrectContingent {
    my ($wff) = @_;
    my $pretty_wff = &prettify($wff);
    return "You are correct!  The WFF <p><center><tt>$pretty_wff</tt></center><p> is true in at least one row and it is false in at least one row and is therefore contingent."
}

###
sub msg_NotAContra {
    my ($wff) = @_;
    my $pretty_wff = &prettify($wff);
    return "You have asserted that the WFF <p><center><tt>$pretty_wff</tt></center><p> is a contradiction.  However, it is true in at least one row, and so it is not the case that it is false regardless of the truth values assigned to the atomic statements that compose it.  So it cannot be a contradiction."
}

###
sub msg_CorrectContra {
    my ($wff) = @_;
    my $pretty_wff = &prettify($wff);
    return "You are correct!  The WFF <p><center><tt>$pretty_wff</tt></center><p> has the truth value <tt>F</tt> in every row and is therefore a contradiction; it is false regardless of the truth values assigned to the atomic statements that compose it."
}

###
sub msg_NotATautology {
    my ($wff) = @_;
    my $pretty_wff = &prettify($wff);
    return "You have asserted that the WFF <p><center><tt>$pretty_wff</tt></center><p> is a tautology.  However, it is false in at least one row, and so it is not true regardless of the truth values assigned to the atomic statements that compose it.  So it cannot be a tautology."
}

###
sub msg_CorrectTautology {
    my ($wff) = @_;
    my $pretty_wff = &prettify($wff);
    return "You are correct!  The WFF <p><center><tt>$pretty_wff</tt></center><p> has the truth value <tt>T</tt> in every row and is therefore a tautology; it is true regardless of the truth values assigned to the atomic statements that compose it."
}

###
sub msg_SlashInConclusion {
    my $row_num = shift;
    return "A slash \'/\' has been assigned to a sentence letter or logical operator in the conclusion; slashes can only occur beneath the main logical operator of a premise in an abbreviated truth table."
}

###
sub msg_BadSlash {
    my ($row_num,$subwff,$wff) = @_;
    my $pretty_subwff = &prettify($subwff);
    my $pretty_wff = &prettify($wff);

    return "In Row $row_num, a slash '/' has been assigned to a statement letter or logical operator in the subWFF <tt>$pretty_subwff</tt> of the premise <tt>$pretty_wff</tt>.  A slash is used in a row of an abbreviated truth table to indicate that a premise (in this case, <tt>$pretty_wff</tt>) cannot be made true given the truth values assigned to the statement letters in the conclusion of the argument in that row.  However, this should be indicated by assigning the slash to the main logical operator of the premise itself; there should be no slash assigned any other of its components."
}

###
sub msg_EmptyATT {
    return "Your truth table contains no rows.  The only time such a truth table can count as complete is when the conclusion of the arguent in question is valid.  That is not the case here. Hence, your truth table is incomplete."
}

###
sub msg_ValidConclusion {
    return "As you hopefully have seen, even though your truth table has no rows filled in beneath the argument, it nonetheless shows that the argument is valid.  The reason for this is that the conclusion of the argument is a <em>tautology</em> (see Section 7.5); there is no way to make it false.  Thus, an empty truth table for an argument with a tautologous conclusion represents all the ways there are (namely, none) of making the conclusion false and the premises true -- simply because there is no way to make the conclusion true!  Thus, under these circumstances (and only under these) an empty abbreviated truth table indicates that the argument is valid."
}


###
sub msg_DuplicateRows {
    my ($i,$j) = @_;
    return "Rows $i and $j are identical in your abbreviated truth table."
}

###
sub msg_TooManyTVsInATTRow {
    my ($row_num) = @_;
    return "Too many truth values have been entered in the area below the argument in Row $row_num.  There should be exactly one truth value (or slash '/') for each statement letter and connective in the argument."
}

###
sub msg_TooFewTVsInATTRow {
    my ($row_num) = @_;
    return "You have not entered enough truth values below the argument in Row $row_num.  There should be exactly one truth value for each statement letter and connective in the argument."
}

###
sub msg_BadNegation {
    my ($neg,$neg_tv,$rhs,$row_num) = @_;
    my $pretty_neg = &prettify($neg);
    my $pretty_rhs = &prettify($rhs);
    return "The negated wff <tt>$pretty_neg</tt> has been assigned <tt>$neg_tv</tt> in Row $row_num, but its immediate component <tt>$pretty_rhs</tt> has also been assigned <tt>$neg_tv</tt>.";
}

###
sub msg_BadNegationWithSlash {

    my ($neg,$noneg_wff,$row_num) = @_;
    my $pretty_neg = &prettify($neg);
    my $pretty_noneg = &prettify($noneg);

    my $msg = "The negation \'<tt>$pretty_neg</tt>\' has been assigned a slash ";
    $msg .= "in Row $row_num, indicating that it cannot be assigned the truth value ";
    $msg .= "\'<tt>T</tt>\' given the truth value of its immediate component ";
    $msg .= "\'<tt>$pretty_noneg</tt>\'.  But \'<tt>$pretty_noneg</tt>\' ";
    $msg .= "has been assigned \'<tt>F</tt>\'.";

    return $msg;
}

###
sub msg_BadConjunction {
    my ($wff,$wff_tv,$lhs,$rhs,$lhs_tv,$rhs_tv,$row_num) = @_;
    my $pretty_conj = &prettify($wff);
    my $pretty_lhs = &prettify($lhs);
    my $pretty_rhs = &prettify($rhs);
    return "The conjunction \'<tt>$pretty_conj</tt>\' has been assigned \'<tt>$wff_tv</tt>\' in Row $row_num, but its immediate components \'<tt>$pretty_lhs</tt>\' and \'<tt>$pretty_rhs</tt>\' have been assigned \'<tt>$lhs_tv</tt>\' and \'<tt>$rhs_tv</tt>, respectively.";
}

###
sub msg_BadConjunctionWithSlash {
    my ($wff,$wff_tv,$lhs,$rhs,$lhs_tv,$rhs_tv,$row_num) = @_;
    my $pretty_conj = &prettify($wff);
    my $pretty_lhs = &prettify($lhs);
    my $pretty_rhs = &prettify($rhs);
    my $msg = "The conjunction \'<tt>$pretty_conj</tt>\' has been assigned a slash ";
    $msg .= "in Row $row_num, indicating that it cannot be assigned the truth value <tt>T</tt> ";
    $msg .= "given the truth values of its conjuncts.  But its conjuncts ";
    $msg .= "\'<tt>$pretty_lhs</tt>\' and \'<tt>$pretty_rhs</tt>\' ";
    $msg .= "have been assigned \'<tt>$lhs_tv</tt>\' and \'<tt>$rhs_tv</tt>, ";
    $msg .= "respectively.";

    return $msg;
}

###
sub msg_BadDisjunction {
    my ($wff,$wff_tv,$lhs,$rhs,$lhs_tv,$rhs_tv,$row_num) = @_;
    my $pretty_disj = &prettify($wff);
    my $pretty_lhs = &prettify($lhs);
    my $pretty_rhs = &prettify($rhs);
    return "The disjunction \'<tt>$pretty_disj</tt>\' has been assigned \'<tt>$wff_tv</tt>\' in Row $row_num, but its immediate components \'<tt>$pretty_lhs</tt>\' and \'<tt>$pretty_rhs</tt>\' have been assigned \'<tt>$lhs_tv</tt>\' and \'<tt>$rhs_tv</tt>, respectively.";
}

###
sub msg_BadDisjunctionWithSlash {
    my ($wff,$wff_tv,$lhs,$rhs,$lhs_tv,$rhs_tv,$row_num) = @_;
    my $pretty_disj = &prettify($wff);
    my $pretty_lhs = &prettify($lhs);
    my $pretty_rhs = &prettify($rhs);
    my $msg = "The disjunction \'<tt>$pretty_disj</tt>\' has been assigned a slash ";
    $msg .= "in Row $row_num, indicating that it cannot be assigned the truth value <tt>T</tt> ";
    $msg .= "given the truth values of its disjuncts.  but its disjuncts ";
    $msg .= "\'<tt>$pretty_lhs</tt>\' and \'<tt>$pretty_rhs</tt>\' ";
    $msg .= "have been assigned \'<tt>$lhs_tv</tt>\' and \'<tt>$rhs_tv</tt>, ";
    $msg .= "respectively.";

    return $msg;
}

###
sub msg_BadConditional {
    my ($wff,$wff_tv,$lhs,$rhs,$lhs_tv,$rhs_tv,$row_num) = @_;
    my $pretty_cond = &prettify($wff);
    my $pretty_lhs = &prettify($lhs);
    my $pretty_rhs = &prettify($rhs);
    return "The conditional statement \'<tt>$pretty_cond</tt>\' has been assigned \'<tt>$wff_tv</tt>\' in Row $row_num, but its immediate components \'<tt>$pretty_lhs</tt>\' and \'<tt>$pretty_rhs</tt>\' have been assigned \'<tt>$lhs_tv</tt>\' and \'<tt>$rhs_tv</tt>, respectively.";
}

###
sub msg_BadConditionalWithSlash {
    my ($wff,$wff_tv,$lhs,$rhs,$lhs_tv,$rhs_tv,$row_num) = @_;
    my $pretty_cond = &prettify($wff);
    my $pretty_lhs = &prettify($lhs);
    my $pretty_rhs = &prettify($rhs);
    my $msg = "The conditional \'<tt>$pretty_cond</tt>\' has been assigned a slash ";
    $msg .= "in Row $row_num, indicating that it cannot be assigned the truth value <tt>T</tt> ";
    $msg .= "given the truth values of its antecedent \'<tt>$pretty_lhs</tt>\' ";
    $msg .= "and consequent.\'<tt>$pretty_rhs</tt>\'.  But those components ";
    $msg .= "have been assigned \'<tt>$lhs_tv</tt>\' and \'<tt>$rhs_tv</tt>, ";
    $msg .= "respectively.";

    return $msg;
}

###
sub msg_BadBiconditional {
    my ($wff,$wff_tv,$lhs,$rhs,$lhs_tv,$rhs_tv,$row_num) = @_;
    my $pretty_bicond = &prettify($wff);
    my $pretty_lhs = &prettify($lhs);
    my $pretty_rhs = &prettify($rhs);
    return "The biconditional statement \'<tt>$pretty_bicond</tt>\' has been assigned \'<tt>$wff_tv</tt>\' in Row $row_num, but its immediate components \'<tt>$pretty_lhs</tt>\' and \'<tt>$pretty_rhs</tt>\' have been assigned \'<tt>$lhs_tv</tt>\' and \'<tt>$rhs_tv</tt>, respectively.";
}

###
sub msg_BadBiconditionalWithSlash {
    my ($wff,$wff_tv,$lhs,$rhs,$lhs_tv,$rhs_tv,$row_num) = @_;
    my $pretty_bicond = &prettify($wff);
    my $pretty_lhs = &prettify($lhs);
    my $pretty_rhs = &prettify($rhs);
    my $msg = "The biconditional \'<tt>$pretty_bicond</tt>\' has been assigned a slash ";
    $msg .= "in Row $row_num, indicating that it cannot be assigned the truth value <tt>T</tt> ";
    $msg .= "given the truth values of its immediate components \'<tt>$pretty_lhs</tt>\' ";
    $msg .= "and.\'<tt>$pretty_rhs</tt>\'.  But those components ";
    $msg .= "have been assigned \'<tt>$lhs_tv</tt>\' and \'<tt>$rhs_tv</tt>, ";
    $msg .= "respectively.";

    return $msg;
}

###
sub msg_SlashAassignedtoAtom {
    my ($wff,$row_num) = @_;
    return "An occurrence of the statement letter \'<tt>$wff</tt>\' has been assigned the \"inconsistent\" truth value '<tt>/</tt>'.  All occurrences of statement letters should uniformly be assigned either a \'<tt>T</tt>\' or an \'<tt>F</tt>\'; a '<tt>/</tt>' should only occur under the main logical operator of a wff, indicating that you were not able consistently to assign a single truth value to that wff."
}


###
sub msg_ConflictingAssignments1 {
    my ($wff,$row_num) = @_;
    return "The statement letter (or atomic sentence) \'<tt>$wff</tt>\' has been assigned both \'<tt>T</tt>\' and \'<tt>F</tt>\' in Row $row_num."
}

###
sub msg_ConflictingAssignments2 {
    my ($wff,$wff_tv,$row_num,$exp_att_context) = @_;
    my $tv_of_wff_in_tva_area = 'T';
    $tv_of_wff_in_tva_area = 'F' if $wff_tv eq 'T';
    my $wff_type = 'statement letter';
    $wff_type = 'wff' if $exp_att_context;
    return "In Row $row_num, the assignment of the truth value \'<tt>$tv_of_wff_in_tva_area</tt>\' to the $wff_type \'<tt>$wff</tt>\' in the truth value assignment area (i.e., the area to the left of the vertical bar \'<tt>|</tt>\') conflicts with the value of \'<tt>$wff_tv</tt>\' that is assigned to one or more of the occurrences of \'<tt>$wff</tt> in the argument in that row."
}

###
sub msg_ValidityNotDemonstrated {
    my ($missing_tvas_ref,@legit_rows) = @_;
    my @missing_truncated_tvas = @$missing_tvas_ref;
    my $missing_truncated_tvas = join(', ',@missing_truncated_tvas);
    $missing_truncated_tvas =~ s/(.*)\s*$/$1/;

    my $plural = 's' if @missing_truncated_tvas > 1;
    my $insert;
    if (@legit_rows == 0) {
	$insert = "none, as there are calculation or assignment problems in every row";
    } elsif (@legit_rows == 1) {
	$insert = "Row " . pop(@legit_rows);
    } elsif (@legit_rows == 2) {
	$insert = "Rows " . shift (@legit_rows) . " and " . pop(@legit_rows);
    } else {
	$insert = "and " . pop @legit_rows;
	my @insert = map {$_ = "$_, "} @legit_rows;
	$insert = "Rows " . join('', @insert) . $insert;
    }

    return "The legitimate, noninvalidating rows of the submitted abbreviated truth table (i.e., those rows not involving a truth value assignment error or calculation error -- in this case: $insert) do not jointly demonstrate that the argument is valid, because there remain ways to make the conclusion false (notably, by the following truth value assignment$plural -- $missing_truncated_tvas) that are not represented by legitimate rows of the truth table."
}

###
sub msg_ATTRowIsInvalidating {
    my $row_num = shift;
        return "Row $row_num in the abbreviated truth table is correctly shown to be invalidating.<br />"
}


###
sub msg_CorrectATTInvalid {
    my @invalidating_rows = @_;
    my $invalidating_row = pop @invalidating_rows;

    return "The truth value assignment correctly identified in Row $invalidating_row makes the premise(s) of the argument true and the conclusion false."
      if @invalidating_rows == 0;

    my $invalidating_rows = join(', ',@invalidating_rows);
    $invalidating_rows =~ s/, (\d+)$/ and $1/;
    my $msg = "The truth value assignment correctly identified in Row $invalidating_row makes the premise(s) of the argument true and the conclusion false.  ";
    if (@invalidating_rows == 1) {
	$msg .= "(One such row -- Row $invalidating_rows -- has already been identified.  "
    } else {
	$msg .= "(Several such rows -- Rows $invalidating_rows -- have already been identified.  "
    }
    $msg .= "Note that only one such row is necessary to establish invalidity.)"
}

###
sub msg_CorrectATTInvalid_Old {
    my ($row_num,$ith_tva) = @_;
    my $last_atom_tva_pair = $ith_tva;
    $last_atom_tva_pair =~ s/.*(\w)([TF])$/\&\#160\;\<tt\>$1\<\/tt\>\&\#160\; is assigned \&\#160\;\<tt\>$2\<\/tt\>,\&\#160\;/;
    my $first_atom_tva_pairs = $ith_tva;
    $first_atom_tva_pairs =~ s/(.*)\w[TF]$/$1/;
    $first_atom_tva_pairs =~ s/(\w)([TF])/\&\#160\;\<tt\>$1\<\/tt\>\&\#160\; is assigned \&\#160\;\<tt\>$2\<\/tt\>\&\#160\;,/g;
    $first_atom_tva_pairs =~ s/(.*)\s*$/$1/;

    my $num = $first_atom_tva_pairs =~ tr/A-Z/A-Z/;  # counts how many atom/TV combinations there are
    $first_atom_tva_pairs =~ s/,\s*$// if $num == 2; # removes final comma if there's only two sentence letters

    return "The abbreviated truth table shows that the argument is invalid.  Specifically, Row $row_num shows that the premise(s) are true and the conclusion is false when statement letter $first_atom_tva_pairs and $last_atom_tva_pair."
}

###
sub msg_CorrectExpATTInvalid {
    my ($row_num,$translated_ith_tva) = @_;
    my $last_wff_tva_pair = $translated_ith_tva;
    $last_wff_tva_pair =~ s/.*([A-Z][a-z])([TF])$/\&\#160\;\<tt\>$1\<\/tt\> is assigned \&\#160\;\<tt\>$2\<\/tt\>,\&\#160\;/;
    my $first_wff_tva_pairs = $translated_ith_tva;
    $first_wff_tva_pairs =~ s/(.*)[A-Z][a-z][TF]$/$1/;
    $first_wff_tva_pairs =~ s/([A-Z][a-z])([TF])/\&\#160\;\<tt\>$1\<\/tt\> is assigned \&\#160\;\<tt\>$2\<\/tt\>,/g;

    my $num = $first_wff_tva_pairs =~ tr/A-Z/A-Z/;  # counts how many WFF/TV combinations there are
    $first_wff_tva_pairs =~ s/,\s*$// if $num == 2; # removes final comma if there's only two sentence letters

    return "Your abbreviated truth table is correct.  Row $row_num shows that the premises are all true and the conclusion is false when the WFF $first_wff_tva_pairs and $last_wff_tva_pair so the argument is invalid."
}

###
sub msg_FAssignedToPremise {
    my ($row_num,$premise) = @_;
    my $pretty_premise = &prettify($premise);
    return "The truth value \'<tt>F</tt>\' has been assigned to the premise \'<tt>$pretty_premise</tt>\' in Row $row_num.  An argument is invalid only if the conclusion can be false when all the premises are true.  Thus, invalidity cannot be shown by a row in an abbreviated truth table unless the premises are all assigned \'<tt>T</tt>, i.e., unless every premise is assumed to be true.";
}

###
sub msg_TAssignedToConclusion {
    local ($row_num,$conclusion) = @_;
    my $pretty_conclusion = &prettify($conclusion);
    return "The truth value \'<tt>T</tt>\' has been assigned to the conclusion <tt>$pretty_conclusion</tt> in Row $row_num.  An argument is invalid only if the conclusion can be false when all the premises are true.  Thus, invalidity cannot be shown by a row in an abbreviated truth table unless the conclusion is assigned \'<tt>F</tt>, i.e., unless the conclusion is assumed to be false.";
}

###
sub msg_InappropriateTVA {
    my ($row_num) = @_;
    return "Truth values have been assigned to the statment letters of the argument in the truth value assignment area (i.e., the area to the left of the vertical bar '<tt>|</tt>') in Row $row_num, but it has also indicated by the presence of a slash '<tt>/</tt>' beneath a logical operator that a consistent truth value assignment is not possible in this row.  If a consistent truth value assignment is not possible, all \'<tt>T</tt>'s and <tt>F</tt>'s should have been removed from the truth value assignment area.  Otherwise, the slash should have been replaced with an appropriate truth value."
}

###
sub msg_InvalidatingRowButNoTVA {
    my ($row_num,$atoms,$ith_user_tvs) = @_;
    return "Row $row_num shows that the argument is invalid (it makes the premise(s) true and the conclusion false), but there is no corresponding truth value assignment in the area beneath the sentence letters to the left of the vertical bar.  The sentence letters \"$atoms\" should have been assigned the truth values \"$ith_user_tvs\", respectively."
}

###
sub msg_InvalidatingRowButNoEval {
    my ($row_num,$ith_tva) = @_;
    return "Row $row_num shows that the argument is invalid (the indicated truth value $ith_tva makes the premise(s) true and the conclusion false), but no indication of invalidity was given below the abbreviated truth table."
}

###
sub msg_NoTVA {
    my ($row_num) = @_;
    return "No truth value assignment has been provided in the area to the left of the vertical bar '<tt>|</tt>' in Row $row_num."
}

###
sub msg_TooManyTVsInTVA {
    my ($row_num) = @_;
    return "There are more truth values than there are sentence letters in the truth value assignment area (i.e., the area consisting of the columns to the left of the vertical bar \"<tt>|</tt>\" in Row $row_num.  Exactly one \'<tt>T</tt> or \'<tt>F</tt> should be beneath each sentence letter in this area."
}

###
sub msg_TooFewTVsInTVA {
    my ($row_num) = @_;
    return "The truth value assignment given in Row $row_num to the statement letters (i.e., the ones in the list to the left of the argument) is incomplete; you have truth values in the columns beneath some, but not all, of those sentence letters."
}

###
sub msg_NoTherefore {
    return "The space provided is for entering an argument.  Hence, it must contain a \"therefore\" symbol (i.e., :.) that separates the premises of the argument from the conclusion."
}

###
sub msg_NothingEntered {
    return "Nothing was entered in the answer area."
}

###
sub msg_InconsistentTVA {
    return "Different truth values have been assigned to the statement letter '<tt>$_[0]</tt>' in Row $_[1].  Truth values must be assigned uniformly in each row to all occurrences of the same sentence letter."
}

###
sub msg_CannotFutzWithAtoms {
    my ($original_atoms,$futzed_with_atoms,$arg_comparison) = @_;
    $original_atoms =~ s/(\w)/$1 /g;
    $original_atoms =~ s/\s*$//;
    $futzed_with_atoms =~ s/(\w)/$1 /g;
    $futzed_with_atoms =~ s/\s*$//;

    my $msg = "The list of statement letters \'<tt>$futzed_with_atoms</tt>\' to the left of the argument in the first row of the abbreviated truth table has been altered.  ";
    $msg .= "It appears that there are duplicates.  "
      if $arg_comparison eq 'dups';
    $msg .= "It appears that one or more of the statement letters occurring in the argument have been deleted from the list.  "
      if $arg_comparison eq 'dels';
    $msg .= "It appears that there are statements letters in the list that do not occur in the argument.  "
      if $arg_comparison eq 'extras';
    $msg .= "One or more statement letters in the argument are missing from the list, and one or more statement letters in the list do not occur in the argument.  "
      if $arg_comparison eq 'dels_and_extras';
    $msg .= "Here is what the list should be: <tt>$original_atoms</tt>.  ";
    $msg .= "This problem makes it impossible to evaluate the submitted answer meaningfully."
}

###
sub msg_CannotFutzWithArg {
    my ($original_arg,$futzed_with_arg) = map &prettify_argument($_), @_;
    
    return "The argument in the problem you are working on has been altered in some important way (other than simply the addition or removal of spaces or outside parentheses)It should be \"<tt>$original_arg</tt>\" but it has been altered so that it looks like this: \"<tt>$futzed_with_arg</tt>\"."
}

###
sub msg_CannotFutzWithATTArg {
    my ($original_arg,$futzed_with_arg) = map &prettify_argument($_), @_;
    return "The argument in the problem you are working on has been altered in some important way (other than simply the addition or removal of spaces or outside parentheses).  The original argument looked like this:
<pre>
$original_arg
</pre>
but it has been altered so that it looks like this:
<pre>
$futzed_with_arg
</pre>
This problem makes it impossible to evaluate the submitted answer meaningfully."
}

###
sub msg_CannotFutzWithATTDashes {
    my ($first_2_lines_of_ATT_problem,$first_2_user_lines) = @_;
    return "You have removed or altered the second line of the problem that contains a series of dashes and a vertical bar.  To ensure your abbreviated truth table is evaluated correctly, the first two lines of your abbreviated truth table should not be altered in any way.  The first two lines in the original argument looked like this:
<pre>
$first_2_lines_of_ATT_problem
</pre>
but they have been altered so that they look like this:
<pre>
$first_2_user_lines
</pre>"
}

###
sub msg_NotEnoughRows {
    return "There are not enough rows in your truth table.  You have $_[0] but there should be $_[1]."
}

###
#sub msg_TooManyRows {
#    return "There are too many rows in your truth table.  There should only be $_[0]."
#}

###
sub msg_TooManyRows {
    return "There are either too many rows in your truth table (there should only be $_[0]) or something other than \"Valid\" or \"Invalid\" has been given as the truth table evaluation."
}

###
sub msg_MungedTVA {
    return "The truth value assignment in Row $_[0] has become corrupted.  It should look like this: <tt>\"$_[1]\"</tt>.  In the submitted truth table it looks like this: <tt>\"$_[2]\"</tt>."
}

###
sub msg_TooManyVertBars {
    return "There are too many vertical bars in Row $_[0].  There should be only the vertical bar that separates the preassigned truth values for the statement letters from the truth values that you enter beneath the argument."
}

###
sub msg_TooManyATTVertBars {
    my ($row_num) = @_;
    return "There are too many vertical bars in Row $row_num.  There should be only the vertical bar that separates the truth value assignment area for the list of statement letters to the left of the argument from the truth values that you enter beneath the statement letters and connectives in the argument."
}

###
sub msg_TooManySlashes {
    my $row_num = shift;
    return "It appears that there are too many forward slashes in Row $row_num."
}

###
sub msg_NoVertBar {
    return "The vertical bar that separates the truth value assignment area from the area  truth beneath the argument is missing in Row $_[0]."
}

###
sub msg_NoATTVertBar {
    my ($row_num) = @_;
    return "In Row $row_num, the verticfal bar that separates the truth value assignment area for the list of statement letters to the left of the argument from the truth values that you enter beneath the statement letters and connectives in the argument is missing."
}

###
sub msg_MissingTV {
    my ($row_num) = @_;
    return "A truth value is missing from the truth value assignment in Row $row_num."
}

###
sub msg_NoRows {
    return "The truth table appears to be empty.";
}

###
sub msg_InvalidChar {
    my ($row_num) = @_;
    return "An illegitimate character has been entered in Row $row_num.  (Only the truth values '<tt>T</tt>' and '<tt>F</tt>' (upper case), the vertical bar '<tt>|</tt>' and spaces should appear in each row.)"
}


###
sub msg_InvalidATTChar {
    my ($row_num,$row) = @_;
    my $invalid_chars = $row;
    $invalid_chars =~ s/[TF\|\/]//g;
    my @invalid_chars = split(//,$invalid_chars);
    my $verb = 'was';
    my $plural;
    if (length($invalid_chars) > 1) {
       my $plural = 's';
       $verb = 'were'; }

    return "The following illegitimate character$plural $verb entered in Row $row_num: \'<tt>@invalid_chars</tt>\'.  (Only the truth values '<tt>T</tt>' and '<tt>F</tt>' (upper case), the vertical bar '<tt>|</tt>', spaces, and possibly a forward slash '<tt>/</tt>' should appear in each row.)"
}


###
sub msg_ConclusionNotWff {
    return "The conclusion of your argument is not a wff.";
}

###
sub msg_NoConclusion {
    return "Your argument contains no conclusion.";
}

###
sub msg_PremiseNotWff {
    return "Your argument contains a non-WFF among its premises.";
}

###
sub msg_CorrectInvalid4 {
    return "You are correct!  Rows $_[0] and $_[1] show that the argument is invalid.  On these rows of the truth table, the premises of the argument are true and the conclusion false.  (There are other invalidating rows as well.)";
}

###
sub msg_CorrectInvalid3 {
    return "You are correct!  Rows $_[0] and $_[1] show that the argument is invalid.  On these rows of the truth table, the premises of the argument are true and the conclusion false.";
}

###
sub msg_CorrectInvalid2 {
    return "You are correct!  Row $_[0] shows that the argument is invalid!  On this row of the truth table, the premises of the argument are true and the conclusion false. (There are other invalidating rows as well.)";
}

###
sub msg_CorrectInvalid1 {
    return "You are correct!  Row $_[0] shows that the argument is invalid!  On this row of the truth table, the premises of the argument are true and the conclusion false.";
}


###
sub msg_InvalidityNotShown {
    return "Row $_[0] does not demonstrate that the argument is invalid. For a row to demonstrate invalidity, the premises must all be true and the conclusion false in that row.";
}

###
sub msg_Unchecked {
    return "If you claim the argument is invalid, you must check at least one row of the truth table that demonstrates your claim.";
}

###
sub msg_CorrectValid {
    return "You are correct!  The argument is valid.  There is no row on which the premises are all true and the conclusion is false.";
}


###
sub msg_ATTValid {

    return "The abbreviated truth table shows that the argument is valid.  More exactly, the truth table shows that every truth value assignment to the statement letters that makes the conclusion false makes at least one of the premises false as well.";
}

###
sub msg_ATTValidWithExtraRows {
    my ($num1,$num2,@noninvalidating_user_tvas) = @_;
    my @redundant_tvas =
      &canonize_tvas(&find_redundant_tvas(@noninvalidating_user_tvas));
    my $redundant_tvas = join(' ,',@redundant_tvas);
    $redundant_tvas =~ s/(.*),$/$1/;
    $diff = $num1 - $num2;
    my $insert = "there is $diff unnnecessary row";
    my $insert2 = "there needs to be only one row that assigns truth values to the statement letters in the conclusion as follows";
    if ($diff > 1) {
	$insert = "there are $diff unnnecessary rows";
	my $insert2 = "there needs to be only one row for each of the following ways of assigning truth values to the statement letters in the conclusion";
    }
    return "CORRECT: The abbreviated truth table correctly shows that the argument is <em>valid</em> by demonstrating that there is no way to make the conclusion false and all of the premises true.  <p>However, $insert in the truth table; more specifically, $insert2 -- $redundant_tvas).  The reason for this is that, if the assignment of truth values to the statement letters in the conclusion in a given row forces one of the premises to be false, then that premise will be false in any other row that assigns the same truth values to the statement letters in the conclusion.  Hence, only one such row is necessary."
}

###
sub msg_InvalidATTDeclaredValid {
    my $row_num = shift;
    return "Row $row_num shows that the argument is invalid, as the premises are true and the conclusion false in that row.  Moreover, the invalidating truth value assignment implicit in that row was correctly identified.  However, the argument was incorrectly declared to be <em>valid</em>."
}

###
sub msg_ValidATTDeclaredInvalid {
    return "You indicated that the argument was invalid but your abbreviated truth table shows that there is no row on which the premises are true and the conclusion false."
}

###
sub msg_BogusSlash {
    my ($wff,$row_num,$wff_type) = @_;
    my $pretty_wff = &prettify($wff);
    my $tv = "T";
    my $foo = 'the conclusion of the argument in that row';
    if ($wff_type eq 'conclusion') {
	$tv = "F";
	$foo = 'it';
    }
    return "The truth values assigned to the $wff_type \'<tt>$pretty_wff</tt>\' in Row $row_num include a slash, indicating that you were not able consistently to assign it the value \'<tt>$tv</tt>\' given the truth values assigned to the statement letters occurring in $foo.  However, this is not the case."
}

###
sub msg_NotValid {
    return "The argument is not valid -- there is at least one row of the truth table on which the premises are true and the conclusion false."
}

###
sub msg_CheckedInValidArg {
    return "You have asserted that the argument is valid, but you have also checked one or more rows.  In the truth table for an argument marked as valid, every row should be unchecked, as a checked row is supposed to be one that shows that the argument is <em>invalid</em>.";
}

###
sub msg_Incomplete {
    return "You are missing a truth value in Row $_[0] (and perhaps elsewhere).  There must be a column of truth values (<tt>T</tt>\'s and <tt>F</tt>\'s in upper case) entered below every logical operator that occurs in the argument and below every atomic sentence that occurs as a premise or as the conclusion -- and only below those elements of the argument.  In particular, there should be nothing beneath the atomic <em>parts</em> of the compound statements in the argument.";
}

###
sub msg_TooManyTVs {
    return "You have too many truth values in Row $_[0].  There should be a column of truth values (T\'s and F\'s in upper case) entered below every connective and atomic statement that occurs in the argument, but no where else.";
}
###
sub msg_IncorrectTV {
    return "The assignment of \"<tt>$_[0]</tt>\" to the WFF \"<tt>$_[1]</tt>\" in Row $_[2] is not correct.";
}

###
sub msg_IncorrectSubwffTV {
    return "The assignment of \"<tt>$_[0]</tt>\" to the subWFF \"<tt>$_[1]</tt>\" of the WFF \"<tt>$_[2]</tt>\" in Row $_[3] is not correct.";
}

###
sub msg_SlashAssignedToConclusion {
    return "A slash has been assigned to the conclusion of the argument, or to one of its components.  In Layman's system of abbreviated truth tables, one determines the validity or invalidity of an argument by first assigning <tt>F</tt> to a conclusion and, given that, appropriate truth values to its components, if possible.  (This will always be possible in these exercises.)  One then attempts consistently to assign true to all the premises.  Slashes therefore should only occur beneath connectives occurring in premises."
}

###
sub msg_IncorrectlyMarkedValid {
    return "Argument was incorrectly identified as valid! " .
      "(<tt>$ith_tva_string_formatted</tt> is invalidating.)";
}

###
sub msg_Invalidating {
    return "<tt>$user_invalidating_tva</tt> is an invalidating assignment."
}

###
sub msg_NotInvalidating {
    return "<tt>$user_invalidating_tva</tt> is not an invalidating assignment!"
}

###
sub msg_NoInvalidatingAssignment {
    return "Argument was judged invalid, but no invalidating truth value assignment was specified."
}

###
sub msg_InvAssignmentNotProperForm {
    return "Invalidating assignment appears not to be of the proper form, viz., \"$_[0]\", where either \"T\" or \"F\" fills the blanks.  Invalidating assignment submitted: $_[1]."
}

###
sub msg_NotEnoughAtoms {
    return "There are not enough statement letters in the invalidating assignment. Statement letters in argument: <tt>$_[0]</tt>; statement letters in the assignment: <tt>$_[1]</tt>."
}

###
sub msg_TooManyAtoms {
    return "There are too many statement letters in the invalidating assignment. Statement letters in argument: $_[0]; statement letters in the assignment: $_[1]."
}

###
sub msg_DifferentAtoms {
    return "The invalidating assignment contains statement letters that do not occur in the argument.  Statement letters in argument: $_[0]; statement letters in the assignment: $_[1]."
}

###
sub msg_ValidWithGarbage {
    return "=== <b>WARNING</b> === The following information was entered after the evaluation of \"valid\":\n <blockquote>\n$_[0]\n</blockquote>\nAs it does not appear to be a truth value assignment (which would indicate a misunderstanding of the material) it has been ignored in the grading.";
}

###
sub msg_InappropriateInvAssignment {
    return "Argument was judged to be valid, but an invalidating assignment -- $_[0] -- appears to have been entered as well.";
}

###
sub msg_NoEvalGiven {
    return "No evaluation (\"Valid\"/\"Invalid\") given!";
}

###
sub msg_FoundSomeGarbage {
    return "=== WARNING === Some extra information was ignored after the invalidating assignment, viz.: $_[0]\n";
}


1;
