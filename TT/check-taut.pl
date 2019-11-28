#!/usr/bin/perl -w

##########################################################################
### The TT itself has already been validated for correctness when this ###
### routine is called.  Hence, we just need to extract the column of   ###
### truth values beneath the main connective in the wff.  This is done ###
### by counting the number N of connectives in the LHS of the wff.  We ###
### then simply extract the N+1th TV from each row and determine the   ###
### logical status of the wff accordingly.                             ###
##########################################################################

sub check_taut {

    local $att = $POL::tt;  # Needed for &pol_template to get the user's TT to display
    $att =~ s/\n\n+/\n/g;
    my $print_tt = "yes";
    my $probref = "$POL::exercise "."Problem $POL::problem_num" if $POL::exercise;
    my $logstuff = "$POL::tt\n\n";
    my $wff = $POL::wff;
    my $action = $POL::action;

    my $num_lhs_connectives = 0;
    unless (&wff($wff) =~ /neg/) {
        my $paren_wff = $wff;
        $paren_wff = "($wff)" unless &iswff($paren_wff);
        $num_lhs_connectives = &count_connectives(&lhs($paren_wff));
    }

    # Put the calculated TVs in a single string WITH linefeeds
    my $tvs_assigned_to_wff = $POL::tt_rows;
    $tvs_assigned_to_wff =~ s/[ \t]//g;
    $tvs_assigned_to_wff =~ s/.*?\|(.*?)$/$1/mg;

    #find the TVs under the main connective in each row
    $tvs_assigned_to_wff =~ s/[TF]{$num_lhs_connectives}([TF]).*?$/$1/mg;

    $wff_status = "contingent";
    $wff_status = "taut"
      if $tvs_assigned_to_wff !~ /F/;
    $wff_status = "contra"
	if $tvs_assigned_to_wff !~ /T/;

    start_polpage();


    if ($action eq "Tautology") {
        if ($wff_status eq "taut") {
            &pol_template($head_CorrectTautology,
                          &msg_CorrectTautology($wff),
                          $probref,
                          "display");
            &bye_bye();
        }
	&pol_template($head_NotATautology,
		      &msg_NotATautology($wff),
		      $probref,
		      '&taut_contra_or_contingent($POL::tt,1)');
	&bye_bye();
    }

    if ($action eq "Contradiction") {
        if ($wff_status eq "contra") {
            &pol_template($head_CorrectContra,
                          &msg_CorrectContra($wff),
                          $probref,
                          "display");
            &bye_bye();
        }

	&pol_template($head_NotAContra,
		      &msg_NotAContra($wff),
		      $probref,
		      '&taut_contra_or_contingent($POL::tt,1)');
	&bye_bye();
    }

    if ($action eq "Contingent") {
        if ($wff_status eq "contingent") {
            &pol_template($head_CorrectContingent,
                          &msg_CorrectContingent($wff),
                          $probref,
                          "display");
	    &bye_bye();
        }

	&pol_template($head_NotContingent,
		      &msg_NotContingent($wff),
		      $probref,
		      '&taut_contra_or_contingent($POL::tt,1)');
	&bye_bye();
    }
}


1;
