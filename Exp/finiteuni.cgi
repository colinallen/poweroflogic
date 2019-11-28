#!/usr/bin/perl

require '../lib/header.pl';
require '../Exp/exp.pl';
require '../Exp/evaluate-exp-att.pl';

$mailto = 'random';

# $polmenu{'Main menu'} = "../menu.cgi";

$program = $cgi->url;

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


if ($POL::exercise) { # add menu items
    my($chapter,$rest)=split(/\./,$POL::exercise,2);
    $polmenu{"More from Ch. $chapter"} = "../menu.cgi?chapter=$chapter";
    $polmenu{"More from Ex. $POL::exercise"} = "$program?exercise=$POL::exercise&prevchosenstring=$prevchosen_string&msfu=".rand
	if $POL::argument or $POL::probnum;
} else {
    local $subtitle = 	"Finite Universe Models";
    local $instructions = "<center><strong>This feature is not supported for Finite Universe models. Please return to the Main Menu and make your selection from there. </strong></center>";

    &start_polpage;
    print
	$cgi->startform();

    &pol_header($subtitle,$instructions);

    &footer();

    &bye_bye();
}

for ($POL::usrchc) {
    /Expand/   and do { &user_expand; last };
    /Check/    and do { &check_expansions; last };
    /Evaluate/ and do { &evaluate_exp_att; last };
    &pick_arg;
}

sub pick_arg {
    my @problems;
    my ($chapter) = split(/\./,$POL::exercise,2);
    my $probfile = "$EXHOME$chapter/$POL::exercise";
    my $subtitle = "Exercise $POL::exercise, Demonstrating Invalidity";


    my $instructions = &get_preamble($probfile);
    
    $cgi->delete('att'); # delete any previous selection
    
    ## Create @problems: just a list of the unformatted problems in the prob file

    $probfile =~ s/\||\.\.//g; # close pipeline exploit; CA 9-17-2004
    open(FILE,$probfile) || &html_error("Could not open problem file $probfile");
    while (<FILE>) {
	next if /^\#|^\w*$/;
	chomp;
	push @problems, $_;
    }
    close(FILE);
    
    &start_polpage('Choose an argument');

    $instructions .= $PREVCHOICEINSTRUCTION if @POL::prevchosen;
    
    &pol_header($subtitle,$instructions);  # create outer table, print the PoL header and instructions
    
    print              # create a table containing all the problems in the exercise
	"<table width=\"100%\" border=0><!-- argument selection table -->\n";
    
    my $count=0;
    
    foreach $argument (@problems) {
	++$count;
	$pretty_arg = &prettify_argument($argument);
	#	$pretty_arg =~ s/[<]/&lt;/g;
	#	$pretty_arg =~ s/[>]/&gt;/g;
	#	$pretty_arg =~ s/(:\.)|(\.:)/<img align=bottom src=$therefore>/;
	#	$pretty_arg = "(Too long to display)" if length($pretty_arg) > 85;
	#	$pretty_arg =~ s/(:\.)|(\.:)/<img align=bottom src=$therefore>/ if $pretty_arg !~ /Too/;

	my $button_image = $prevchosen{$count} ? $smallgreyPoLogo : $smallPoLogo;
	
	print 
	    Tr(td({-valign=>'middle',-align=>'left'},
		  $cgi->startform,
		  $cgi->image_button(-name=>'void',
				     -src=>$button_image),
		  $cgi->hidden(-name=>'usrchc', -value=>'Expand'),
		  $cgi->hidden(-name=>'exercise',-value=>$POL::exercise),
		  $cgi->hidden(-name=>'probnum',-value=>$count),
		  $cgi->hidden('prevchosen'),
		  $cgi->hidden(-name=>'argument',-value=>$argument),
		  $cgi->endform,
		  ),

	       td({-valign=>'center',-align=>'left',-bgcolor=>'#dddddd'},
		  "<font size=-1>",
		  $cgi->strong("#$count"),
		  "</font>",
		  $cgi->endform,
		  ),
	       
	       td({-valign=>'middle',-align=>'left'},
		  "<tt>\n",
		  ascii2utf_html($pretty_arg),
		  "</tt>\n"));
    }
    
    print # close the table containing the problems
	"</table>",
	"<!-- close argument selection table -->\n";  
    
    &pol_footer;
    &end_polpage;

}

sub user_expand {
    $subtitle = "Exercise $POL::exercise Problem $POL::probnum\n" if $POL::exercise;

    &start_polpage('Finite Interpretation Method');
    &pol_header($subtitle);

    print &expansions_form;
    &pol_footer;
    &end_polpage;


    
}

sub expansions_form {
    # named 'theconclusion' so that it comes after 'premise' alphabetically
    ($premises,$theconclusion) = split(/\.:|:\./,$POL::argument,2);
    @premises = split(/\, /,$premises);

#    $cgi->delete_all;
    my @form;

    my $foo = $POL::argument;
    $foo =~ tr/A-Z/A-Z/;
    my $numpreds = &count_preds($POL::argument);
    my @universes;
    my $i=0;
    my ($constants,$numconstants) = &get_constants($POL::argument);
    $constants = 'a' if !$constants;

    for($i=0;$i<2**$numpreds;++$i){
	my $entities = $constants;
	my $nextobj = 97; # start with 'a'
	my $j;
	for($j=0;$j<$i;++$j){
	    my $char = chr($nextobj+$j);
	    while ($entities =~ /$char/) { ++$char; } 
	    $entities .= ",";
	    $entities .= $char;
	}
	push @universes, $entities;
    }
	$i = 0;
	$onsubmit="replaceCharsRev(document.getElementById('theconclusionu'));\n";
	for(@premises) {
		++$i;
		$onsubmit .= "replaceCharsRev(document.getElementById('premiseu$i'));\n";
	}
	$onsubmit .= "return true;\n";
    push @form, ("<center>",
	     "<script language=\"javascript\" type=\"text/javascript\" src=\"/5e/javascript/replace.js\" charset=\"UTF-8\"></script>",
		 "<script language=\"javascript\" type=\"text/javascript\" charset=\"UTF-8\">\nfunction fixInput() {\n $onsubmit }</script>",
		 $cgi->startform(
		 		-onsubmit=>'fixInput()'
				#-onsubmit=>"replaceCharsRev(document.getElementById('premise1'))"
				),
		 "Select universe:",
		 $cgi->popup_menu(-name=>'universe',
				  -values=>\@universes,
				  -default=>$POL::universe),
		 "<p>");
    
    $i = 0;
    for (@premises) {
		++$i;
		push @form, (
			     $cgi->hidden(-name=>"premise$i",
					  -override=>1,
					  -value=>$_),
			     "Expand the premise ",
			     "<tt>",ascii2utf_html($_),"</tt> ",
			     "to its statement logic equivalent:",
			     "<br>",
			     $cgi->textfield(-size=>50,
					     -style=>'font-family: monospace',
					     -name=>"premise$i",
						 -id=>"premiseu$i",
					     -onkeyup=>'process(this)',
					     -override=>1,
					     -value=>@{"POL::premise$i"}[1]),
			     "<p>");
    }
    
    push @form, ($cgi->hidden(-name=>'theconclusion',
			      -value=>$theconclusion,
			      -override=>1),
		 "Expand the conclusion ",
		 "<tt>",ascii2utf_html($theconclusion),"</tt> ",
		 "to its statement logic equivalent:",
		 "<br>",
		 $cgi->textfield(-size=>50,
				 -style=>'font-family: monospace',
				 -name=>'theconclusion',
				 -id=>'theconclusionu',
				 -onkeyup=>'process(this)',
				 -override=>1),
		 "<br>",
		 $cgi->hidden(-name=>'exercise',-value=>$POL::exercise),
		 $cgi->hidden(-name=>'probnum',-value=>$count),
		 $cgi->hidden('prevchosen'),
		 $cgi->submit(-name=>'usrchc',
			      -value=>'Check Equivalences'),
		 $cgi->hidden(-name=>'argument',-value=>$POL::argument),
		 $cgi->endform(),
		 "</center>");
    
    return join "\n", @form;

}

sub count_preds {
    local $preds = $_[0];
    $preds =~ s/[^A-Z]//g;
    local @preds = split(//,$preds);
    $preds = "";
    foreach $pred (@preds) {
	$_ = $preds;
	next if eval("tr/$pred/$pred/");
	$preds .= "$pred";
    }
    return length($preds);
}

sub get_constants {
    my ($arg) = @_;
    $arg =~ s/[^a-u]//g;
    $arg =~ s/([a-u])/$1 /g;
    my @constants = split(/ /,$arg);
    my $constants = "";
    foreach $constant (sort @constants) {
	$_ = $constants;
	next if eval("tr/$constant/$constant/");
	$constants .= "$constant,";
    }
    my $numconstants = length($constants)/2;
    chop $constants;
    return ($constants,$numconstants);
}

sub translator { # generate a translation scheme from expanded argument
    my ($argument) = @_;
    my @atoms;
    my @scheme;
    while ($argument =~ /([A-Z][a-u])/) {
	my $next = $1;
	push @atoms, $next;
	$argument =~ s/$next//g;
    }
    my $nextletter = 'A';
    for (sort @atoms) {
	push @scheme, $nextletter, $_;
	++$nextletter;
    }
    return @scheme;
}

sub check_expansions {
    my $universe = $cgi->param('universe');

    $subtitle =
	"Exercise $POL::exercise Problem $POL::probnum\n"
	    if $POL::exercise;

    &start_polpage('Finite Interpretation Method');
    &pol_header($subtitle);
    
    print 
	"<center>\n",
	"<strong>Checked equivalences for universe: ",
	"<em>$universe</em></strong>\n",
	"</center>\n",
	"<p>\n";
        
    my @param_names = $cgi->param;
    my @entities = split(/,/,$universe);
    my $aok = '';
    
    print
	"<table border=1 align=center width=90%><!-- expansions table -->\n",
	"<tr><th>Original</th><th>Expanded</th><th>Evaluation</th><tr>";


  FOO:
    for (sort @param_names) {
	next unless /premise|theconclusion/;
	my @pair = $cgi->param($_);

	$pair[0]=~s/\s//g;
	my $expanded = &expand_qwff(&add_outer_parens($pair[0]),@entities);
	$expanded =~ s/\s//g;	

	my $attempt = $pair[1];
	$attempt =~ s/\s//g;

	print "<tr><td>";

	print
	    "<tt>",ascii2utf_html($pair[0]),"</tt>",
	    "</td><td>",
	    "<tt>",ascii2utf_html($pair[1]),"</tt>";

	print "&nbsp;" if !$pair[1];
	print "</td>\n<td align=left>\n";

	my $le = length($expanded);
	my $la = length($attempt);
	my $atype = &wff($attempt);
	my $etype = &wff($expanded);
	my $errmsg = '';
	
      ERRORS: {
	    if (!$atype) {
		$errmsg = "Your expansion is not a wff" if $pair[1];
		$errmsg = "An expansion has not been given" if !$pair[1];
		last ERRORS;
	    }
	    if (!$etype) {
		$errmsg = "The original expression '".ascii2utf_html($pair[0])."' does not appear to be well formed (".ascii2utf_html($expanded).")";
		last ERRORS;
	    }
	    if ($etype ne $atype) {
		$errmsg = "Your expansion is of the wrong type; it is a $atype but should be $etype";
		last ERRORS;
	    }
	    if ($le - $la > 2) {
		$errmsg = "Your expansion is too short -- check that you have the correct number<br> \
of parts in the $etype and that each part has the correct form";
		last ERRORS;
	    }
	    if ($la - $le > 2) {
		$errmsg = "Your expansion is too long -- check that you have the correct number \
of parts in the $etype and that each part has the correct form";
		last ERRORS;
	    }
	    $temp_attempt = &add_outer_parens($attempt);

#	    if (not &ttree(["~($expanded<->$temp_attempt)"])) {
	    ## call to ttree now made in is_expansion subroutine
	    if (not &is_expansion(&add_outer_parens($pair[0]),
				  $temp_attempt,
				  @entities)) {
		$errmsg = "Your expansion is incorrect -- check that each part of your $etype has the right form";
	    }
	}
	  
	  if ($errmsg) {
	      print "<img src=$redx>\n ";
	      print "<font size=-2>$errmsg</font>";
	      print "</td></tr>\n";
	      $MAILTEXT .= "User attempt '".ascii2utf_html($attempt)."' judged not equivalent to expansion '".ascii2utf_html($expanded)."' of original '".ascii2utf_html($pair[0])."' in universe '$universe' - $errmsg\n";
	      $aok = '';
	      last FOO;
	  }

	print "<img src=$greentick>\n";
	print "</td></tr>\n";

	$aok .= ". " if /premise/ and $aok;
	$aok .= " :. " if /conclusion/;
	$aok .= $expanded;
	$MAILTEXT .= ascii2utf_html($attempt)." passed as equivalent to ".ascii2utf_html($expanded).".\n";

    }

    &mailit($mailto,$MAILTEXT);

    print "</table><!-- end expansions table -->\n";

    if (not $aok) {
	print
	    $cgi->center(strong("Please try again")),
	    "<p>",
	    &expansions_form,
	    ;
    } else {
	print
	    "<p>\n",
	    $cgi->center(strong("You have correctly constructed equivalent ",
				"statements for the universe you selected.",
				"<br>",
				"Now, see whether you can find truth value ",
				"assignments that demonstrate invalidity.",
				"<br>\n",
				"Beware that this will not be possible if ",
				"your chosen universe has too few objects!"),
			 "<p>",
			 "(Be sure to use upper case &nbsp;",
			 "<tt>T</tt>&nbsp; and &nbsp;<tt>F</tt>&nbsp; ",
			 "for truth values.)"),
	    ;

	my @scheme = &translator($aok);
	&exp_form($aok,@scheme);
    }
    &pol_footer;
    &end_polpage;

}

sub pred2prop {
    my ($arg,@scheme) = @_;
    my $i;
    for ($i=0;$i<@scheme;$i=$i+2) {
	$arg =~ s/$scheme[$i+1]/$scheme[$i]/g;
    }
    return $arg;
}

sub get_preamble {
    my ($probfile) = @_;

    $probfile =~ s/\||\.\.//g; # close pipeline exploit; CA 9-17-2004
    open (FILE,$probfile);
    while (<FILE>) {
	next unless /^#!preamble/;
	s/^#!preamble//;
	$result .= $_;
    }
    return $result;
}
