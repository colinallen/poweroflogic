#!/usr/bin/perl -w
# grader-check-tt-form.pl -- Standalone TT form checker for use with grader.pl
#
# Takes two arguments: a sequent ($argument) and a TT ($answer).
# Checks only (1) the syntactic form of a TT (e.g., enough rows,
# correct number of truth values in each row, no inappropriate
# characters in any row, etc) and (2) the calculation of truth
# values in each row.
#
# To Do
# 1. Add flexibility -- count TT as correct if incorrect calculation
#    in an incidental row.
# 2. Need to check that atoms haven't been futzed with.
#
# Questions
# 1. Should we reject if an invalidating row has been entereed
# despite an evaluation of "valid"?  (Currrently, a warning is given
# but credit given if the argument is indeed valid.)


############
# Requires #
############

require "../lib/wff-subrs.pl";
require "../TT/extract_nth_subwff.pl";
require "../TT/make-tt-template.pl";
require "../TT/grader-messages.pl";


########################
##### MAIN ROUTINE #####
########################

&initialize;

&check_form;
&print_log and exit if !$result_form;

&check_tv_calc;
&print_log;

#######################
##### Subroutines #####
#######################

sub initialize {

    $argument = "";
    $answer = "";

    # Command line argument version
    ($argument,$answer) = @ARGV if @ARGV;

    # Got to get STDIN before requires when called by grader.pl
    if (!$argument) {
        $argument = <>;
        while (<>) {
            $answer .= $_;
        }
    }

    my $raw_argument = $argument;
    my $raw_answer = $answer;

    # Fix "therefore" sign if mysteriously munged by PageOut
    # This is probably no longer necessary

    $raw_argument =~ s/:\s*\./:. /;
    $raw_argument =~ s/\.\s*:/ .:/;
    $raw_answer =~ s/:\s*\./:. /;
    $raw_answer =~ s/\.\s*:/ .:/;

    $logstuff = "<p />\n<strong>Argument:</strong> <tt>$raw_argument</tt><br />\n";
    $logstuff .= "<strong>Truth Table Attempt:</strong>\n" .
      "<pre>\n" . $raw_answer . "</pre>\n";

    # Initialize some global vars

    $result_form = 0;
    $result_tv_calc = 0;
    $result_validity = 0;
    $result_invalidating_row = 0;
    $result = 0;

    $user_eval = "";
    $tt = "";

    my $first_line = "";
    for (split(/\n/,$answer)) {
	next if /^[-\s|]*$/;               # ignore blank lines and separator lines
	s/\s*//g;
	$first_line = $_ and next
	    if /:\.|\.:/;
	push @tt, $_;
    }

    chomp $argument;

    $tt = join "\n", sort {$b cmp $a} @tt;
#    print "\nTT: \n$tt\n\n";

    $tt = "$first_line\n--\n$tt";
#    print "\nTT: \n$tt\n\n";

    $user_eval =~ s/\s//g;
    $user_eval =~ tr/A-Z/a-z/;

    # Remove spaces to form "clean" argument: $arg
    $arg = $argument;
    $arg =~ s/&lt;/</g;  # PageOut might change angle brackets to HTML
    $arg =~ s/&gt;/>/g;
    $arg =~ s/\s*//g;
    $arg =~ s/\.:/:./;   # Change .: to :. for uniformity

    # Make the TT template; useful for extracting atoms and TVs
    $tt_template = &make_tt_template($arg);

    $atoms = $tt_template;
    $atoms =~ s/^(.*?)\|.*/$1/s;
    $atoms =~ s/\s//g;
    $num_rows = 2**($atoms =~ tr/A-Z/A-Z/);

    # Can make these both hashes.  This would allow transposed rows.
    @tvas = &get_tvas;
    @user_tvs = &get_user_tvs;

    # @sequent is an array containing the premises and the conclusion
    $sequent = $arg;
    $sequent =~ s/,|:\.|\.:/ /g;
    @sequent = split(/\s+/,$sequent);
}

###

sub check_form {

    # Extract argument from user's truth table
    local $user_arg = $answer;
    $user_arg =~ s/^.*?\|(.*?)\n.*/$1/s;
    $user_arg =~ s/\s//g;
    $user_arg =~ s/\.:/:./;  # Change .: to :. for uniformity

#    print "ARG: $arg\n";
#    print "USER_ARG: $user_arg\n";

    $arg = &prettify_argument($arg);
    $arg =~ s/\s*//g;

    # Make sure user's arg is the same as the given argument
    if ($user_arg ne $arg) {
	$logstuff .= "<strong>Form: </strong>";
	$logstuff .=  &error_msg_wrapper(&msg_CannotFutzWithArg(&htmlify_bicond(&prettify_argument($arg)),
								&htmlify_bicond(&prettify_argument($user_arg))));
        return;
    }
    
    local $num_atomic_wffs_in_seq = 0;
    
    foreach $fla (@sequent) {
	$num_atomic_wffs_in_seq++ if &atomic($fla);
    }
    
    local $num_tvs_expected_in_row = &count_connectives($sequent)+$num_atomic_wffs_in_seq;
    
    # Check the rows of the TT for proper form
    local $tt_rows = $tt;
    $tt_rows =~ s/(.*?\n){2}(.*)/$2/sm;
    
#    print "\nTT_ROWS: \n$tt_rows\n\n";
    
    local @tt_rows = split(/\n/,$tt_rows);
    local $tva;
    $i=1;
    foreach $row (@tt_rows) {
	if ($i>$num_rows) {
	    $logstuff .= "<strong>Form: </strong>" .
		&error_msg_wrapper(&msg_TooManyRows($num_rows));
            return;
	}
	if ($row =~ /[^TF\|\s]/) {
	    $logstuff .= "<strong>Form: </strong>" .
		&error_msg_wrapper(&msg_InvalidChar($i));
            return;
	}
	if ($row !~ /\|/) {
	    $logstuff .= "<strong>Form: </strong>" .
		&error_msg_wrapper(&msg_NoVertBar($i));
            return;
	}
	if ($row =~ /\|.*\|/) {
	    $logstuff .= "<strong>Form: </strong>" .
		&error_msg_wrapper(&msg_TooManyVertBars($i));
            return;
	}
	
  	# extract the TVs in the TVA in the row
  	$tva = $row;
  	$tva =~ s/^(.*?)\s*\|.*/$1/;
  	$tva =~ s/\s//g;
  	$tva =~ s/([TF])/$1 /g;
  	chop($tva);
	
  	# Extract the 2**($num_rows) of TVs in the TVA area
  	my $assigned_tvs = $tt_template;
  	$assigned_tvs =~ s/(.*?\n){2}(.*)/$2/;
  	$assigned_tvs =~ s/\s//g;
  	$assigned_tvs =~ s/([TF])/$1 /g;
  	@assigned_tvs = split(/\|/,$assigned_tvs);
  	chop($assigned_tvs[$i-1]);
	
	# Make sure user hasn't munged the TVs
	# THIS PROCEDURE SHOULD GO AWAY;
	# Users will transpose rows, and should be allowed to do so
  	if ($tva ne $assigned_tvs[$i-1]) {
  	    $logstuff .= "<strong>Form: </strong>" .
		&error_msg_wrapper(&msg_MungedTVA($i,$assigned_tvs[$i-1],$tva));
	    return;
  	}
	
	$row =~ s/^.*?\|\s*(.*)/$1/;                    # strip out the TVA and | in that row
	local $num_tvs_in_row = $row =~ tr/TF/TF/;      # count the number of Ts and Fs
	
	if ($num_tvs_in_row < $num_tvs_expected_in_row) {
	    $logstuff .= "<strong>Form: </strong>" .
		&error_msg_wrapper(&msg_Incomplete($i));
            return;
	}
	if ($num_tvs_in_row > $num_tvs_expected_in_row) {
	    $logstuff .= "<strong>Form: </strong>" .
		&error_msg_wrapper(&msg_TooManyTVs($i));
            return;
	}
	$i++;
    }
    if ($i<=$num_rows) {
	$logstuff .= "<strong>Form: </strong>" .
	    &error_msg_wrapper(&msg_NotEnoughRows($i-1,$num_rows));
	$result_form=0;
	return;
    }
    
    
    $result_form=1;
    $logstuff .= "<strong>Form: </strong>" .
	"The form of the truth table is correct.<br />\n";
}

###

sub check_tv_calc {
    
    local $ith_tva="";
    local $jth_tv="";
    local $shortest_subwff_with_wrong_tv = "";
    local $shortest_tv = "";  # Holds the TV of the shortest subwff w/ wrong TV on a given row
    local $wff="";
    local $subwff="";
    local $current_row=0;
    
  FOO:
    for ($i=0;$i<$num_rows;$i++) {
	$shortest_tv = "";
	$current_row = $i+1;
	$ith_tva = $tvas[$i];
	$ith_tva =~ s/(\w)(\w)/$1 $2/g;
	chop $ith_tva;
	@ith_tva = split(/ /,$ith_tva);
	local $j = 0;                   # the column we're in; used to extract user tv
	local $seq = $sequent;
	
	while ($seq) {
	    ($wff,$seq) = split(/ /,$seq,2);
	    chomp($wff);
	    $num_connectives_in_wff = &count_connectives($wff);
	    my $atomic = !$num_connectives_in_wff;
	    for ($k=1;$k<=$num_connectives_in_wff||$atomic;$k++) {
		$subwff = &extract_nth_subwff($wff,$k);
		$jth_tv = substr($user_tvs[$i],$j,1);
		
                # Find shortest subwff with the wrong tv
		if (&calculate_tv($subwff,@ith_tva) ne $jth_tv) {
		    if ((not $shortest_tv) or
			&count_connectives($subwff) <
			&count_connectives($shortest_subwff_with_wrong_tv)) {
			$shortest_subwff_with_wrong_tv = $subwff;
			$shortest_tv = $jth_tv; # tv of shortest subwff w/ wrong tv
		    }
		}
		
		$j++;
		$atomic = 0;
	    }
	    last FOO if $shortest_tv;   # stop loop if you've found a bad truth value in row $i
	    # (and hence have assigned T or F to $shortest_tv)
	}
    }
    
    if ($shortest_tv) {
        $result_tv_calc=0;
	$logstuff .= "<strong>TV calculation:</strong> ";
	$shortest_subwff_with_wrong_tv =~ s/ //g;
	if (&paren_eq($shortest_subwff_with_wrong_tv,$wff) ||
	    &paren_eq($shortest_subwff_with_wrong_tv,"($wff)")) {
	    $logstuff .=
		&error_msg_wrapper(&msg_IncorrectTV($shortest_tv,&prettify($wff),$current_row));
	    return;
	} else {
	    $pretty_subwff = &prettify($shortest_subwff_with_wrong_tv);
	    my $pretty_wff = &prettify($wff);
	    $logstuff .=
		&error_msg_wrapper(&msg_IncorrectSubwffTV($shortest_tv,
							  $pretty_subwff,$pretty_wff,$current_row));
	    return;
	}
    }
    $result_tv_calc = 1;
    $result = $result_tv_calc;
    $logstuff .= "<strong>TV calculation:</strong> " .
	"Truth values were all calculated correctly.<br />\n";
}

###

###

sub print_log {
    
    $logstuff .= "<strong>Overall problem evaluation:</strong> ";
    $logstuff .= "<b><i>Correct</i></b>\n<p />\n" if $result;
    $logstuff .= "<b><i>Incorrect</i></b>\n<p />\n" if !$result;
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
# Removes spaces before newlines
sub cleanup {
    local $tt = $_[0];
    $tt =~ s/([TF])\s*(\n)/$1$2/g;
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

sub get_tvas {
    local @tvas = ();
    for ($i=1;$i<=$num_rows;$i++) {
	my $tva = "";
	my $tvs = $tt_template;
	$ats = $atoms;
	
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

###
# subroutine for counting the number of connectives in a wff
#
sub count_connectives {
    $_ = $_[0];
    tr/>~\.v/>~\.v/;
}

###
# Add some spaces b/w binary operators to pretty up $wff
sub prettify {
    ($_) = @_;
    s/\s*//g;
    s/([\.v]|->|<->)/ $1 /g;
    s/</&lt;/g;   # "<" inside <pre> needs to be unicoded
    return $_;
}

###
# Note this is not the same as removing spaces in the argument
# Don't replace with s/\s*//g, as we need to retain spaces b/t
# premises so can split on whitespace to form @sequent. (Not
# currenty used in this code.)

sub unprettify {
    $_ = shift;
    s/\s*([^:]\.|v|->|<->)\s*/$1/g;
    return $_;
}

###

sub error_msg_wrapper {
    my $msg = shift;
    $msg = "<font color=\"red\">$msg</font>\n<br />";
    return $msg;
}

###
#
sub prettify_argument {
    $_ = shift;
    $_ =~ s/\s*//g;    # Make sure spaces are gone; probably unnecessary at this point
    s/,/, /g;
    s/:\.|\.:/:-/;
    s/([\.v]|->|<->|:-)/ $1 /g;
    s/:-/:./;
    return $_;
}

sub htmlify_bicond {
    
    $_ = shift;
    s/<->/&lt;-&gt;/g;  # "<" inside <pre> needs to be unicoded
    return $_;
}
    
###
    
    sub htmlify_answer {
    my ($answer) = @_;
    $answer =~ s/\n/\n<br \/>/gs;
    return $answer;
}

###############################################################################
# Subroutine for calulating TV of a sentence on a given truth value assignment
# Taken from Quizmaster code; should put this into a separate module
# Question for later: why does a space get inserted after the conclusion in the
# sequent when TT is submitted from tt.cgi?

sub calculate_tv {

    # Strip off the formula
    $_ = shift @_;

    # Make a hash from the TVA that remains
    my %local_tva = @_;

    # Replace statement letters with truth values (very cool)
    s/([A-Z])/$local_tva{$1}/g;

    # Calculate til all connectives are gone
    while (/[.~\-v]/) {
	&doitnow($_);
    }

    # Prolly unnecessary
    $_ =~ s/\s//;

    return $_;
}

# the TV calculation engine
sub doitnow {

    ($_) = @_;

    # The algorithm assumes outer delimiters
    $_ = "\($_\)" if &iswff("($_)");

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
