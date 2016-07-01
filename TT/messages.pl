#!/usr/bin/perl -w

$head_Incomplete = "<h1>Your truth table is incomplete!</h1>";
$head_TooManyTVs = "<h1>Your truth table is incorrect!</h1>";
$head_IncorrectSubwffTV = "<h1>Incorrect truth value!</h1>";
$head_IncorrectTV = "<h1>Incorrect truth value!</h1>";
$head_CheckedInValidArg = "<h2>Can't have checked rows in a valid argument!</h2>";
$head_NotValid = "<h1>Argument is not valid!</h1>",
$head_CorrectValid = "<h1>Argument is valid!</h1>";
$head_ATTValid = "<h1>Correct!  Argument is valid!</h1>";
$head_ATTValidWithExtraRows = "<h1>Correct!  Argument is valid!</h1>";
$head_ATTInvalidButtonPressed = "<h2>No invalidating truth value assignment!</h2>";
$head_ATTValidButtonPressed = "<h1>Wrong button pushed?</h1>";
$head_BogusSlash = "<h1>Illegitimate slash /!</h1>";
$head_Unchecked = "<h1>No rows checked!</h1>";
$head_InvalidityNotShown = "<h1>Invalidity not demonstrated!</h1>";
$head_CorrectInvalid1 = "<h1>Correct!</h1>";
$head_CorrectInvalid2 = "<h1>Correct!</h1>";
$head_CorrectInvalid3 = "<h1>Correct!</h1>";
$head_CorrectInvalid4 = "<h1>Correct!</h1>";
$head_PremiseNotWff = "<h1>Non-WFF in premises!</h1>";
$head_RYOPremiseNotWff = "<h1>Non-WFF in premises!</h1>";
$head_ConclusionNotWff = "<h1>Conclusion is not a WFF!</h1>";
$head_NoConclusion = "<h1>No conclusion!</h1>";
$head_InvalidChar = "<h1>Invalid character!</h1>";
$head_InvalidATTChar = "<h1>Invalid character!</h1>";
$head_MissingTV = "<h1>Missing truth value!</h1>";
$head_NoVertBar = "<h1>Vertical bar missing!</h1>";
$head_NoATTVertBar = "<h1>Vertical bar missing!</h1>";
$head_TooManyVertBars = "<h1>Too many vertical bars!</h1>";
$head_TooManyATTVertBars = "<h1>Too many vertical bars!</h1>";
$head_MungedTVA = "<h1>Corrupted truth value assignment!</h1>";
$head_TooManyRows = "<h1>Too many rows!</h1>";
$head_NotEnoughRows = "<h1>Not enough rows!</h1>";
$head_CannotFutzWithArg = "<h1>Argument has been altered!</h1>";
$head_CannotFutzWithATTArg = "<h1>Argument has been altered!</h1>";
$head_CannotFutzWithATTDashes = "<h1>Dashes have been altered!</h1>";
$head_InconsistentTVA = "<h2>Inconsistent truth value assignments!</h2>";
$head_NothingEntered = "<h1>No argument entered!</h1>";
$head_NoTherefore = "<h1>No :. symbol!</h1>";
$head_NoTVA ="<h2>No truth value assignment given!</h2>";
$head_NoTVAValidPressed ="<h2>&ldquo;Valid&rdquo; indicated but no &lsquo;/&rsquo; in row!</h2>";
$head_NoTVA_InvalidPressed ="<h2>No truth value assignment given!</h2>";
$head_InappropriateTVA ="<h2>Inappropriate truth value assignment or mistaken &lsquo;/&rsquo;!</h2>";
$head_TooFewTVsInTVA = "<h1>Incomplete truth value assignment!</h2>";
$head_TooManyTVsInTVA = "<h2>Too many truth values!</h2>";
$head_TooManyTVsInATTRow = "<h2>Too many truth values!</h2>";
$head_TooFewTVsInATTRow = "<h2>Not enough truth values!</h2>";
$head_TAssignedToConclusion = "<h2>&lsquo;<tt><font size=+1>T</font></tt>&rsquo; assigned to conclusion!</h2>";
$head_FAssignedToPremise = "<h2>&lsquo;<tt><font size=+1>F</font></tt>&rsquo; assigned to premise!</h2>";
$head_CorrectATTInvalid = "<h1>Correct! Argument is invalid!</h1>";
$head_CorrectExpATTInvalid = "<h1>Correct!</h1>";
$head_ValidityNotDemonstrated = "<h1>Validity not demonstrated!</h1>";
$head_ConflictingAssignments1 = "<h1>Conflicting truth value assignments!</h1>";
$head_ConflictingAssignments2 = "<h1>Conflicting truth value assignments!</h1>";
$head_BadNegation = "<h1>Incorrect truth value for a negation!</h1>";
$head_BadConjunction = "<h2>Incorrect truth value for a conjunction!</h2>";
$head_BadDisjunction = "<h2>Incorrect truth value for a disjunction!</h2>";
$head_BadConditional = "<h2>Incorrect truth value for a conditional!</h2>";
$head_BadBiconditional = "<h2>Incorrect truth value for a biconditional!</h2>";
$head_DuplicateRows = "<h1>Duplicate rows!</h1>";
$head_ValidConclusion = "<h2>Correct!  Argument is valid!</h2>";
$head_EmptyATT = "<h1>Truth table is empty!</h1>";
$head_BadSlash = "<h2>&lsquo;/&rsquo; not assigned to main logical operator!</h2>";
$head_CorrectTautology = "<h1>Correct!</h1>";
$head_NotATautology = "<h1>Not a tautology!</h1>";
$head_CorrectContra = "<h1>Correct!</h1>";
$head_NotAContra = "<h1>Not a contradiction!</h1>";
$head_CorrectContingent = "<h1>Correct!</h1>";
$head_NotContingent = "<h1>Not a contingent statement!</h1>";
$head_ItsATautologyAlright = "<h1>Correct!</h1>";
$head_SlashAssignedToConclusion = "<h1>Slash assigned to conclusion!</h1>";
$head_SlashAssignedToAtom = "<h1>Slash assigned to atom!</h1>";

###
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
    return "You have asserted that the WFF <p><center><tt>$pretty_wff</tt></center><p> is contingent.  However, a contingent statement is one that is true in at least one row of the truth table and false in at least one row.  This is not the case for this wff, so it is not contingent.  Please review the truth table and submit another answer."
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
    return "You have asserted that the WFF <p><center><tt>$pretty_wff</tt></center><p> is a contradiction.  However, it is true in at least one row, and so it is not the case that it is false regardless of the truth values assigned to the atomic statements that compose it.  So it cannot be a contradiction.  Try again."
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
    return "You have asserted that the WFF <p><center><tt>$pretty_wff</tt></center><p> is a tautology.  However, it is false in at least one row, and so it is not true regardless of the truth values assigned to the atomic statements that compose it.  So it cannot be a tautology.  Try again."
}

###
sub msg_CorrectTautology {
    my ($wff) = @_;
    my $pretty_wff = &prettify($wff);
    return "You are correct!  The WFF <p><center><tt>$pretty_wff</tt></center><p> has the truth value <tt>T</tt> in every row and is therefore a tautology; it is true regardless of the truth values assigned to the atomic statements that compose it."
}

###
sub msg_BadSlash {
    my ($row_num,$subwff,$wff_argtype,$wff) = @_;
    my $pretty_subwff = &prettify($subwff);
    my $pretty_wff = &prettify($wff);

    return "In Row $row_num, a slash / has been assigned to a statement letter or logical operator in the subWFF <tt>$pretty_subwff</tt> of the $wff_argtype <tt>$pretty_wff</tt>.  The presence of a slash in your abbreviated truth table indicates that you believe that you were unable to make the conclusion false on the truth values you assigned to its statement letters -- as required if a row is to show that the argument is invalid.  However, your inability to do so should be indicated by a slash only beneath the main logical operator of the conclusion itself; there should be no slash beneath any other of its components.  Correct this and try again."
	if $wff_argtype eq "conclusion";
    return "In Row $row_num, a slash / has been assigned to a statement letter or logical operator in the subWFF <tt>$pretty_subwff</tt> of the $wff_argtype <tt>$pretty_wff</tt>.  The presence of a slash in your abbreviated truth table indicates that you believe that you were unable to make <tt>$wff</tt> true given the truth values you assigned to the conclusion of the argument -- as required if a row is to show that the argument is invalid.  However, your inability to do so should be indicated by a slash only beneath the main logical operator of the premise itself; there should be no slash beneath any other of its components.  Correct this and try again."
}

###
sub msg_EmptyATT {
    return "Your truth table contains no rows. The only time such a truth table can count as complete is when the conclusion of the argument in question is a tautology.  For in that case, there is no way to make the conclusion false, as one must first attempt to do according to the abbreviated truth table method. But that is not the case here. Hence, your truth table is incomplete. Try again."
}

###
sub msg_ValidConclusion {
    return "As you hopefully have seen, even though your truth table has no rows filled in beneath the argument, it nonetheless shows that the argument is valid. The reason for this is that the conclusion of the argument is a tautology (see Section 7.5); there is no way to make it false. Thus, an empty truth table for an argument with a tautologous conclusion represents all the ways there are (namely, none) of making the conclusion false -- and hence all the ways there are to make the conclusion false and the premises true! Thus, under these circumstances (and only under these) an empty abbreviated truth table indicates that the argument is valid."
}


###
sub msg_DuplicateRows {
    my ($i,$j) = @_;
    return "Rows $i and $j are identical in your abbreviated truth table; please delete one of them."
}

###
sub msg_TooManyTVsInATTRow {
    my ($row_num) = @_;
    return "You have entered too many truth values below the argument in Row $row_num.  There should be exactly one truth value (or slash &lsquo;/&rsquo;) for each statement letter and connective in the argument.  Delete the extraneous truth values and try again."
}

###
sub msg_TooFewTVsInATTRow {
    my ($row_num) = @_;
    return "You have not entered enough truth values below the argument in Row $row_num.  There should be exactly one truth value for each statement letter and connective in the argument.  Add the appropriate truth values and try again."
}

###
sub msg_BadBiconditional {
    my ($bicond,$bicond_tv,$lhs,$rhs,$row_num) = @_;
    my $pretty_bicond = &prettify($bicond);
    my $pretty_lhs = &prettify($lhs);
    my $pretty_rhs = &prettify($rhs);
    return "The biconditional statement &nbsp;<tt>$pretty_bicond</tt>&nbsp; has been assigned &nbsp;<tt>$bicond_tv</tt>&nbsp; in Row $row_num, but its immediate components &nbsp;<tt>$pretty_lhs</tt>&nbsp; and &nbsp;<tt>$pretty_rhs</tt>&nbsp; have been assigned &nbsp;<tt>$lhs_tv</tt>&nbsp; and &nbsp;<tt>$rhs_tv</tt>, respectively.  Correct this and try again.";
}

###
sub msg_BadConditional {
    my ($cond,$cond_tv,$lhs,$rhs,$row_num) = @_;
    my $pretty_cond = &prettify($cond);
    my $pretty_lhs = &prettify($lhs);
    my $pretty_rhs = &prettify($rhs);
    return "The conditional statement &nbsp;<tt>$pretty_cond</tt>&nbsp; has been assigned &nbsp;<tt>$cond_tv</tt>&nbsp; in Row $row_num, but its immediate components &nbsp;<tt>$pretty_lhs</tt>&nbsp; and &nbsp;<tt>$pretty_rhs</tt>&nbsp; have been assigned &nbsp;<tt>$lhs_tv</tt>&nbsp; and &nbsp;<tt>$rhs_tv</tt>, respectively.  Try again.";
}

###
sub msg_BadDisjunction {
    my ($disj,$disj_tv,$lhs,$rhs,$row_num) = @_;
    my $pretty_disj = &prettify($disj);
    my $pretty_lhs = &prettify($lhs);
    my $pretty_rhs = &prettify($rhs);
    return "The disjunction &nbsp;<tt>$pretty_disj</tt>&nbsp; has been assigned &nbsp;<tt>$disj_tv</tt>&nbsp; in Row $row_num, but its immediate components &nbsp;<tt>$pretty_lhs</tt>&nbsp; and &nbsp;<tt>$pretty_rhs</tt>&nbsp; have been assigned &nbsp;<tt>$lhs_tv</tt>&nbsp; and &nbsp;<tt>$rhs_tv</tt>, respectively.  Correct this and try again.";
}

###
sub msg_BadConjunction {
    my ($conj,$conj_tv,$lhs,$rhs,$row_num) = @_;
    my $pretty_conj = &prettify($conj);
    my $pretty_lhs = &prettify($lhs);
    my $pretty_rhs = &prettify($rhs);
    return "The conjunction &nbsp;<tt>$pretty_conj</tt>&nbsp; has been assigned &nbsp;<tt>$conj_tv</tt>&nbsp; in Row $row_num, but its immediate components &nbsp;<tt>$pretty_lhs</tt>&nbsp; and &nbsp;<tt>$pretty_rhs</tt>&nbsp; have been assigned &nbsp;<tt>$lhs_tv</tt>&nbsp; and &nbsp;<tt>$rhs_tv</tt>, respectively.  Correct this and try again.";
}

###
sub msg_BadNegation {
    my ($neg,$neg_tv,$rhs,$row_num) = @_;
    my $pretty_neg = &prettify($neg);
    my $pretty_rhs = &prettify($rhs);
    return "<tt>$pretty_neg</tt> has been assigned <tt>$neg_tv</tt> in Row $row_num, but its immediate component <tt>$pretty_rhs</tt> has also been assigned <tt>$neg_tv</tt>.  Correct this and try again.";
}

###
sub msg_SlashAassignedToAtom {
    my ($wff,$row_num) = @_;
    return "An occurrence of the statement letter &nbsp;<tt>$wff</tt>&nbsp; has been assigned the &ldquo;inconsistent&rdquo; truth value &lsquo;<tt>/</tt>&rsquo;.  All occurrences of statement letters should uniformly be assigned either a &nbsp;<tt>T</tt>&nbsp; or an &nbsp;<tt>F</tt>&nbsp;; a &lsquo;<tt>/</tt>&rsquo; should only occur under the main logical operator of a wff, indicating that you were not able consistently to assign a single truth value to that wff.  Assign the occurrence of &nbsp;<tt>$wff</tt>&nbsp; in question a truth value and resubmit your answer."
}


###
sub msg_ConflictingAssignments2 {
    my ($wff,$wff_tv,$row_num,$exp_att_context) = @_;
    my $tv_of_wff_in_tva_area = 'T';
    $tv_of_wff_in_tva_area = 'F' if $wff_tv eq 'T';
    my $wff_type = 'statement letters';
    $wff_type = 'wffs' if $exp_att_context;
    return "In Row $row_num, the assignment of the truth value &nbsp;<tt>$tv_of_wff_in_tva_area</tt>&nbsp; to the $wff_type &nbsp;<tt>$wff</tt>&nbsp; in the truth value assignment area (i.e., the area to the left of the vertical bar &nbsp;&lsquo;<tt>|</tt>&rsquo;&nbsp;) conflicts with the value of &nbsp;<tt>$wff_tv</tt>&nbsp; that is assigned to one or more of the occurrences of &nbsp;<tt>$wff</tt> in the argument in that row.  Make sure that you have assigned truth values to the $wff_type in the truth value assignment area in each row consistently with the assignments they receive in the rest of the row."
}

###
sub msg_ConflictingAssignments1 {
    my ($wff,$row_num) = @_;
    return "The statement letter (or atomic sentence) &nbsp;<tt>$wff</tt>&nbsp; has been assigned both &nbsp;<tt>T</tt>&nbsp; and &nbsp;<tt>F</tt>&nbsp; in Row $row_num.  Make sure that you have assigned truth values to each occurrence of every sentence letter consistently in each row of your abbreviated truth table."
}

###
sub msg_ValidityNotDemonstrated {
    return "Although none of the rows in your abbreviated truth table have shown that the argument is invalid (since in none of them are the premises true and the conclusion false), as the truth table stands, it does not demonstrate that the argument is valid either, because there are still more truth value assignments that make the conclusion false.  Remember that, to show that the argument is valid, your truth table must demonstrate that, on <i>every</i> truth value assignment that makes the conclusion false, at least one of the premises is false as well (that is, that there is no way to make the conclusion false and the premises true).  (<b>NOTE:</b> The relevant truth value assignments that remain might assign the same truth values to the statement letters in the conclusion as a true value assignment you've already considered &mdash; the difference might be only on the truth values assigned to one or more statement letters that occur only in the premises.)  <p>So begin adding rows for other truth value assignments that make the conclusion false.  If, and only if, you test all of those truth value assignments without finding a row with all true premises, you will have shown the argument to be valid."
}

###
sub msg_CorrectATTInvalid {
    my ($row_num,$ith_tva) = @_;
    my $last_atom_tva_pair = $ith_tva;
    $last_atom_tva_pair =~ s/.*(\w)([TF])$/\<tt\>$1\<\/tt\> is assigned \<tt\>$2\<\/tt\>,\&nbsp\;/;
    my $first_atom_tva_pairs = $ith_tva;
    $first_atom_tva_pairs =~ s/(.*)\w[TF]$/$1/;
    $first_atom_tva_pairs =~ s/(\w)([TF])/\<tt\>$1\<\/tt\> is assigned \<tt\>$2\<\/tt\>,/g;

    # $num counts how many atom/TV combinations there are
    my $num = $first_atom_tva_pairs =~ tr/A-Z/A-Z/;

    # removes final comma if there's only two sentence letters
    $first_atom_tva_pairs =~ s/,\s*$// if $num == 2;

    return "Your abbreviated truth table is correct!  Row $row_num shows that the premises are all true and the conclusion is false when statement letter $first_atom_tva_pairs and $last_atom_tva_pair so you have shown that the argument is invalid!"
}

###
sub msg_CorrectExpATTInvalid {
    my ($row_num,$translated_ith_tva) = @_;
    my $last_wff_tva_pair = $translated_ith_tva;
    $last_wff_tva_pair =~ s/.*([A-Z][a-z])([TF])$/\&nbsp\;\<tt\>$1\<\/tt\> is assigned \&nbsp\;\<tt\>$2\<\/tt\>,\&nbsp\;/;
    my $first_wff_tva_pairs = $translated_ith_tva;
    $first_wff_tva_pairs =~ s/(.*)[A-Z][a-z][TF]$/$1/;
    $first_wff_tva_pairs =~ s/([A-Z][a-z])([TF])/\&nbsp\;\<tt\>$1\<\/tt\> is assigned \&nbsp\;\<tt\>$2\<\/tt\>,/g;

    my $num = $first_wff_tva_pairs =~ tr/A-Z/A-Z/;  # counts how many WFF/TV combinations there are
    $first_wff_tva_pairs =~ s/,\s*$// if $num == 2; # removes final comma if there's only two sentence letters

    return "Your abbreviated truth table is correct.  Row $row_num shows that the premises are all true and the conclusion is false when the WFF $first_wff_tva_pairs and $last_wff_tva_pair so the argument is invalid."
}

###
sub msg_FAssignedToPremise {
    my ($row_num,$premise) = @_;
    my $pretty_premise = &prettify($premise);
    return "You have assigned &nbsp;<tt>F</tt>&nbsp; to the premise &nbsp;<tt>$pretty_premise</tt>&nbsp; in Row $row_num.  An argument is invalid only if the conclusion can be false when all the premises are true.  Thus, invalidity cannot be shown by a row in an abbreviated truth table unless the premises are all assigned &nbsp;<tt>T</tt>, i.e., unless every premise is assumed to be true.";
}

###
sub msg_TAssignedToConclusion {
    local ($row_num,$conclusion) = @_;
    my $pretty_conclusion = &prettify($conclusion);
    return "You have assigned &nbsp;<tt>T</tt>&nbsp; to the conclusion <tt>$pretty_conclusion</tt> in Row $row_num.  An argument is invalid only if the conclusion can be false when all the premises are true.  Thus, invalidity cannot be shown by a row in an abbreviated truth table unless the conclusion is assigned &nbsp;<tt>F</tt>, i.e., unless the conclusion is assumed to be false.";
}

###
sub msg_InappropriateTVA {
    my ($row_num) = @_;
    return "You have assigned truth values to the statment letters of the argument in the truth value assignment area (i.e., the area to the left of the vertical bar &lsquo;<tt>|</tt>&rsquo;) in Row $row_num, but you have also indicated by the presence of a slash &lsquo;<tt>/</tt>&rsquo; beneath a logical operator that a consistent truth value assignment is not possible in this row.  If a consistent truth value assignment is not possible, remove all &nbsp;<tt>T</tt>'s and <tt>F</tt>'s from the truth value assignment area.  Otherwise, replace the slash with an appropriate truth value."
}

###
sub msg_NoTVA_ValidPressed {
    my ($row_num) = @_;
    return "You have pressed the &ldquo;Valid&rdquo; button, indicating you believe that there is no truth value assignment that makes the premises true and the conclusion false.  However, there is no &lsquo;/&rsquo; beneath the connective of any premise in Row $row_num, which suggests that you <i>have</i> found a truth value assignment that makes the premises true and the conclusion false, and hence that the argument is invalid.  Check to see if this is the case, and enter the appropriate truth values under the sentence letters that occur to the left of the argument in the table."
}

###
sub msg_NoTVA_InvalidPressed {
    my ($row_num) = @_;
    return "By pressing the &ldquo;Invalid&rdquo; button you have indicated that you have found a consistent way to assign truth values to the components of the argument that makes its premises true and its conclusion false, but you have not provided a truth value assignment in the area to the left of the vertical bar &lsquo;<tt>|</tt>&rsquo; in Row $row_num."
}

###
sub msg_NoTVA {
    my ($row_num) = @_;
    return "No truth value assignment has been provided in the area to the left of the vertical bar '<tt>|</tt>' in Row $row_num."
}

sub msg_TooManyTVsInTVA {
    my ($row_num) = @_;
    return "There are more truth values than there are sentence letters in the truth value assignment area (i.e., the area consisting of the columns to the left of the vertical bar &lsquo;<tt>|</tt>&rsquo; in Row $row_num.  Be sure that there is exactly one &nbsp;<tt>T</tt> or &nbsp;<tt>F</tt> beneath each sentence letter in this area.  (And be sure that your vertical bars are lined up properly in a single column.)"
}

###
sub msg_TooFewTVsInTVA {
    my ($row_num) = @_;
    return "The truth value assignment given in Row $row_num to the statement letters (i.e., the ones in the list to the left of the argument) is incomplete; you have truth values in the columns beneath some, but not all, of those sentence letters."
}

###
sub msg_NoTherefore {
    return "The space provided is for entering an argument.  Hence, it must contain a &ldquo;therefore&rdquo; symbol (i.e., :.) that separates the premises of the argument from the conclusion."
}

###
sub msg_NothingEntered {
    return "Please enter an argument in the space provided."
}

###
sub msg_InconsistentTVA {
    return "You have assigned different truth values to the statement letter &lsquo;<tt>$_[0]</tt>&rsquo; in Row $_[1].  Truth values must be assigned uniformly in each row to all occurrences of the same sentence letter.  Correct this and resubmit your answer."
}

###
sub msg_CannotFutzWithArg {
    return "The argument in the problem you are working on has been altered.  It should be
<center>
<pre>
$_[1]
</pre>
</center>
but it has been altered so that it looks like this:
<center>
<pre>
$_[2]
</pre>
</center>
Please restore the original argument.  You may wish to copy the argument from this page and paste it into the previous page.  If you wish to experiment with truth tables, go to the option on the starting menu for creating your own truth table."
}

###
sub msg_CannotFutzWithATTArg {
    my ($original_line1,$user_line1) = @_;
    return "The line containing the argument in the problem you are working on has been altered in some important way (other than simply the addition or removal of spaces).  To ensure your abbreviated truth table is evaluated correctly, the first two lines of your abbreviated truth table should not be altered in any way.  The original line looked like this:
<pre>
$original_line1
</pre>
but it has been altered so that it looks like this:
<pre>
$user_line1
</pre>
Please restore the original argument.  You may wish to copy the argument from this page and paste it into the previous page."
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
</pre>
Please restore the original argument.  You may wish to copy the argument from this page and paste it into the previous page."
}

###
sub msg_NotEnoughRows {
    return "There are not enough rows in your truth table.  You have $_[0] but there should be $_[1].  Correct this and resubmit your answer."
}

###
sub msg_TooManyRows {
    return "There are too many rows in your truth table.  There should only be $_[0].  Delete the extraneous rows and resubmit your answer."
}

###
sub msg_MungedTVA {
    return "The truth value assignment in Row $_[0] has become corrupted.  It should look like this: &ldquo;<tt>$_[1]</tt>&rdquo;.  Yours looks like this: &ldquo;<tt>$_[2]</tt>&rdquo;.  Repair this and resubmit your answer."
}

###
sub msg_TooManyVertBars {
    return "There are too many vertical bars in Row $_[0].  There should be only the vertical bar that separates the preassigned truth values for the statement letters from the truth values that you enter beneath the argument.  Please delete any extraneous vertical bars."
}

###
sub msg_TooManyATTVertBars {
    my ($row_num) = @_;
    return "There are too many vertical bars in Row $row_num.  There should be only the vertical bar that separates the truth value assignment area for the list of statement letters to the left of the argument from the truth values that you enter beneath the statement letters and connectives in the argument.  Please delete any extraneous vertical bars."
}

###
sub msg_TooManySlashes {
    return "There are too many forward slashes in Row $_[0].  Actually, I'm not sure about this...."
}

###
sub msg_NoVertBar {
    return "The vertical bar that separates the preassigned truth values for the statement letters from the truth values that you enter is missing in Row $_[0].  Please replace it."
}

###
sub msg_NoATTVertBar {
    my ($row_num) = @_;
    return "In Row $row_num, the verticfal bar that separates the truth value assignment area for the list of statement letters to the left of the argument from the truth values that you enter beneath the statement letters and connectives in the argument is missing.  Please replace it."
}

###
sub msg_MissingTV {
    my ($row_num) = @_;
    return "A truth value is missing from the truth value assignment in Row $row_num.  Return replace it."
}

###
sub msg_InvalidChar {
    my ($row_num) = @_;
    return "You have typed an invalid character in Row $row_num.  Please delete it.  (Only the truth values &lsquo;<tt>T</tt>&rsquo; and &lsquo;<tt>F</tt>&rsquo; (upper case), the vertical bar &lsquo;<tt>|</tt>&rsquo; and spaces should appear in each row.)"
}


###
sub msg_InvalidATTChar {
    my ($row_num) = @_;
    return "You have typed an invalid character in Row $row_num.  Please delete it.  (Only the truth values &lsquo;<tt>T</tt>&lsquo; and &lsquo;<tt>F</tt>&lsquo; (upper case), the vertical bar &lsquo;<tt>|</tt>&rsquo;, spaces, and possibly a forward slash &lsquo;<tt>/</tt>&rsquo; should appear in each row.)"
}


###
sub msg_ConclusionNotWff {
    return "The conclusion of your argument is not a wff.";
}

###
sub msg_NoConclusion {
    return "Your argument contains no conclusion.  Please add a conclusion to your argument.";
}

###
sub msg_PremiseNotWff {
    return "Your argument contains a non-WFF among its premises.";
}

###
sub msg_RYOPremiseNotWff {
    my $premise = shift;
    return "<tt>$premise</tt> is not a WFF.  Did you remember to separate adjacent premises with a comma?";
}

###
sub msg_CorrectInvalid4 {
    return "You are correct!  Rows $_[0] and $_[1] show that the argument is invalid.  On these rows of the truth table, the premises of the argument are true and the conclusion false.  (There are other invalidating rows as well that you might try to find.)";
}

###
sub msg_CorrectInvalid3 {
    return "You are correct!  Rows $_[0] and $_[1] show that the argument is invalid.  On these rows of the truth table, the premises of the argument are true and the conclusion false.";
}

###
sub msg_CorrectInvalid2 {
    return "You are correct!  Row $_[0] shows that the argument is invalid!  On this row of the truth table, the premises of the argument are true and the conclusion false. (There are other invalidating rows as well that you might try to find.)\n";
}

###
sub msg_CorrectInvalid1 {
    return "You are correct!  Row $_[0] shows that the argument is invalid!  On this row of the truth table, the premises of the argument are true and the conclusion false.";
}


###
sub msg_InvalidityNotShown {
    return "Row $_[0] does not demonstrate that the argument is invalid. For a row to demonstrate invalidity, the premises must all be true and the conclusion false in that row.  Try again.";
}

###
sub msg_Unchecked {
    return "If you claim the argument is invalid, you must check at least one row of the truth table that demonstrates your claim.  Try again.";
}

###
sub msg_CorrectValid {
    return "You are correct!  The argument is valid.  There is no row on which the premises are all true and the conclusion is false.";
}


###
sub msg_ATTValid {
    return "You have shown that the argument is valid.  There is no row on which the premises are all true and the conclusion is false.";
}

###
sub msg_ATTValidWithExtraRows {
    my ($num1,$num2) = @_;
    $diff = $num1 - $num2;
    $num_extra_rows = chr($diff);
    return "You have shown that the argument is valid by showing that there is no way to make the conclusion false and all of the premises true."
	if $diff == 1;
    return "You have shown that the argument is valid by showing that there is no way to make the conclusion false and all of the premises true.  <p>However, you have $num_extra_rows unnecessary rows in your abbreviated truth table.  To see this, note that if the assignment of truth values to the statement letters in the conclusion in a given row forces one of the premises to be false, then that premise will be false in any other row that assigns the same truth values to the statement letters in the conclusion.  Hence, only one such row is necessary.  (Note that this does not mean that your answer is wrong, only that it could have been shown more directly.)"
}

###
sub OLDmsg_ATTValidWithExtraRows {
    my ($num1,$num2) = @_;
    $diff = $num1 - $num2;
    $num_extra_rows = chr($diff);
    return "You have shown that the argument is valid by showing that there is no way to make the conclusion false and all of the premises true.  <p>However, you have one unnecessary row in your abbreviated truth table.  To see this, note that if the assignment of truth values to the statement letters in the conclusion in a given row forces one of the premises to be false, then that premise will be false in any other row that assigns the same truth values to the statement letters in the conclusion.  Hence, only one such row is necessary.  (Note that this does not mean that your answer is wrong, only that it could have been shown more directly.)"
	if $diff == 1;
    return "You have shown that the argument is valid by showing that there is no way to make the conclusion false and all of the premises true.  <p>However, you have $num_extra_rows unnecessary rows in your abbreviated truth table.  To see this, note that if the assignment of truth values to the statement letters in the conclusion in a given row forces one of the premises to be false, then that premise will be false in any other row that assigns the same truth values to the statement letters in the conclusion.  Hence, only one such row is necessary.  (Note that this does not mean that your answer is wrong, only that it could have been shown more directly.)"
}

###
sub msg_ATTInvalidButtonPressed {
    return "You pressed the &ldquo;Invalid&rdquo; button, but you have provided no invalidating truth value assignment -- in none of the rows in your truth table are the premises true and the conclusion false.  Did you perhaps mean to press the &ldquo;Valid&rdquo; button instead?"
}

###
sub msg_ATTValidButtonPressed {
    return "You pressed the &ldquo;Valid&rdquo; button, but your abbreviated truth table contains a row in which the premises are true and the conclusion false -- in which case the argument is invalid.  Did you perhaps mean to press the &ldquo;Invalid&rdquo; button instead?"
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
    return "The truth values assigned to the $wff_type &nbsp;<tt>$pretty_wff</tt>&nbsp; in Row $row_num include a slash, indicating that you were not able consistently to assign it the value &nbsp;&lsquo;<tt>$tv</tt>&rsquo;&nbsp; given the truth values assigned to the statement letters occurring in $foo.  However, this is not the case.  Please replace the &lsquo;/&rsquo; with the appropriate truth value."
}

###
sub msg_NotValid {
    return "The argument is not valid -- there is at least one row of the truth table on which the premises are true and the conclusion false.  Try again."
}

###
sub msg_CheckedInValidArg {
    return "You have asserted that the argument is valid, but you have also checked one or more rows.  In the truth table for an argument marked as valid, every row should be unchecked, as a checked row is supposed to be one that shows that the argument is <em>invalid</em>.  Try again.";
}

###
sub msg_Incomplete {
    return "You are missing a truth value in Row $_[0] (and perhaps elsewhere).  Be sure you have a column of truth values (<tt>T</tt>s and <tt>F</tt>s in upper case) entered below every logical operator that occurs in the argument and below every atomic sentence that occurs as a premise or as the conclusion -- and only below those elements of the argument.  In particular, be sure you put nothing beneath the atomic <em>parts</em> of the compound statements in the argument.";
}

###
sub msg_TooManyTVs {
    return "You have too many truth values in Row $_[0].  Be sure you have a column of truth values (<tt>T</tt>s and <tt>F</tt>s in upper case) entered below every connective and every atomic statement that occurs as a premise or as the conclusion in the argument, but no where else. In particular, be sure you put nothing beneath the atomic <em>parts</em> of the compound statements in the argument."; 
    }

###
sub msg_IncorrectTV {
    return "Your assignment of \'<tt>$_[0]</tt>\' to the WFF <center><pre>$_[1]</pre></center> in Row $_[2] is not correct.  Correct this and resubmit your answer.";
}

###
sub msg_IncorrectSubwffTV {
    return "Your assignment of \'<tt>$_[0]</tt>\' to the subWFF <center><pre>$_[1]</pre></center> of the WFF <center><pre>$_[2]</pre></center> in Row $_[3] is not correct.  Correct this and resubmit your answer.";
}
###
sub msg_SlashAssignedToConclusion {
    return "A slash has been assigned to the conclusion of your argument, or to one of its components.  In Layman's system of abbreviated truth tables, one determines the validity or invalidity of an argument by first assigning <tt>F</tt> to a conclusion and, given that, appropriate truth values to its components, if possible.  (This will always be possible in these exercises.)  One then attempts consistently to assign true to all the premises.  Slashes therefore should only occur beneath connectives occurring in premises."
}
