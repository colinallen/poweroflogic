#!/usr/bin/perl

# proof.pl

# This is the main proofchecking routine
#  - requires wff-subrs.pl line-subrs.pl errors
#  - runs from command line using stdin/stdout
#  - to be wrapped in cgi script

$ENV{'PATH'} = '/bin:/usr/bin:/usr/local/bin';

#require "../lib/header.pl";
require "../lib/wff-subrs.pl";
require "../Proof/line-subrs.pl";
require "../Proof/rules.pl";
require "../Proof/errors";

$demo = 0;
$seq = 0;

# FIRST SLURP IN THE INPUT, DISCARDING LINES
# UNTIL A SEQUENT IS FOUND (MATCHING :. OR .:)
# THEN GRAB ALL REMAINING NON-BLANK LINES
while (<>) {
    last if /^\.$/; # if you can't type control D use single dot on line.
    chomp $_;
    $rawline = $_;
    s/\s//g;     #eliminated white space
    next if !$_; #skip blank lines
    
    &error("Error:<pre>".ascii2utf_html($rawline)."</pre>".
	   "Every line of proof must be properly numbered.")
	unless /^\|*\d+|\.:|:\./;

    if (!$seq) { # still looking for a conclusion
	if ( /(.*)(\.:|:\.)(.*)/ ) { # we have a conclusion
	    $conclusion=$3;
	    if ($1) {
		$premises.= &get_linesent($1);
		push @proof,$1;
	    }
	    $seq=1;
	} else { # a premise line prior to conclusion
	    $premises .= &get_linesent($_).","; # comma for more premises 
	    push @proof,$_;
	}
    } else { # just an ordinary line of proof
	push @proof,$_;
    }
}

&error($NOSEQ) if !$seq;

print
    "\n<table border=\"0\">",
    "\n<tr>",
    "<th align=\"left\" valign=\"top\">",
    "Premises:",
    "</th>",
    "<td><code>",ascii2utf_html($premises),"</code></td>",
    "</tr>"
    if $premises;

print
    "\n<tr><th align=\"left\">Conclusion:</th>",
    "<td><code>",ascii2utf_html($conclusion),"</code></td>",
    "\n</tr>\n</table>\n",
    "<strong>Proof attempt:</strong>\n",
    "<br />",
    ;

# CHECK PREMISSES FOR WFFNESS
$prems = $premises; # make a copy to leave global alone
$prems =~ s/,,/,/g; # delete duplicate commas

while ($prems) {
    ($nextprem,$prems) = split(/,/,$prems,2);
    if (not &wff($nextprem)) {
	my $errmsg=$NOTWFF;
	$errmsg.=$NUMINWFF if $nextprem=~/\d/;
	$errmsg.=$NOCAPS if $nextprem !~ /[A-Z]/;
	&error("Premise '".ascii2utf_html($nextprem)."'",$errmsg);
    }
}

# CHECK CONCLUSION FOR WFFNESS
if (not &wff($conclusion)) {
    my $errmsg=$NOTWFF;
    $errmsg=$NOCAPS if $conclusion !~ /[A-Z]/;
    &error("Conclusion '".ascii2utf_html($conclusion)."'",$errmsg);
}

# CHECK EACH LINE OF PROOF
foreach $line (@proof) {
    ++$linecount;
    
    $indent = &get_indent($line);
    $linenumber  = &get_linenum($line);
    $sentence    = &get_linesent($line);
    $annote  = &get_annotation($line);
    
    # CHECK LINE NUMBER
    &error(&badline($line),$LINENUMNIL,$linecount) if !$linenumber;
    &error(&badline($indent,$linenumber,$sentence,$annote),
	   $linenumber,$LINENUMFORM,$linecount)
	if $linenumber !~ /^\d\d?$/;
    &error(&badline($indent,$linenumber,$sentence,$annote),
	   $linenumber,$LINENUM,$linecount)
	if $linenumber != $linecount;
    
    # CHECK FOR STRAY CONCLUSIONS
    &error(&badline($indent,$linenumber,$sentence,$annote),
	   $DOUBLECONC)
	if $line =~ /\.:|:\./;
    
    # CHECK SENTENCE EXISTS
    &error(&badline($indent,$linenumber,$sentence,$annote),
	   ascii2utf_html($sentence),$NOSENT)
	if $sentence =~ /^\s*$/;
    
    # CHECK RULE IS CITED
    if ($annote =~ /^[\d,]*$/ and !&ispremise($sentence,$premises)) {
	if (!&wff($sentence)) {
	    &error(&badline($indent,$linenumber,$sentence,$annote),
		   $BADFORMAT);
	} else {
	    &error(&badline($indent,$linenumber,$sentence,$annote),
		   ascii2utf_html($sentence),$NOTPREM);
	}
    }
    
    # CHECK WFFNESS OF SENTENCE
    if (not &wff($sentence)) {
	my $errmsg=$NOTWFF;
	$errmsg.=$NUMINWFF if $sentence=~/\d/;
	$errmsg.=$WFFZERO if $sentence=~/0/;
	$errmsg.=$NOCAPS if $sentence !~ /[A-Z]/;
	&error(&badline($indent,$linenumber,$sentence,$annote),
	       ascii2utf_html($sentence),$errmsg);
    }

    # CHECK ASSUMPTIONS
    if ($annote =~ /assume/i) {

	push @assumption_stack, $linenumber;

	if ($linenumber == 1 && $indent ne "|") {
	    &error(&badline($indent,$linenumber,$sentence,$annote), $INDENT);
	} elsif ($linenumber != 1) {
	    $previndent = &get_indent($proof[$linenumber-2]); # array offset is 2
	    if (length($indent) != length($previndent)+1) {
		&error(&badline($indent,$linenumber,$sentence,$annote), $INDENT);
	    }
	}
	
    }

    # CHECK OTHER RULES
    if ($annote && $annote !~ /assume/i) {
	
	# CHECK TO SEE WHETHER LINES CITED IN ANNOTATION ARE AVAILABLE
	# FOR INFERENCES - I.E. NOT TOO HIGH OR INSIDE DISCHARGED BOXES
	my($premnums)=get_ann_nums($annote);
	while ($premnums) {
	    ($curr, $premnums) = split(/,/,$premnums,2);
	    &error(&badline($indent,$linenumber,$sentence,$annote),
		   "$curr $TOOHIGH") if $curr >= $linenumber;
	    
	    my $available = 0;
	    foreach $available_line (@available_lines) {
		if ($curr == $available_line) {
		    $available = 1;
		    last;
		}
	    }
	    &error(&badline($indent,$linenumber,$sentence,$annote),
		   $curr, $NOTAVAILABLE) unless $available;
	}
	
	$rule=&get_rule($annote);
	$rule=~tr/[a-z]/[A-Z]/;
	$rule=$rule_aliases{$rule} if $rule_aliases{$rule};
	
	# NOTE: THE FOLLOWING EVAL IS POTENTIALLY INSECURE BECAUSE USER
	# MAY ENTER ANYTHING AS ANNOTATION.  IMPLEMENTED SECURITY FEATURES:
	# - spaces are eliminated so multiword commands will fail
	# - implemented list of known rules in rules.pl
	if ($implemented{$rule}) {
	    $rulemsg = eval "$rule(\@proof,\$linenumber)"; # fire off  rule
	    $rulemsg = "$rule: $@" if $@;
	} elsif ($implemented{$rule} eq 'n') {
	    pop @assumption_stack if $rule eq RAA;
	    &warning;
	} else {
	    $rulemsg = "$rule: $NOSUCHRULE";
	}
	if ($rulemsg) {
	    &error(&badline($indent,$linenumber,$sentence,$annote), $rulemsg);
	}
    }
	
    # CHECK INDENTATION
    $previndent = &get_indent($proof[$linenumber-2]); # array offset is 2
    if (($linenumber > 1) &&
	((($annote =~ /raa|cp/i) && # RAA AND CP DECREASE INDENT
	  (length($indent) != length($previndent)-1))
	 ||
	 (($annote !~ /assume|raa|cp/i) && # ALL OTHERS STAY SAME
	  (length($indent) != length($previndent))))) {
	&error(&badline($indent,$linenumber,$sentence,$annote),
	       $INDENT);
    }

    # PASSED ALL TESTS
    push @available_lines, $linenumber;
    print &goodline($indent,$linenumber,$sentence,$annote);
    
    # CHECK TO SEE WHETHER PROOF IS COMPLETE
    if (($indent eq "") # we have discharged all extra assumptions
	and
	&samewff($sentence,$conclusion)) {
	print "Congratulations:  No errors were found in the proof.\n";
	exit;
    }
}

print
    "The proof is incomplete. The ",
    &wff($conclusion),
    " ",
    ascii2utf_html($conclusion),
    " remains unproven.\n";

# SUBROUTINE TO CHECK MEMBERSHIP IN PREMISES
# This can be simplified now that we are no longer
# sending in premise separately from the proofs
sub ispremise {
    my ($in,$prems) = @_;
    while ($prems) {
	($nextprem,$prems) = split(/,/,$prems,2);
	return 1 if $in eq $nextprem;
    }
    return 0;
}


##################################################################
# Various print $outing and formatting subroutines that should perhaps
# go elsewhere

# SUBROUTINE TO REPORT LOGIC ERRORS
sub error { # ERRORHEAD and ERRORFOOT are in the error file
    print $ERRORHEAD;
    foreach $string (@_) {
	print "$string";
    }
    print $ERRORFOOT;
    exit;
}

# SUBROUTINE TO WARN ABOUT UNIMPLEMENTED RULES
# This is for demo purposes only.  Must be removed in final version
sub warning {
    print "<br /><font color=\"maroon\">The rule CONT is temporarily disabled; the next line has not been properly checked.</font>\n";
#    print "<br /><font color=maroon>WARNING: The next line mentions a rule that is not yet available in this demo; it has not been properly checked.</font>\n";
}

# FORMATS GOODLINES OF PROOF
sub goodline {
    return "<tt>  OK " . &format_line(@_)."</tt><br />";
}

# FORMATS BAD LINES OF PROOF
sub badline {
    return "<tt>  ** " . &format_line(@_)."</tt><br />";
}

# THIS IS THE COMMON FORMAT FOR ALL LINES OF PROOF
# Currently just a quick hack.  Can be improved considerably.
sub format_line {
    my ($result,$i);
    my ($ind,$num,$sent,$ann) = @_;
    my $nums = &get_ann_nums($ann);
    $nums =~ s/,/-/
	if ($ann =~ /cp|raa/i and $nums =~ /^\d+,\d+$/);

    $result .= "$ind$num. ";
    $result = pack "A6", $result; # up to 6 spaces
	
    $result .= ascii2utf_html($sent); 

    ##offset for non-printed chars from unicode translation (e.g. -> becomes &#8310;)
    $offset = length(ascii2utf_html($sent)) - length($sent)
	+ (ascii2utf_html($sent) =~ tr/&//);  #add 1 for each translated character
    $offset+=30; #add 30 for the first packing
    $result = pack "A$offset", $result # up to 36 spaces
	if length($result) < $offset; 
    $result .= $nums . ", " if $nums;
    my $ruleinput=uc(&get_rule($ann));
    $ruleinput=$rule_aliases{$ruleinput} if $rule_aliases{$ruleinput};
    $result .= $implemented{$ruleinput}; # canonical form
	$offset+=10; #Add 10 more to bring us up to 40 spaces
    $result = pack "A$offset", $result #
	if length($result) < $offset; 
    $result .= "\n";
    return $result;
}

sub analyse_ruleapp {
    my ($number,$conc,$annote) = @_;
    my ($premnums)=get_ann_nums($annote);
    my $curr;
    my $currsent;
    
    print
	$ERRORHEAD,
	"Line $number attempts to conclude a ",
	&wff($conc),
	" from ";

    print "no premises." if !$premnums;
	
    while ($premnums) {
	($curr, $premnums) = split(/,/,$premnums,2);
	$currsent = &get_linesent($proof[$curr-1]);
	print
	    &wff($currsent),
	    " (line $curr), ";
    }
    print
	"an improper format for this rule...",
	$ERRORFOOT;
}
