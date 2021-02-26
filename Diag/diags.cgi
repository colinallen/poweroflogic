#!/usr/bin/perl

require '../lib/header.pl';

$mailto='random';

#$tab          = chr(32);
$tab          = ".";
$qtab         = quotemeta($tab);
$anstab       = ">";
$newln        = ":";
$ind          = "v";
$IND          = "V";  # for independent supporters of same conclusion
$dep          = "+";  # for codependent supporters of same conclusion
$delrow       = "Delete Row";
$uplabel      = "Add row to top";
$downlabel    = "Add row to bottom";
$restorelabel = "Remove Brackets";
$redrawlabel  = "Redraw/Recolor";
$checklabel   = "Check Diagram";

$program = $cgi->url;

$POL::exercise = '2.3A' if !$POL::exercise;

################# keep track of prevchosen items
@POL::prevchosen = split(/::/,$POL::prevchosenstring)
    if $POL::prevchosenstring;
%prevchosen = ();
for (@POL::prevchosen) {
    next unless $_;              # skip bogus values
    $prevchosen{$_} = 1;         # store legit values
}
$prevchosen{$POL::probnum} = 1 if $POL::probnum;  # register current probnum
$cgi->param('prevchosen', sort {$a<=>$b} keys %prevchosen); # set in cgi
$prevchosen_string = join "::", keys %prevchosen; # used for menu
################ end prevchosen maintenance

## add menu items;
($chapter,$exnum)=split(/\./,$POL::exercise,2);
$polmenu{"Main Menu"} = "../menu.cgi";
$polmenu{"More from Ch. $chapter"} = "../menu.cgi?chapter=$chapter"
    if $POL::exercise;
if ($POL::prob) {
    $polmenu{"More from Ex. $POL::exercise"}
    = "$program?exercise=$POL::exercise&prevchosenstring=$prevchosen_string&msfoo=".rand;
    $polmenu{"Help with diagrams"} = "../help.cgi?helpfile=diagrams.html";
}
### end menu additions

&start_polpage('Argument Diagrams');

$instructions = "Pick an argument to diagram<br>\n".$PREVCHOICEINSTRUCTION
    unless $POL::prob;

&get_out if $cgi->user_agent  =~ /msie[^\d]*[1-3]/i;

&pickprob if !$POL::prob;

$POL::prob = &rot($POL::prob);
($argument,$answer) = split(/::/,$POL::prob);
$answer = &reversestring($answer);
&bracket if !$POL::bracketed;

@userdiag = @POL::elements;
@userdiag = (0,$newln)
    unless @userdiag or $POL::usrchc =~ /$uplabel|$downlabel/;

while ($userdiag[0] =~ /^($newln|\s)$/) {
    shift @userdiag;
}

for (@userdiag) {
    $_=substr($_,0,2) unless /$delrow/; # shorten illegally long fields
#    $_=$tab if !$_;
#    print "'$_'";
}

$userdiag = join('',@userdiag);
$reverse_userdiag = &reversestring($userdiag);
$userconc = &get_conclusion($reverse_userdiag);

$cgi->delete('elements');

for ($POL::usrchc) {
    /$uplabel|$downlabel/i  and do { &add_row; last; };
    /Not an argument/i      and do { &check_arg; last; };
    /Check Brackets/        and do { &check_brackets; last; };
    /Check/                 and do { &check; last;};
    /show answer/i          and do { &reveal_diagram; last;};
    /$restorelabel/         and do { &restore_arg; last};
    &display_argument(@userdiag);
}
&pol_footer;
&end_polpage;

#################################################################
### ARGUMENT BRACKETING SUBROUTINES

###
sub pickprob {
    my @problems;
    my $probfile = "$EXHOME"."$chapter/$chapter.$exnum";

    $probfile =~ s/\||\.\.//g; # close pipeline exploit; CA 9-17-2004    
    open(FILE,$probfile) || die("Could not open problem file $probfile");
    while (<FILE>) {
	next if /^\#|^\w*$/;
	chomp;
	push @problems, $_;
    }
    close(FILE);
    
    # html out
    &pol_header("Exercise $POL::exercise, Argument Diagrams",$instructions);

    print
	"<table width=\"100%\" border=0>";

    my $count=0;
    foreach $problem (@problems) {
	++$count;
	my ($argument,$foo) = split("::",$problem,2);
	$argument =~ s/[\[\]]//g;
	if (length($argument) > 160) { # truncate display
	    $argument = substr($argument,0,160);
	    $argument =~ s/(.*)\s.*/$1.../;
	}
	$problem = &rot($problem); # hide from prying eyes

	my $button_image = $prevchosen{$count} ? $smallgreyPoLogo : $smallPoLogo;

	print
	    Tr(
	       td({-valign=>'top',-align=>'left'},
		  $cgi->startform,
		  $cgi->hidden(-name=>'prob',-value=>$problem),
		  $cgi->hidden(-name=>'probnum',-value=>$count),
		  $cgi->hidden('prevchosen'),
		  $cgi->hidden('exercise'),
		  $cgi->image_button(-name=>'act',
				     -src=>$button_image,
				     -value=>"Arg. $count"),
		  ),
	       td({-valign=>'center',-align=>'left',-bgcolor=>'#dddddd'},
		  "<font size=-1>",
		  $cgi->strong("#$count"),
		  "</font>",
		  $cgi->endform,
		  ),
	       td("<font size=-1>\n",
		  $argument,
		  "</font>"),
	       );
    }
    
    print "</table>";

    &pol_footer;
    &end_polpage;
}

###
sub bracket {
    my $msg = @_[0];
    my $arg = $argument;
    $arg =~ s/[\[\]]//g;

    my $numrows = int(length($argument)/58)+2;

    $instructions = "If you believe this passage does not contain an argument, click the \"Not an argument\" button below. Otherwise place square brackets around the individual statements in this argument.";

    &pol_header("Exercise $POL::exercise, Argument Diagrams",$instructions);
    print $msg;
    print
	$cgi->startform,
	"<center>",
	$cgi->textarea(-name=>'brackguess',
		       -style=>'font-family: monospace',
		       -value=>$POL::brackguess,
		       -default=>$arg,
		       -rows=>$numrows,
		       -cols=>60,
		       -wrap=>'wrap'),
	$cgi->hidden('prob'),
	$cgi->hidden('probnum'),
	$cgi->hidden('prevchosen'),
	$cgi->hidden('exercise'),
	$cgi->hidden('bracketed',1),
	"<br>",
  	$cgi->submit('usrchc','Not an argument'),
  	$cgi->submit('usrchc','Check Brackets'),
  	$cgi->submit('usrchc',$restorelabel),
	"</center>",
	$cgi->endform;

    &pol_footer;
    &end_polpage;
}

###

sub check_arg {
    if ($answer eq 'tnemugra na toN') { # backwards
	$instructions = "";
	&pol_header("Exercise $POL::exercise, Argument Diagrams",$instructions);
	print $cgi->center("<b>You correctly reported this as not argument.</b>");
	print "<div style=\"color: gray\">$POL::brackguess</a></div>";
	$cgi->delete('prob');

	print
	    "<hr>\n",
	    $cgi->startform,
	    $cgi->center($cgi->submit(-name=>'act',-value=>"Another from $POL::exercise?")),
	    $cgi->hidden('exercise'),
	    $cgi->hidden('prevchosen'),
	    $cgi->endform;

	&pol_footer;
	&end_polpage;

    } else {
	&bracket("<div style=\"text-align: center; color=$INSTRUCTCOLOR\">Wrong answer. Try again.</div>");
    }
}

sub check_brackets {
    my $match = &fuzzy_match($POL::brackguess,$argument);
    $instructions = "" if $match;

    #&pol_header("Exercise $POL::exercise, Argument Diagrams",$instructions);
    if (($POL::brackguess !~ /\[/)
	|| ($POL::brackguess !~ /\]/)) {
	&bracket("<div style=\"text-align: center; color=$INSTRUCTCOLOR\">Wrong answer. You did not insert a set of brackets. Try again.</div>");
	exit;
	
    }
    if ($match !~ /\d/) {
#	&mailit($mailto,
#		"$POL::brackguess\ncompared to\n$argument\nyielded\n$match")
#	    if $mailto;

	&display_argument($match,@userdiag);
    } else {
	my $numbracksguess = ($POL::brackguess =~ s/\[/\[/g);
	my $numbracksans = ($argument =~ s/\[/\[/g);
	my $errmsg;
	$errmsg = "You have identified the correct number of statements.";
	$errmsg = "You have identified too many statements."
	    if $numbracksguess > $numbracksans;
	$errmsg = "You have identified too few statements."
	    if $numbracksguess < $numbracksans;
	$errmsg .= " You have misplaced the number $match pair of brackets. "
	    if $match > 0;

#	&mailit($mailto,
#		"$POL::brackguess\ncompared to\n$argument\nyielded\n$errmsg")
#	    if $mailto;

	$errmsg .= "<br>Try again!";

	&bracket("<center>$errmsg</center>");
    }
}

###
sub fuzzy_match {
    my ($string1,$string2) = @_;
    return 'identical' if $string1 eq $string2;

    my $curr1, $curr2;
    my $match = 'close enough';
    my $count = 0;
    my $continue = 1;
    while ($string1 =~ /\]/ and $continue) {
	++$count;
	($curr1,$string1) = split(/\]/,$string1,2);
	$curr1 = uc($curr1);
	$curr1 =~ /.*\[(.*)/;
	$curr1 = $1;
	$curr1 =~ s/[^\w]//g;
	($curr2,$string2) = split(/\]/,$string2,2);
	$curr2 = uc($curr2);
	$curr2 =~ /.*\[(.*)/;
	$curr2 = $1;
	$curr2 =~ s/[^\w]//g;
	if (# too much omitted
	    (abs(length($curr1)-length($curr2)) > 15)
	    || # or no inclusion
	    ($curr1 !~ /$curr2/ and $curr2 !~ /$curr1/)
	    || # or nothing to match in string2
	    ($string1 =~ /\]/ and $string2 !~ /\]/)) {
	    $match = $count;
	    $continue = 0;
	}
    }
    $match = $count if $string2 =~ /\]/;
    return $match;
}

###
sub restore_arg {
    $POL::brackguess = $POL::prob;
    $POL::brackguess =~ s/[\[\]]//g;
    $cgi->delete('brackguess');
    &bracket;
}

#############################################################################
### DIAGRAM MANIPULATION SUBROUTINES
# The allowable element in DIAGRAMs are:
#   statement numbers (max one digit)
#   v (for independent branches)
#   + (for interdependent supports -- same meaning as in book)
#   > (for formatting)
#
# Internally, > represents an empty cell in the diagram, but it's for
# pretty formatting purposes only to allow conclusions to be centered
# under the supporting premises, but having no logical meaning.  The
# diagram representation ends rows with colons, and shows all the
# elements of each row in left to right order.  So, e.g.
#
# 12:3:
# 1+2:>3
# 1v2:3v4:5
#
# When there are multiple branches, the coordination between rows is implicit.  So, e.g. in 
#    1+2v3:4v5:6:
# 1+2 is matched to 4 and 3 is matched to 5.
#
# The diagram string is reversed during processing for easier manipulation


### manipulates the number of rows in a diagram
sub add_row {
    push @userdiag, ('0',$newln)    if $POL::usrchc eq $downlabel;
    unshift @userdiag, ('0',$newln) if $POL::usrchc eq $uplabel;
    &display_argument(@userdiag);
}

###
sub display_argument {
    local $clean = shift(@_) if @_[0] =~ /clean/i;
    local $match = shift(@_) if @_[0] =~ /close|identical/i;

    $conclusion_ok = &is_conclusion_ok(&get_conclusion($reverse_userdiag),
				       $answer);
    
    $instructions = "<strong>INSTRUCTIONS</strong> Use small (tab) buttons in table below to expand rows to left and right. In table cells, enter numbers (for statements), enter <tt>v</tt> between <em>in</em>dependent supports, and <tt>+</tt> between <em>inter</em> dependent) supports. Remove a cell by clicking in with mouse and deleting all its contents (<em>including</em> invisible elements). Use <u>$redrawlabel</u> button to see the effects of changes."
	unless $clean;

    &pol_header("Exercise $POL::exercise, Argument Diagrams",
		$instructions);


    if ($POL::usrchc =~ /Check Brackets/) { # then we just arrived
	print
	    "<table border=\"0\" cellspacing=\"2\" width=\"100%\">",
	    "<tr><td valign=\"top\" width=\"50%\">",
	    "<strong>",
	    "Your placement of brackets was...<br>",
	    "</strong>",
	    $POL::brackguess,
	    "</td><td valign=\"top\" width=\"50%\">",
	    "<strong>",
	    "...$match to the official answer:<br>",
	    "</strong>",
	    $argument,
	    "</td></tr></table>\n",
	    "<hr>",
	    ;
    }

    print
	"\n<table border=\"0\" cellspacing=\"0\" align=\"center\">",
	"<!--containing table-->\n",
	"<tr><td valign=\"top\">",
	;

    print "<div style=\"color: $INSTRUCTCOLOR\">$msg</div>\n";

    print
	strong("Diagram the argument with statements numbered as shown"),
	"<br>"
	unless $clean;

    &display_english('abridged') # show the english argument
	unless $clean;

    print "</td><td valign=\"top\">";

    ++$POL::xattempts if $POL::usrchc =~ /Check Diagram/;
    $cgi->param('xattempts', $POL::xattempts);
    $attempt_text = "[attempts: $POL::xattempts]" if $POL::xattempts;

    print
	$cgi->startform,
	$cgi->hidden('probnum'),
	$cgi->hidden('prevchosen'),
	$cgi->hidden(-name=>'xattempts'),
	
	unless $clean;

    my $border = "0px solid black";
    $border = "2px solid black" if $clean;
    print
	"\n",
	"<!--begin diagram table-->\n",
	"<table -style=\"border: $border; ",
	"  cellspacing: 0px; ",
	"  cellpadding: 2px; ",
	"  align: center;\"",
	">",
	;
	
    print
	Tr(td({-colspan=>20, -bgcolor=>$DIAGBGCOLOR, -align=>'center'},
	      $cgi->submit(-name=>usrchc,-value=>$uplabel),
	      #$cgi->submit(-name=>usrchc,-value=>$downlabel),
	   ))
	unless $clean;

    my $row1; my $row2;
    my $prev; local @prevcolorrow; local @colorrow;
    my $count = 0; my $rowcount = 0;

    my $deletingrow = 0;
    my $loopcount = 0;
    for (@userdiag) {
	++$loopcount;
	
#	next if /^\s*$/;
	$deletingrow = 1 and next if /$delrow/;
	if ($deletingrow) {
	    $deletingrow = 0 if /$newln/;
	    next;
	}

	if (/$newln/) { # end of line
	    next if $prev eq $newln; # skip blank line
	    #&output_colorrow($row0,$count) unless $rowcount == 0;
	    &output_workrow($row1,$count);
	    &output_colorrow($row2,$count) unless $loopcount > $#struc;

	    @prevcolorrow = @colorrow;
	    @colorrow = ();
	    $row0 = '';
	    $row1 = '';
	    $row2 = '';
	    $count = 0;
	    ++$rowcount;
	} elsif (/([$qtab$ind$IND$dep])(.+)/ or /(.+)([$qtab$ind$IND$dep])/) {
	    my $first = $1;
	    my $second = $2;

	    $row0 .= &bridgecell($first,$count);
	    $row0 .= &bridgecell($second,$count+1);
	    $row1 .= &makebox($first);
	    $row1 .= &makebox($second);
	    $row2 .= &plaincell($first);
	    $row2 .= &plaincell($second);
	    ++$count;
	    ++$count;
	} elsif (/[\d$qtab$ind$IND$dep]/) {
	    $row0 .= &bridgecell($_,$count);
	    $row1 .= &makebox($_);
	    $row2 .= &plaincell($_);
	    ++$count;
	} else { # bogus character
	    next;
	}
	$prev = $_;
    }
    &output_colorrow($row0) if $row1; # in case of incomplete row
    &output_workrow($row1) if $row1;


    if ($POL::xattempts > 5) {
	$attempt_text .= "<br>";
	$attempt_text .= $cgi->submit(-name=>usrchc,-value=>"Show Answer");
    } 


    print
	"<tr>",
	"<td colspan=\"20\" bgcolor=\"$DIAGBGCOLOR\" align=\"center\">",
	$cgi->submit(-name=>usrchc,-value=>$redrawlabel),
	$cgi->submit(-name=>usrchc,-value=>$checklabel),
	$cgi->center("<font size=\"-1\">$attempt_text</font>"),
	"</td></tr>"
	    unless $clean;

    print "</table><!--end diagram table-->";

    print
	"</td></tr>",
	"</table><!--end containing table-->",
	"<hr>",
	;

    &display_english('');
    $problem = &rot($problem);
    print $cgi->hidden(-name=>prob,-value=>$problem);
    #$cgi->hidden('probnum');
    print $cgi->hidden('bracketed',1);
    print $cgi->hidden('exercise');
    print $cgi->endform;


}

###
sub makebox {
    my ($contents) = @_;
    my $result;
    $result .= "\n<td align=center";
    $result .= " bgcolor=$DIAGFGCOLOR" if $contents =~ /[1-9$dep]/i;
    $result .= " bgcolor=#aaaaaa" if $contents =~ /[$IND$ind]/i;
    #$result .= " style=\"border-bottom: dotted $RIGHTPAGECOLOR 1px\"";
    $result .= ">\n";
    $result .= $cgi->textfield(-name=>'elements',
			       -style=>'font-family: monospace',
			       -value=>$contents,-size=>2)
	if !$clean;


    $result .= "<font color=\"white\" size=\"+2\">$contents</font>"
	if $clean and $contents =~ /[1-9$dep]/;
    $result .= "&nbsp;"; # unless $contents;
    $result .= "\n</td>\n";
    return $result;
}

###
sub plaincell {
    my ($contents) = @_;
    my $result;
    my $bgcolor = "black";
    $bgcolor = $DIAGBGCOLOR if $contents =~ /[1-9$ind$IND$dep]/;
    $result = td({-align=>"center",-bgcolor=>$bgcolor},
		 "&nbsp;");

    push @colorrow, 1 if $contents =~ /[1-9$ind$IND$dep]/;
    push @colorrow, 0 if $contents !~ /[1-9$ind$IND$dep]/;

    return $result;
}

###
sub bridgecell {
    my ($contents,$count) = @_;
    my $result;
    my $bgcolor = $DIAGFGCOLOR;
    $result .= "\n<td align=center";
    $result .= " bgcolor=\"$bgcolor\"" if $contents =~ /[1-9]/ and @prevcolorrow[$count];
    $result .= ">\n";
    $result .= "&nbsp";
    $result .= "\n</td>\n";
    return $result;
}

###
sub output_colorrow {
    my ($row,$count) = @_;
    my $colspan = 18-$count;
    print "<tr>";
    print td({-bgcolor=>$RIGHTPAGECOLOR},
	     "&nbsp;")
	unless $clean;	
    print $row;
    print td({-colspan=>$colspan},"&nbsp;") unless $clean;
    print td({-bgcolor=>$RIGHTPAGECOLOR},"&nbsp;")
	unless $clean;
}

###
sub output_workrow {
    my ($row,$count) = @_;
    print "<tr>";
    print
	"<td bgcolor=\"$RIGHTPAGECOLOR\" valign=\"bottom\" align=\"right\">",
	$cgi->submit(-name=>elements,-value=>$delrow),
	$cgi->submit(-name=>elements,-value=>$tab),
	"</td>"
	unless $clean;

    print $row;

    print
	"\n<td colspan=\"",18-$count,"\"></td>\n",
	"\n<td bgcolor=\"$RIGHTPAGECOLOR\" valign=\"bottom\" align=\"left\">",
	$cgi->submit(-name=>elements,-value=>$tab),
	"</td>\n",
	td($cgi->hidden(-name=>elements,-value=>$newln)),
	unless $clean;
    
    print
	"</tr>\n";
}

###
sub display_english {
    my ($abridged) = @_;
    @sentences = split(/\[/,$argument);
    my $count = 0;

    my $fontsize="<font size=-1>" if length($argument) > 320;

    print "$fontsize\n";
    
    foreach (@sentences) {
	if (/\]/) {
	    print
		"<sup><strong>",
		"<font color=\$LPC\">",
		++$count,
		"</font>",
		"</strong></sup>",
		"[";

	    if ($abridged and (/(\S+\s+){3}/)){
		/(\S+\s+\S+).*(\s\S+\].*)/;
		print "$1 ...$2\n";
	    } else {
		print "$_";
	    }
	    
	} else {
	    print;
	}
    }
    
    print "</font>" if $fontsize;
    print "<br>(<em>See below for unabridged argument.</em>)" if $abridged;

    print
	"<br>",
	"<font color=$INSTRUCTCOLOR>",
	"<strong>",
	"What is the main conclusion? ",
	"Enter it on the bottom row of your diagram.",
	"</strong>",
	"</font>"
	    unless $conclusion_ok or !$abridged;
	
    print "<br>";
}


###
sub check { #diagram 
    local $guess = $reverse_userdiag;
    @answers = split(/ro/,$answer);
    my $error;

    $conclusion_ok = &is_conclusion_ok($userconc, $answer);

    if ($conclusion_ok) {
	for (@answers) {
	    $error = &check_aux($_);
	    last unless $error;
	}
    }

    if ($error or !$conclusion_ok) {
	$msg = "Your diagram is incorrect or incomplete. ";
	
	if (&count_nontab_elements($userconc)>1) {
	    $msg.="The bottom row of your diagram must not contain more than one cell (except for tabs). ";
	} elsif ($conclusion_ok) {
	    my $level = "the main conclusion";
	    $level .= " and the row(s) above it"
		if $error =~ /more|fewer/ and &get_row($guess,1);
	    $err.="You have correctly identified $level, but "
		.&diagnose_error($error);
	} else {
	    $msg.="You have not correctly identified the main conclusion. ";
	}
	$msg .= " Keep going!";
	&display_argument(@userdiag);

	
    } elsif ($conclusion_ok) {
	$msg = "Congratulations: no errors were found.";
	&display_argument('clean',@userdiag);
	$cgi->delete('prob');
	print
	    "<center>",
	    "<hr>\n",
	    $cgi->startform,
	    $cgi->submit(-name=>'act',-value=>"Another from $POL::exercise?"),
	    "</center>\n",
	    $cgi->hidden('exercise'),
	    $cgi->hidden('prevchosen'),
	    $cgi->endform,
	    "</center>",
	    ;
    }

    &pol_footer;
    &end_polpage;
}

###
sub diagnose_error {
    my ($error_string) = @_;
    my $diagnosis;

    for ($error_string) {
	#print "<br>[diagnosis: $error_string]="; #debug
	if (/^(more\s*)+$/) {
	    $diagnosis .= " you need to remove the top row. ";
	} elsif (/^\d?(fewer\s*)+$/) {
	    $diagnosis .= " you need to add to the top of the diagram. ";
	} elsif (/^((fewer|more)\s*)+$/) {
	    $diagnosis .= " you do not have the right number of rows. ";
	} elsif (/morechunks.*(\d+)/) {
	    $diagnosis .= " you need more elements at row $1. ";
	} elsif (/fewerchunks.*(\d+)/) {
	    $diagnosis .= " you need fewer elements at row $1.";
	    $diagnosis .= &compare_rows(&get_row($answer,$1),
					&get_row($guess,$1));
	} elsif (/chunk.*(\d+)('.*')/) {
	    my $rownum = $1-1;
	    my $item = $2;

	    my $description;
	    if ($rownum) {
		my $description = 'element';
		$description = 'group' if $item =~ /'.*[^\d].*'/;
		$diagnosis .= " the $description ";
		$diagnosis .= &reversestring($item);
		
		if (/nochunk/) {
		    if ($description eq 'element') {
			$diagnosis .= " should not appear ";
		    } else {
			$diagnosis .= " contains elements that do not belong ";
		    }
		} else {
		    $diagnosis .= " contains elements that are not correctly connected to others, ";
		}
		$diagnosis .= "in the row that is $rownum level";
		$diagnosis .= "s" unless $rownum==1;
		$diagnosis .= " above the main conclusion. ";
		
#	    print "--$answer-- $guess--";
		
		$diagnosis .= &compare_rows(&get_row($answer,$rownum),
					    &get_row($guess,$rownum));
		
		$diagnosis .= " No element should begin with '0' -- delete or replace it with another number. " if $item =~ /0\'/;
		
	        $diagnosis .= " (Separate statement numbers must be separated by tabs, '+', or 'v'.) "
		    if $item =~ /^'\d\d+'$/;
	    } else {
		$diagnosis = "you need to indicate the support for this conclusion.";
	    }
	    
	} elsif (/support.*(\d+)('.*')/) {
            if ($1) {
                $row = "$1 row";
                $row .= "s" if $1 > 1;
                $row .= "in the row $1 level";
	    $row .= "s" unless $1==1;
	    $row .= " above the main conclusion. ";
            } else {
	        $row="on the bottom row. ";
            }

            $diagnosis .= " the item ";
            $diagnosis .= &reversestring($2);
            $diagnosis .= " does not have the correct support from the row above. ";
	} else {
	    $diagnosis .= " the program was unable to diagnose your error - '$error_string' - ";
	}
    }

# uncomment next line for debugging help
#    print "[$error_string]<p>";


    $diagnosis .= "<p>[This problem has more than one correct answer. The preceding advice may not apply to all alternatives.]<p>"
	if ($answer =~ /or/);

    return $diagnosis;
}

sub compare_rows {
    my ($arow,$grow) = @_;
#    print "comparing '$arow' '$grow'";#debug
    $num_a_elems = ($arow =~ /\d/g);
    $num_g_elems = ($grow =~ /\d/g);
    my $response;


    if ($num_g_elems < $num_a_elems) {
	$response .= " You appear to have have too few elements in this row. ";
    } else {
	$response .= " You appear to have too many elements ($numnums) in this row. "
	    if $num_g_elems > $num_a_elems;

	$response .= &compare_elements($arow,$grow);
    }

    return $response;
}

sub compare_elements {
    my ($arow,$grow) = @_;
#    print "matching '$arow' '$grow'<br>"; #debug
    my $response;
    foreach $element (split(/[$tab$anstab$ind$dep]+/,$grow)) {
#	print "look '$element'<br>";#debug
	next unless $element;
	$response .= " The element '$element' does not belong there. "
	    unless $arow =~ /$element/;
#	print "got $response<br>";#debug
    }
    return $response;
}


###
sub check_aux {
    my ($answer) = @_;
    $answer =~ s/$anstab/$tab/g;

    my @guess_rows = split(/$newln/,$guess);
    my @answer_rows =  split(/$newln/,$answer);
    my $response;
    
    #print "<p>Will compare guess[$guess] ($#guess_rows rows) to answer[$answer] ($#answer_rows rows)<p>"; #debug

    return 'more' if $#guess_rows > $#answer_rows;

#    for ($i=$#guess_rows;$i>=0;--$i) {
    for ($i=0;$i<=$#guess_rows;++$i) {
	my @guess_chunks = split(/$qtab+/,$guess_rows[$i]);
	my @answer_chunks = split(/$qtab+/,$answer_rows[$i]);

#	print "row $i : "; #debug
	
	# check chunk identity
      GUESS: foreach $gchunk (@guess_chunks) {
	  $gchunk =~ s/([$ind$dep]) \1/$1/ig; # get rid of doubled connectors
	  $gchunk =~ s/ $//; # get rid of trailing space
	ANSWER: foreach $achunk (@answer_chunks) {
	    #print "comparing $gchunk $achunk<br>"; #debug
	    $achunk =~ s/([$ind$dep]) \1/$1/ig;
	    $achunk =~ s/ $//;
	    next GUESS if &same_chunk($gchunk,$achunk);
	    }
	  if (&compare_elements($answer_rows[$i],$gchunk)) {
	      return "nochunk".($i)."'$gchunk'";
	  } else {
	      return "chunk".($i)."'$gchunk'";
	      
	  }
	  
      }
    }

    # check chunk support identity

    if (0) { # debug
	for (@guess_rows) { print "'$_'<br>"};
	print "<hr>";
	for (@answer_rows) { print "'$_'<br>"};
	print "<hr>";
    }
    
    for ($i=0;$i<$#guess_rows;++$i) {
	next unless $answer_rows[$i];
	my %answer = &find_supports(&reversestring($answer_rows[$i]),
				    &reversestring($answer_rows[$i+1]));
	my %guess = &find_supports(&reversestring($guess_rows[$i]),
				   &reversestring($guess_rows[$i+1]));
	
	for (keys(%answer)) {
	    #print "comparing support for $_ (at row $i):correct=$answer{$_} guess=$guess{$_}<br>";#debug
	    next if &same_chunk($answer{$_},$guess{$_});
	    $guess_rows[$i] =~ s/$qtab//g;
	    return "support".($i)."'$_'";
	}
    }
    return 'fewer' if $#answer_rows > $#guess_rows;
    return '';
}

###
sub same_chunk {
    my ($chunk1,$chunk2) = @_;
#    print "comparing [$chunk1] to [$chunk2]<br>"; #debug
    $chunk1 =~ s/\s//g;
    $chunk2 =~ s/\s//g;
    my @chunk1 = split(/($ind)+/i,$chunk1);
    my @chunk2 = split(/($ind)+/i,$chunk2);

  FIRST: foreach $thing1 (@chunk1) {
    SECOND: foreach $thing2 (@chunk2) {
#	print "things:'$thing1','$thing2'<br>"; #debug
	next FIRST if &same_dependent_group($thing1,$thing2);
    }
      return 0;
  }
    return 1;
}

###
sub same_dependent_group {
    my ($grp1,$grp2) = @_;
    my @grp1 = split(/[$dep]+/,$grp1);
    my @grp2 = split(/[$dep]+/,$grp2);
    
  FIRST: foreach $thing1 (@grp1) {
    SECOND: foreach $thing2 (@grp2) {
#	print "things:$thing1,$thing2<br>";
	next FIRST if $thing1 eq $thing2;
    }
      return 0;
  }
    return 1;
}

###
sub find_supports {
    my ($lower,$upper) = @_;
#    print "upper: $upper lower: $lower<br>";#debug
    my @lower = split(/ */,$lower);
    my @upper = split(/ */,$upper);
    my %result; my $count;
    foreach $element (@lower) {
	if ($element=~/\d/) {
	    if ($count > $#upper or
		$element =~ /$qtab|$anstab/ or
		@upper[$count] =~ /$qtab|$anstab/) {
		$result{$element} = 0;
	    } else {
		$result{$element} = &get_chunk($count,@upper);
#		print "got $element supported by $result{$element}<br>"; #debug
	    }
	}
	++$count;
    } # end foreach $element
    return %result;
}

###
sub get_chunk {
    my ($place,@row) = @_;
    my $result = $row[$place];
#    $result = 0 unless $result =~ /\d+/;
    my $i;
    for ($i=$place-1;$i>=0;--$i) {
	last if $row[$i] =~ /$qtab/;
	$result = $row[$i].$result;
    }
    for ($i=$place+1;$i<=$#row;++$i) {
	last if $row[$i] =~ /$qtab/;
	$result .= $row[$i];
    }
#    print "get_chunk returns $result<br>";#debug
    return $result;
}

sub get_row {
    my ($string,$rownum) = @_;
    return  (split(/$newln/,$string))[$rownum-1];
}

sub is_conclusion_ok {
#    print "[@_]"; #debug
    my($guess,$answers) = @_;
    my @anslist = split(/ro/,$answers); # or backwards!
#    print "found $anslist[0] in $answers"; #debug
    return 0 unless $guess;

    for (@anslist) {
#	print "compare '$guess' to '",&get_conclusion($_),"'"; #debug
	return 1 if $guess == &get_conclusion($_);
    }
    return 0;
}

###
sub get_conclusion {
    my ($diag) = @_;
#    print "finding conclusion in '$diag': "; #debug
    return '' if $lastine =~ /\d.\d/;
    $diag =~ s/^:?([^:]+)/$1/;
    $diag =~ /(\d+)/;
#    print "[got $diag = '$1']<br>"; #debug

    return $1;
}

sub reversestring {
    return join('',reverse(split('',@_[0])));
}

sub count_nontab_elements {
    my $result;
    for (@_) {
	++$result unless /$qtab|$anstab/;
    }
    return $result;
}

###
sub get_out {
    print $cgi->user_agent;
    print "<p>Argument diagramming is not available to users of Microsoft Internet Explorer version 3 or earlier.  Upgrade your browser or use Netscape if you wish to practice diagramming.";
    &pol_footer;
    &end_polpage;
}

sub reveal_diagram {
    &pol_header("Exercise $POL::exercise, Argument Diagrams",
		'Peek at answer');

    print "Here is an arrangement of premises and conclusion that would be accepted as correct...";
    $clean = 1;

    @answers = split(/ro/,$answer);
    #print $answers[0];

    @rows = split(':',&reversestring($answers[0]));
    
    my $row1; my $row2;
    my $prev; local @prevcolorrow; local @colorrow;
    my $count = 0; my $rowcount = 0;
    my $loopcount = 0;

    print
	"\n",
	"<center>",
	"<!--begin diagram table-->\n",
	"<table -style=\"border: $border; ",
	"  cellspacing: 0px; ",
	"  cellpadding: 2px; ",
	"  align: center;\"",
	">",
	;
    

    for (@rows) {
        ++$loopcount;
	my $row = $_;
	$row =~ s/\>//g;
	&output_workrow(&makebox($row),$count);
    }
    

    print
	"</td></tr>",
	"</table><!--end containing table-->",
	"</center>",
	"<hr>",
	;

    &display_english;
    print "<p>Use the browser's back arrow to return to your previous work.</p>";
    
}
