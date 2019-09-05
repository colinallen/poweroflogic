#!/usr/bin/perl -w
# evaluate-tt.pl
# This script has two main functions:  evaluate_tt and valid_or_invalid.
# The first checks a submitted truth table for proper form, and for
# proper calculation of the truth values in the table.  If the truth table
# passes these tests, it is passed to valid_or_invalid, which generates
# a new page that brings up the validated truth table and asks the user
# to assess its validity.  Submitting that page calls check-validity.pl.

require "extract_nth_subwff.pl";
require "pol-template.pl";
require "messages.pl";

local ($tt) = @ARGV;
require "../lib/header.pl" and &evaluate_tt if $tt;

###

sub evaluate_tt {

# initialize some global variables

    $debug=0;
    local $logstuff="";
    $ith_tva="";
    $jth_tv="";
    $shortest_subwff_with_wrong_tv = "";
    $shortest_tv = "";		# Holds the TV of the shortest subwff w/ wrong TV on a given row
    $wff="";
    $subwff="";
    $current_row=0;
    $probref = "$POL::exercise "."Problem $POL::problem_num" if $POL::exercise;

# process the input

#    $tt = $POL::tt;
    $tt = $POL::tt unless $input;
    $tt = &cleanup($tt);
    $orig_tt = $tt;
    $tt =~ s/([TF])\s*$/$1\n/s;         # replace all white space at the end of the TT with a single \n
    $tt =~ s/\r//g;
    $logstuff = $tt;

    $tt_rows = $tt;
    $tt_rows =~ s/(.*?\n){2}(.*)/$2/sm;

    $atoms = $POL::atoms;
    $atoms =~ s/[ \t]//g;

    local $pretty_seq = $POL::pretty_seq;
    local $sequent = $pretty_seq;

    if ($sequent =~ /^\s*(:\.|\.:)/) {    # case where there are no premises in RYO sequent
	$sequent =~ s/(:\.)|(\.:)//g;
	$sequent =~ s/ //g;
	@sequent = ($sequent);
    } else {                              # case where there are both premises and conclusion
	$sequent =~ s/(:\.\s*)|(\.:\s*)//g;
        $sequent =~ s/,//g;               # remove commas
	$sequent =~ unprettify($sequent); # Remove spaces around binary connectives
#	$sequent =~ s/  / /g;             # Make sure there are no double spaces (probably unnecessary
	$sequent =~ s/\s*$//;             # Make sure no trailing spaces at end of sequent
	@sequent = split(/,* /,$sequent); # @sequent now just contains the unprettified formulas in the argument
    }

    $dashes= $POL::dashes;

    $assigned_tvs = $POL::assigned_tvs;
    $assigned_tvs =~ s/\s//g;
    $assigned_tvs =~ s/([TF])/$1 /g;
    @assigned_tvs = split(/\|/,$assigned_tvs);

    $num_atoms = $atoms =~ tr/A-Z/A-Z/;
    $num_rows = 2**$num_atoms;
    $num_wffs = scalar(@sequent);
    @tvas = &get_tvas;
    @user_tvs = &get_user_tvs;

    &start_polpage;

#     print 
# 	"@assigned_tvs<br>",
# 	"atoms: $atoms<br>", 
# 	"sequent: $sequent<br>",
# 	"sequent array: @sequent<br>",
# 	"dashes: $dashes<br>", 
# 	"tt_rows: $tt_rows<br>",
# 	"tt: $tt<br>",
# 	"tvas: @tvas<br>",
# 	"user_tvs: @user_tvs<br>";

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
            $wff =~ s/\s*//g;
	    $num_connectives_in_wff = &count_connectives($wff);
	    my $atomic = !$num_connectives_in_wff;
	    for ($k=1;$k<=$num_connectives_in_wff||$atomic;$k++) {
		$subwff = &extract_nth_subwff($wff,$k);  # &ext... just returns $wff if it contains < 2 connectives
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
#		$vbar[$i]{$wff} = $jth_tv 
		$vbar_string .= "$wff $jth_tv " # need to be able to pass vbar as a param...
                  if &paren_eq($wff,$subwff);
#		print "vbar_string: $vbar_string<br>";
		$atomic = 0;
	    }
	    last FOO if $shortest_tv;   # stop loop if you've found a bad truth value in row $i 
	                                # (and hence have assigned T or F to $shortest_tv)
	}
#	chop $vbar_string;
    }
    if ($shortest_tv) {
	$shortest_subwff_with_wrong_tv =~ s/ //g;
	if (&paren_eq($shortest_subwff_with_wrong_tv,$wff) || &paren_eq($shortest_subwff_with_wrong_tv,"($wff)")) {

	    $logstuff .= &msg_IncorrectTV($shortest_tv,&prettify($wff),$current_row);
	    &mailit($mailto,$logstuff);
	    &pol_template($head_IncorrectTV,
			  &msg_IncorrectTV($shortest_tv,&prettify($wff),$current_row),
			  $probref,
			  '&tt_form($POL::argument,1)');  # Single quotes are correct here!  Arg is to be eval'd...);
	} else {
	    $pretty_subwff = &prettify($shortest_subwff_with_wrong_tv);
	    my $pretty_wff = &prettify($wff);

#	    $logstuff .= &msg_IncorrectSubwffTV($shortest_tv,$pretty_subwff,$pretty_wff,$current_row);
	    &pol_template($head_IncorrectSubwffTV,
			  &msg_IncorrectSubwffTV($shortest_tv,$pretty_subwff,$pretty_wff,$current_row),
			  $probref,
			  '&tt_form($POL::argument,1)');
	}
    }

    &valid_or_invalid($tt,$vbar_string);
    &bye_bye;
}


###
sub valid_or_invalid {

    local ($tt,$vbar_string,$flag) = @_;
    local %vbar;
    local $pretty_seq = $POL::pretty_seq if $POL::pretty_seq;
    local @sequent = split(/ /,$POL::seq) if $POL::seq;

    # my @tt = split(/\n/,$tt);
    # print "<h3>rows before cleanup = ".@tt."</h3>";
    $tt = &cleanup($tt);  # start with $tt, removing any spaces before newlines
    @vbar_array = split(/ /,$vbar_string);

    for ($i=0;$i<$num_rows;$i++) {
	for $fla (@sequent) {
	    shift(@vbar_array);                      # pop off the wff
	    $vbar[$i]{$fla} = shift(@vbar_array);    # assign it the right TV for the $ith row
	}
    }

    my @tt = split(/\n/,$tt);
    # print "<h3>rows after cleanup = ".@tt."</h3>";
    local $subtitle = "Exercise $probref\n" if $probref;

    &pol_header($subtitle) if not $flag;             # table 1 -- outer table

    print  # Announce the point (more loudly now than $instructions in &pol_header)

	"<center>",
	h2("Valid or invalid?"),
	"</center>"
	    if not $flag;

    print  # instructions -- looks best if put inside its own table
	"<center>",
	"<table cellpadding=5 border=0 cellspacing=0 width=\"100%\">\n",               # table 2 -- instructions
	"<tr><td>",
	"Your truth table is correct.  Now, using the truth table, ",
	"determine whether or not the argument is valid.  If it is, ",
	"click the button labeled \"Valid\" below.  ",
	"If it is not valid, first, check at least one row of the truth table ",
	"that shows that it is not, and then click the button below labeled ",
	"\"Invalid\".",
	"</td></tr>\n",
	"</table>\n",                                                              # end table 2
	"</center>\n"
	    if not $flag;

    print
	$cgi->startform,
	"\n";

    print  # start the truth table (surrounded by table-in-table)
	"<center>\n",
	"<table border=\"3\">\n",  # table 3 -- smaller single-cell table for the truth table
	"<tr><td>\n";              #            and the valid/invalid buttons

    print
	"<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\">\n";  # table 4 -- the TT table itself

    ## The next three lines restore the original argument ##
    ## in case it has been munged by the user.            ##

    $atoms = $POL::atoms if $POL::atoms;
    $atoms =~ s/\s//g;
    local $atoms_with_spaces = $atoms;
    $atoms_with_spaces =~ s/([A-Z])/$1 /g;
    local $pretty_seq_with_nbsps = $pretty_seq;
    $pretty_seq_with_nbsps =~ s/ /&nbsp;/g;
    local $row1 = "$atoms_with_spaces| $pretty_seq_with_nbsps".'&nbsp;';
    $dashes = $POL::dashes if $POL::dashes;

    my $pretty_tt = "$atoms_with_spaces| $pretty_seq\n";  # Used to reformat user TT in case uglily formatted
    $pretty_tt .= "$dashes\n";

    print  # row 1: the sequent
	"<tr>\n",
	"<td><br></td>\n",  # empty cell--check boxes will go in this column in rows below
	"<td><tt>\n",
	ascii2utf_html($row1),
	"</td></tt>\n";

    print  # row 2: separating dashes
	"<tr>\n",
	"<td><br></td>\n",
	"<td><tt>",
	$dashes,
	"</tt></td>\n",
	"</tr>\n";

# The next block of code prints the remaining rows of the
# table, but first processes the user's truth values
# to ensure that the all truth values occur beneath
# appropriate connectives and atomic statements

    local $assigned_tvs = $POL::assigned_tvs;
    $assigned_tvs =~ s/\s//g;
    $assigned_tvs =~ s/([TF])/$1 /g;
    @assigned_tvs = split(/\|/,$assigned_tvs);

    local $temp_arg_string = &make_temp_arg_string($pretty_seq);
    for ($i=2;$i<@tt;$i++) {
		$rownum = $i-2;
		local $ith_row_user_tv_display_string = "";
		local $ith_row_user_tvs = $user_tvs[$rownum];

		print $cgi->hidden(-name=>"user_tvs_row_$i",-value=>$ith_row_user_tvs),"\n";

		$ith_row_user_tvs = $cgi->param("user_tvs_row_$i") if $cgi->param("user_tvs_row_$i");

# Check to see if we've already got a display string for the i_th row; if not, construct one

        if (not $ith_row_user_tv_display_string = $cgi->param("user_tv_display_string_row_$i")) {
	 	    my $foo = $temp_arg_string;
	 	    while ($foo) {
		 		$last_char = chop($foo);
		 	      CASE: {
		 		    $ith_row_user_tv_display_string = chop($ith_row_user_tvs) . $ith_row_user_tv_display_string,
		                       last CASE
                  		 			if $last_char eq 'v' or $last_char eq '~' or $last_char eq '&' or $last_char eq '-';
		 		    $ith_row_user_tv_display_string = chop($ith_row_user_tvs) . $ith_row_user_tv_display_string,
		                       chop($foo),
		                         last CASE
		                           if $last_char eq '^';
					last CASE
						if $last_char eq '>';
		 		    $ith_row_user_tv_display_string = '&nbsp;' . $ith_row_user_tv_display_string;
		 	  	}
	 	    }
	 	}
		print
	#	    "ith_row_user_tv_display_string row $i: $ith_row_user_tv_display_string<br>",
		    $cgi->hidden(-name=>"user_tv_display_string_row_$i",-value=>$ith_row_user_tv_display_string);
	
	        my $pretty_row = $assigned_tvs[$i-2] . "| " . $ith_row_user_tv_display_string;
	        $pretty_tt .= "$pretty_row\n";
	
		print
	          "<tr>\n",
	            "<td>\n",
	             $cgi->checkbox(-name=>"row_$rownum",
				   -value=>"checked",
				   -label=>""),
		    "</td>\n",
		    "<td><tt>",
	#              $assigned_tvs[$i-2],"| ",$ith_row_user_tv_display_string,
		    $pretty_row,
		    "</td>",
	            "</tt>\n",
	
		    "</tr>\n";
    }

    print
	"</table>\n";                    # end table 4 -- close TT table
			  
    print		  
	"</td></tr>\n",                  # close the single cell containing truth table
	"</table>\n";                    # end table 3 -- close the single-cell TT table

    print  # radio buttons for choosing valid or invalid
	"<p>",
	$cgi->submit(-name=>'action',-value=>'Valid'),"\n",
	$cgi->submit(-name=>'action',-value=>'Invalid'),"\n",
	"</center>\n";

    print
      $cgi->hidden(-name=>'tt',-default=>$tt),"\n",
      $cgi->hidden(-name=>'pretty_tt',-default=>$pretty_tt),"\n",
      $cgi->hidden(-name=>'vbar_string',-default=>$vbar_string),"\n",
      $cgi->hidden(-name=>'exercise',-default=>"$POL::exercise"),"\n",
      $cgi->hidden(-name=>'problem_num',-default=>"$POL::problem_num"),"\n",
      $cgi->hidden(-name=>'num_rows',-default=>$num_rows),"\n",
      $cgi->hidden(-name=>'seq',-default=>$sequent),"\n",
      $cgi->hidden(-name=>'pretty_seq',-default=>$pretty_seq),"\n",
      $cgi->hidden(-name=>'atoms',-default=>$atoms),"\n",
      $cgi->hidden(-name=>'dashes',-default=>$dashes),"\n",
      $cgi->hidden(-name=>'assigned_tvs',-default=>$assigned_tvs),"\n",
      $cgi->hidden(-name=>'user_tvs',-default=>@user_tvs),"\n",
      $cgi->hidden(-name=>'prev_chosen',-default=>@prev_chosen),"\n",
      $cgi->hidden('pageout'),"\n",  # rolls over pageout=sent if not all invalidating
      ;                              # rows have been found; set in check-validity.pl

    for ($i=0;$i<$num_rows;$i++) {
	foreach $fla (@sequent) {
	    print
		$cgi->hidden(-name=>"vbar_$i\_$fla",-default=>$vbar[$i]{$fla});
	}
	print "\n";  # nicer html formatting...
    }

    print
	$cgi->endform;

    &footer();  # end tables 2 and 1

    &bye_bye();
}

###
# This subroutine takes the displayed sequent and forms a string
# that is easier to process in the above routine that calls it.
# Basically, the routine marks atomic premises and conclusions
# with a following caret (e.g., "A" => "A^") and changes dots
# to ampersands.

sub make_temp_arg_string {
    my $temp_arg = shift;
    $temp_arg =~ s/\s*$//;                           # Remove any trailing spaces
    $temp_arg =~ s/, ([A-Z]), /, $1\^, /g;           # Statement letter occurring before and after other premises
    $temp_arg =~ s/^([A-Z]), /$1\^, /g;              # Statement letter as first premise with following premises
    $temp_arg =~ s/^([A-Z]) (:\.|\.:)/$1\^ $2/;      # Statement letter as first premise with no following premises
    $temp_arg =~ s/, ([A-Z]) (:\.|\.:)/, $1\^ $2/;   # Statement letter as last premise with previous premises
    $temp_arg =~ s/(:\.|\.:) ([A-Z])\s*$/$1 $2\^/;   # Statement as conclusion
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
    #print "USER_ARG: $user_arg<br>";

    local $prob_arg = $pretty_seq;
    $prob_arg =~ s/\s//g;
    #print "PROB_ARG: $prob_arg<br>";


    if ($user_arg ne $prob_arg) {
#	$logstuff .= &msg_CannotFutzWithArg($probref,$pretty_seq,&prettify($user_arg));
	&pol_template (
		       $head_CannotFutzWithArg,
		       &msg_CannotFutzWithArg($probref,$pretty_seq,&prettify($user_arg)),
		       $probref,
		       '&tt_form($POL::argument,1)');
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
#	    $logstuff .= &msg_TooManyRows($num_rows);
	    &pol_template($head_TooManyRows,
			  &msg_TooManyRows($num_rows),
			  $probref,
			  '&tt_form($POL::argument,1)');
	}
	if ($row =~ /[^TF\|\s]/) {
#	    $logstuff .= &msg_InvalidChar($i);
	    &pol_template($head_InvalidChar,
			  &msg_InvalidChar($i),
			  $probref,
			  '&tt_form($POL::argument,1)');
	}
	if ($row !~ /\|/) {
#	    $logstuff .= &msg_NoVertBar($i);
	    &pol_template($head_NoVertBar,
			  &msg_NoVertBar($i),
			  $probref,
			  '&tt_form($POL::argument,1)');
	}
	if ($row =~ /\|.*\|/) {
#	    $logstuff .= &msg_TooManyVertBars($i);
	    &pol_template($head_TooManyVertBars,
			  &msg_TooManyVertBars($i),
			  $probref,
			  '&tt_form($POL::argument,1)');
	}	    
	$tva = $row;
	$tva =~ s/^(.*?)\s*\|.*/$1/;              # extract the TVA in the row
	$tva =~ s/\s//g;
	$tva =~ s/([TF])/$1 /g;
	chop($tva);
	chop($assigned_tvs[$i-1]);
	if ($tva ne $assigned_tvs[$i-1]) {
#	    $logstuff .= &msg_MungedTVA($i,$assigned_tvs[$i-1],$tva);
	    &pol_template($head_MungedTVA,
			  &msg_MungedTVA($i,$assigned_tvs[$i-1],$tva),
			  $probref,
			  '&tt_form($POL::argument,1)');
	}
	$row =~ s/^.*?\|\s*(.*)/$1/;                    # strip out the TVA and | in that row
	local $num_tvs_in_row = $row =~ tr/TF/TF/;      # count the number of Ts and Fs
	if ($num_tvs_in_row < $num_tvs_expected_in_row) {
#	    $logstuff .= &msg_Incomplete($i);
	    &pol_template($head_Incomplete,
			  &msg_Incomplete($i),
			  $probref,
			  '&tt_form($POL::argument,1)');
	}
	if ($num_tvs_in_row > $num_tvs_expected_in_row) {
#	    $logstuff .= &msg_TooManyTVs($i);
	    &pol_template($head_TooManyTVs,
			  &msg_TooManyTVs($i),
			  $probref,
			  '&tt_form($POL::argument,1)');
	}
	$i++;
    }
    if ($i<=$num_rows) {
#	    $logstuff .= &msg_NotEnoughRows($i-1,$num_rows);
	    &pol_template($head_NotEnoughRows,
			  &msg_NotEnoughRows($i-1,$num_rows),
			  $probref,
			  '&tt_form($POL::argument,1)');
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
}


###
require "../lib/wff-subrs.pl";

sub prettify {
	$_ = shift;
#    $_ = ascii2utf(shift);
    s/,/, /g;
    s/(v|->|<->|:\.|\.:)/ $1 /g; # Add some spaces b/t binary operators to pretty up $seq
    s/\.:/:./;
    s/([^:])\./$1 \. /g;
    return $_;
}


###
sub unprettify {
#    $_[0] = utf2ascii($_[0]);
    $_[0] =~ s/ ([\.v]|->|<->) /$1/g;
}



1;
