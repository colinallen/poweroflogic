## this file is required by grader.pl
## it requires

require '../lib/wff-subrs.pl';
require '../lib/qlwff-subrs.pl';
require '../Grader/proofgrader-subrs.pl';
require '../Grader/ttgrader-subrs.pl';
require '../Grader/symbgrader-subrs.pl';

#### defines subroutines

# This is the top level subroutine to call on a properly hashed input
sub grade_hash {
    my ($hashref) = @_;
    foreach my $problem (@{ $$hashref{'problems'} }) {
	my $probtype = $$hashref{$problem}{'type'};

        # go through each problem according to type

	if (lc($probtype) eq 'proof') { ## Proofs
	    ($$hashref{$problem}{'result'},$$hashref{$problem}{'evalmsg'}) =
		&check_proof_result($$hashref{$problem}{'question'},
				    $$hashref{$problem}{'answer'});
	    
 	} elsif ($probtype =~ /TT_(full|form|abbr)/i) {    ## TTs
 	    ($$hashref{$problem}{'result'},$$hashref{$problem}{'evalmsg'}) =
 		&check_tt_result($probtype,$$hashref{$problem}{'question'} . "\n" .
 				    $$hashref{$problem}{'answer'});

	} elsif ((lc($probtype) eq 'symb') or 
		 (lc($probtype) eq 'trans')) {    ## Symbolization
	    
	    # question contains instructor's correct answer; answer contains student response
	    ($$hashref{$problem}{'result'},$$hashref{$problem}{'evalmsg'}) =
		&check_symb_result($$hashref{$problem}{'question'},
				   $$hashref{$problem}{'answer'});

	} else {
            ($$hashref{$problem}{'result'},$$hashref{$problem}{'evalmsg'}) =
              ("","Questions of problem type <strong>$probtype</strong> are not currently supported.")
          }
    }
}

sub compare_args { # <argstring1,argstring2> : boolean based on equivalence of argstrings
    return &samearg(@_); # subroutine defined in lib/wff-subrs.pl
}

## old code - can be junked soon (CA 08/05/2003)
		      
sub old_compare_args { # <argstring1,argstring2> : boolean based on equivalence of argstrings
    my ($arg1,$arg2) = @_;
    my @arg1 = &canonize_arg($arg1);
    my @arg2 = &canonize_arg($arg2);
    return 0 if $#arg1 != $#arg2;
    my $i = 0;
    foreach $form (@arg1) {
	return 0 unless &samewff($form, $arg2[$i]);
	++$i;
    }
    return 1;
}

sub canonize_arg { # <argstring> : cleans up and sorts argstring for comparison
    my ($arg) = @_;
    $arg =~ s/\s+//g;
    my ($premises,$conclusion) = split(/$LSO|$RSO/,$arg);
    my @result = split(/,/,$premises);
    @result = sort @result;
    push @result,$conclusion;
    return @result;
}

## XML <-> HASH manipulation subroutines

sub parse_xml { # <xmlstring> : XML -> HASH
    my @input = @_;
    my %HASH = ('created'=>$ts[$#ts]);

    my $linecount=0;
    local $problem_id="";

    my $part_tag; # accumulator for tags split across lines

    for (@input) {
	++$linecount;
	s/\r//g;           # get rid of ^M
	s/<\?[^>]*>//;     # zap declarations
	next if /^\s*$/;   # ignore empty lines
	s/->/-&gt;/g;      # special case conditional not a tag
	s/<-/&lt;-/g;      # special case biconditional not a tag

	if ($part_tag) { # looking for the tag closure
	    if (s/^([^>]*>.*)/$part_tag$1/) { # closure
		$part_tag = "";
	    } elsif (/^[^>]</) {
		&xml_error("Can't have < in middle of $part_tag");
	    } else {
		$part_tag .= $_;
		next;
	    }
	} elsif (s/(.*?)(<[^>]*)$/$1/) {
	    $part_tag = $2; # defer to next line
	}
	
	if (!/<\/?[^>]+>/) { # no tags
	    $element_content .= "$_\n" if $_;
	} else { # tags
	    ## if we aren't closing open tag, everything else is content
	    
	    while (s/\s*(.*?)<(\/?\w[^>]+)>\s*(.*?)\s*/$3/) { # as long as we've got 'em
		# print STDERR "residue = '$3'\n" if $3;
		$element_content .= $1;
		my $tag = $2;
		my ($thistag,$attributes) = split(/\s+/,$tag,2);
		
		&check_tag_attributes($thistag,$attributes);
		my $currtag = $ts[$#ts];

		if ($thistag =~ s/^\/(.*)/$1/) { ## close tag
		    # print STDERR "$linecount. close $thistag\n";
		    if ($thistag ne $currtag) {
			&xml_error("Can't close &lt;$currtag&gt; with &lt;/$thistag&gt; at line $linecount");

		    } else {
			&xml_error("Problem $problem_id must contain a non-empty question")
			    if lc($thistag) eq 'problem'
			    and !$HASH{$problem_id}{'question'};
			&xml_error("Problem $problem_id must contain a non-empty answer")
			    if lc($thistag) eq 'problem'
			    and !$HASH{$problem_id}{'answer'};
			
			&store(\%HASH,$thistag,$element_content)
			    unless $thistag eq 'problem';
			## clean up
			pop @ts;
			$element_content = "";
			$problem_id = 0 if lc($closetag) eq 'problem';
		    }
		} else { # open tag
		    #print STDERR "$linecount. open $thistag $attributes\n";
		    unless ($tag =~ /\/$/) { # self-contained
			push @ts, $thistag;
			if (lc($thistag) eq 'problem') {
			    &store(\%HASH,$thistag,"",$attributes);
			    # store sets #problem_id
			}
		    }  
		}
	    }
	    # print STDERR "Adding '$_' to $ts[$#ts]\n" if $_;
	    $element_content .= "$_\n"
		if $_; # left over from while loop add EOL
	}
    }

    &xml_error("Submission must contain at least one problem")
	unless @{ $HASH{'problems'} };

    &xml_error("Incomplete submission received; end of document reached before &lt;/$ts[$#ts]&gt; ending tag was found")
	unless $ts[$#ts] =~ /^\d+$/; # time stamp

    return %HASH;
}

sub check_tag_attributes { # <tag,attstring>
    my ($tag,$attstring) = @_;
    if (lc($tag) eq 'problem') {
	$attstring =~ /type="(\w+)"/;
	my $type = $1;
    }
    return 1;
}

sub store { # adds material to hash, called by parse_xml
    my ($hashref,$element,$content,$attributes) = @_;
    $content =~ s/-&gt;/->/g; # allow conditionals
    $content =~ s/&lt;-/<-/g; # and biconditionals
    if (lc($element) eq 'pageout_id') {
	if ($$hashref{'pageout_id'} and
	    $$hashref{'pageout_id'} ne $content) {
	    $error .= "conflicting pageout_id $content\n";
	} else {
	    $$hashref{'pageout_id'} = $content;
	}
    } elsif (lc($element) eq 'submission' or lc($element) eq 'response') {
	$$hashref{'type'} = lc($element);
    } else {
	if (lc($element) eq 'problem') {
	    $attributes =~ /id="(\S+)"/;
	    $problem_id = $1;
	    $attributes =~ /type="(\S+)"/;
	    my $type = $1;
	    if ($type) {
		# store in hash
		push @{$$hashref{'problems'}},$problem_id;
		$$hashref{$problem_id}{'type'} = $type;
	    } else {
		$error.= "Problem tag at line $linecount has no type\n";
	    }
	} elsif ($problem_id) {
	    print STDERR "storing $content as $element\n";
	    $$hashref{$problem_id}{$element} = $content;
	} else {
	    $error.= "Problem tag at line $linecount has no id\n";
	}
    }
}

sub xmlify { # <hashref> : HASH -> XML
    my ($hashref) = @_;

    my $xml;
    if ($$hashref{'error'}) { # parsing error
	$xml = $GR::grader_submission;
	$xml .= "\n<ERROR>$$hashref{'error'}</ERROR>\n";
	return $xml;
    }

    $xml = "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n";
    $xml .= "<$$hashref{'type'}>\n";
    $xml .= "\t<pageout_id>$$hashref{'pageout_id'}</pageout_id>\n";

    foreach my $problem (@{$$hashref{'problems'}}) {
	
	$xml .= "\t<problem id=\"$problem\" type=\"$$hashref{$problem}{'type'}\">\n";

	$xml .= "\t\t<question>\n";
	$xml .= &ltfix("$$hashref{$problem}{'question'}\n");
	$xml .= "</question>\n";
	    
	$xml .= "\t\t<answer>\n";
	$xml .= &ltfix("$$hashref{$problem}{'answer'}\n");
	$xml .= "\t\t</answer>\n";

	if ($$hashref{$problem}{'type'} eq "Trans") {
	    $xml .= "\t\t<storedanswer>\n";
	    $xml .= &ltfix("$$hashref{$problem}{'storedanswer'}\n");
	    $xml .= "\t\t</storedanswer>\n";
	}

	$xml .= "\t\t<result>$$hashref{$problem}{'result'}</result>\n";
	
	$xml .= "\t\t<evalmsg>\n";
	$xml .= &ltfix("$$hashref{$problem}{'evalmsg'}\n");
	$xml .= "\t\t</evalmsg>\n";

	$xml .= "\n\t</problem>\n";
    }

    $xml .= "</$$hashref{'type'}>\n";

    return $xml;
}

sub xml_error {
    my ($msg) = @_;
    $msg =~ s/</&lt;/g;
    $msg =~ s/>/&gt;/g;
    if ($ENV{'SERVER_NAME'}) { # cgi context
	print $cgi->header;
	$HASH{'error'} = $msg;
	&log_grader_event;
    }
    print "XML FORMAT ERROR : $msg";
    exit;
}

sub ltfix {
    my ($result) = @_;
    $result =~ s/<-/&#60;-/g;
    return $result;
}

1; # required by require
