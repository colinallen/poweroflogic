#!/usr/bin/perl -w

require "../lib/header.pl";

###

sub check_validity {
    
    $debug=0;
    $nomail=0;
    local @invalidating;
    local @user_tvs = @POL::user_tvs;
    local $dashes = $POL::dashes;
    local @invalidating_rows;
    local @checked=();
    local $probref = "$POL::exercise "."Problem $POL::problem_num" if $POL::exercise;
    local $logstuff = "$POL::tt\n\n";
    local @sequent = split(/ /,$POL::seq);
    local $num_rows = $POL::num_rows;
#    local $att = &cleanup($POL::tt);
    local $att = $POL::pretty_tt;

    &start_polpage();

    for ($i=0;$i<$POL::num_rows;$i++) {
	my @foo;
	push(@checked,$i) if $cgi->param("row_$i") eq "checked";
	for $fla (@sequent) {  # push tv's of wffs in sequent in row $i onto @foo
	    push(@foo,$cgi->param("vbar_$i" . "_" . "$fla"));
	}	    
	if (&invalidating(@foo)) {  # see if it's invalidating
	    push(@invalidating_rows,$i);
	    next;
	}
	next;
    }
	
    if ($POL::action eq "Valid") {
	
      CASE: {
	  if (@checked) {
	      $logstuff .= "Checked rows (add 1):  @checked\n" . $head_CheckedInValidArg;
	      &pol_template($head_CheckedInValidArg,
			    &msg_CheckedInValidArg,
			    $probref,
			    '&valid_or_invalid($POL::tt,$POL::vbar_string,1)');
#	      &bye_bye("cmenzel",$logstuff);
	      }
	  if (@invalidating_rows) {
	      $logstuff .= &msg_NotValid;
	      &pol_template($head_NotValid,
			    &msg_NotValid,
			    $probref,
			    '&valid_or_invalid($POL::tt,$POL::vbar_string,1)');
#	      &bye_bye("cmenzel",$logstuff);
	  }
      }
	&pol_template($head_CorrectValid,
		      &msg_CorrectValid,
		      $probref,
		      'display');
	$logstuff .= &msg_CorrectValid;
    	&bye_bye();
    }
	
    if (!@checked) {
	$logstuff .= &msg_Unchecked;
	&pol_template($head_Unchecked,
		      &msg_Unchecked,
		      $probref,
		      '&valid_or_invalid($POL::tt,$POL::vbar_string,1)');
	&bye_bye();
#	&bye_bye("cmenzel",$logstuff);
    }

  ROWNUMBER:  # Tests to see that the checked rows are all invalidating.
    foreach $i (@checked) {
	foreach $j (@invalidating_rows) {
	    if ($i==$j) {
		next ROWNUMBER;
	    }
	}
	$logstuff .= "Checked rows (add 1): @checked\n" . &msg_InvalidityNotShown($i+1);
	&pol_template($head_InvalidityNotShown,
		      &msg_InvalidityNotShown($i+1),
		      $probref,
		      '&valid_or_invalid($POL::tt,$POL::vbar_string,1)');
	&bye_bye();
    }

# Otherwise all the checked rows are invalidating.  Just need to get the grammar
# right in the various success messages; 

    if (@checked == 1) {  # "Correct" msg when one or more rows checked

      CASE1: {
	    &pol_template($head_CorrectInvalid1,
			  &msg_CorrectInvalid1($checked[0]+1),
			  $probref,
			  'display'),
	    $logstuff .= &msg_CorrectInvalid1($checked[0]+1),
	    last CASE1 
		if @checked eq @invalidating_rows;
	    &pol_template($head_CorrectInvalid2,
			  &msg_CorrectInvalid2($checked[0]+1),
			  $probref,
			  '&valid_or_invalid($POL::tt,$POL::vbar_string,1)');
	    $logstuff .= &msg_CorrectInvalid2($checked[0]+1);
	}
    } else {
	my $rows_checked;     
	$last = pop(@checked);
	$last++;
	if (@checked == 1) {  
	    $rows_checked = $checked[0]+1;
	} else {              
	    foreach $num (@checked) {
		$rows_checked .= $num+1 . ", ";
	    }
	}
      CASE2: {
	    &pol_template($head_CorrectInvalid3,
			  &msg_CorrectInvalid3($rows_checked,$last),
			  $probref,
			  'display'),
	    $logstuff .= &msg_CorrectInvalid3($rows_checked,$last),
	    last CASE2 
		if @checked+1 == @invalidating_rows;
	    &pol_template($head_CorrectInvalid4,
			  &msg_CorrectInvalid4($rows_checked,$last),
			  $probref,
			  '&valid_or_invalid($POL::tt,$POL::vbar_string,1)');
	    $logstuff .= &msg_CorrectInvalid4($rows_checked,$last);
	}
    }
    &bye_bye("cmenzel",$logstuff);
}

    
###

sub invalidating {

    return 0 if pop eq "T";
    while (@_) {
	return 0 if pop eq "F";
    }
    return 1;
}	

1;
