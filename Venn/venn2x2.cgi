#!/usr/bin/perl

# this is venn2.cgi
# Version 0.1 Aug 19, 2001 by CA

require "../lib/header.pl";
require "./twocirc_subrs.pl";

$imagedir="/Images/Venn2";
srand;

# comment out next line if you don't want mail to be sent
#$mailto = 'random';
#$mailto = 'colin';

$debug = 1 if $cgi->url =~ /mayfield/i;

local $title ="Venn Diagram Pairs";
$title = "Exercise $POL::exercise, $title" if $POL::exercise;

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


####################################################
# ADD LOCAL MENU ITEMS HERE
# $polmenu{"Main Menu"} = "../menu.cgi";

if ($POL::exercise =~ /^(\d+)\./) {
    $polmenu{"More from Ch. $1"} = "../menu.cgi?chapter=$1";
    $polmenu{"More from $POL::exercise"} = $cgi->url."?exercise=$POL::exercise&prevchosenstring=$prevchosen_string&do=".time;
}

$polmenu{'Help with Venn'} = "../help.cgi?helpfile=vennhelp.html"
    if $POL::prob;

#####################################################

&start_polpage($title);

if ($POL::prob) {
    $POL::prob = &rot($POL::prob);
} else {
    &picksyll;
    &bye_bye;
#    $cgi->param('prob',&rot($POL::prob));
}
    
($argument,$subject,$predicate,$premdiag,$concdiag,$validity)
    = split("::",$POL::prob,6);
    
if ($POL::action =~/Check/) {
    &checkdiag;
} elsif ($POL::action =~ /valid/i) {
    &checkvalidity;
} elsif ($POL::action =~ /Shad|Partic/) {
    &redraw;
} else {
    $POL::premimage = '0000.gif';
    $POL::concimage = '0000.gif';
    &draw("0000.gif","0000.gif");
}

&end_polpage();

########################### subroutines ###########################
sub checkdiag {
    my $premcheck = &diag_eq($POL::premimage,$premdiag);
    my $conccheck = &diag_eq($POL::concimage,$concdiag);
    if ($premcheck and $conccheck) {
	&pol_header($title);
	print
	    $cgi->table({-border=>0, -cellspacing=>0 -cellpadding=>2},
			
			Tr(td({-width=>80, -align=>'left', -valign=>'top'},
			      $cgi->strong($subject)),
			   td({-width=>80, -align=>'right', -valign=>'top'},
			      $cgi->strong($predicate)),
			   td({-width=>160})),
			
			Tr(td({-width=>80, -align=>'center', -valign=>'top', -colspan=>2},
			      strong("Premise"),
			      "<p>",
			      "<img src=\"$imagedir/$POL::premimage\" align=\"center\" alt=\"$POL::premimage\">",
			      "<p>",
			      strong("Conclusion"),
			      "<p>",
			      "<img src=\"$imagedir/$POL::concimage\" align=\"center\" alt=\"$POL::concimage\">"),
			   td({-width=>240, -align=>'left'},
			      "<font color=\"maroon\">",
			      strong("Correct Diagrams"),
			      "</font>",
			      "<p>",
			      $argument,
			      "<p>",
			      strong("<font color=\"$LEFTPAGECOLOR\">",
				     "The Venn Diagrams correctly represent the premise and conclusion.",
				     "</font>",
				     "<p>",
				     "Now say whether the inference is valid or not."),

			      $cgi->startform,
			      $cgi->hidden('prob'),
			      $cgi->hidden('probnum'),
			      $cgi->hidden('prevchosen'),
			      $cgi->hidden('exercise'),
			      $cgi->hidden('premimage'),
			      $cgi->hidden('concimage'),
			      $cgi->submit(-name=>'action', -value=>"Valid"),
			      $cgi->submit(-name=>'action', -value=>"Not valid"),
			      $cgi->endform))),
	    ;

	&pol_footer;
	
    } elsif (!$premcheck) {
	$errmsg = "Premise must be fixed: ";
	$errmsg .= &diagnose_error($POL::premimage,$premdiag);
	&draw($POL::premimage,$POL::concimage);
    } else {
	$errmsg = "Premise diagram is correct; conclusion must be fixed: ";
	$errmsg .= &diagnose_error($POL::concimage,$concdiag);
	&draw($POL::premimage,$POL::concimage);
    }
}

sub diag_eq {
    my ($d1, $d2) = @_;
    return 1 if $d1 eq $d2;
    return 0;
}

sub diagnose_error {
    my($guess,$answer) = @_;
    $guess   =~ /(\d)(\d)(\d)(\d)\.gif/;
    my $gsum = $1+$2+$3;
    my $guess_shading = "$1$2$3";
    my $gob  = $4;
    
    my $errmsg = "Incorrect Diagram: ";

    $answer  =~ /(\d)(\d)(\d)(\d)\.gif/;
    my $asum = $1+$2+$3;
    my $answer_shading = "$1$2$3";
    my $aob  = $4;
    
    $errmsg .= "You have too few shaded areas. "
	if $asum > $gsum;
    $errmsg .= "You have too many shaded areas. "
	if $asum < $gsum;
    $errmsg .= "Your shading is incorrect. "
	if $asum == $gsum and $guess_shading ne $answer_shading;
    
    $errmsg .= "You have X in an incorrect position. "
	if $gob and $gob ne $aob;
    $errmsg .= "You are missing an X. "
	if !$gob and $aob;

    return "$errmsg Try Again.";
}

sub redraw {
    $premimage=$POL::premimage;
    $concimage=$POL::concimage;
    $premx=$cgi->param('premclick.x');
    $premy=$cgi->param('premclick.y');
    $concx=$cgi->param('concclick.x');
    $concy=$cgi->param('concclick.y');
    @circle1 = (50,50,40);
    @circle2 = (100,50,40);
    
    $premregion = &vennregion($premx,$premy);
    $concregion = &vennregion($concx,$concy);

    if ($premregion) {
	$premimage = &nextimage($premimage,$premregion);
    } elsif ($concregion) {
	$concimage = &nextimage($concimage,$concregion);
    } 

    &draw($premimage,$concimage);
}


sub draw {
    my ($premimage,$concimage) = @_;

    &pol_header($title);

    $argument =~ /(.*?\.)\s*(.*)/;
    $premise = $1;
    $conclusion = $2;

    print
	$cgi->startform(),
	$cgi->hidden(-name=>'premimage',-value=>$premimage, -override=>1),
	$cgi->hidden(-name=>'concimage',-value=>$concimage, -override=>1),
	$cgi->hidden(-name=>'prob'),
	$cgi->hidden(-name=>'probnum'),
	$cgi->hidden(-name=>'exercise'),
	$cgi->hidden('prevchosen'),
	$cgi->table({-border=>0, -cellspacing=>0, -cellpadding=>5, -align=>'center'},
		    Tr(
		       td({-width=>200, -align=>'center', -colspan=>2, -valign=>'top'},
			  strong("Premise: $premise")),

		       td({-width=>300, -align=>'center', -valign=>'top', -rowspan=>4},
			  "<font color=\"maroon\"><strong>$errmsg</strong></font><br>\n",
			  "<p>",
			  "<font color=\"$LEFTPAGECOLOR\">",
			  strong("Diagram the premise and conclusion of the argument"),
			  "</font>",
			  "<p>",
			  $argument,
			  "<p>",
			  &action_table)
		       ),
		    
		    Tr(td({-width=>100, -align=>'left', -valign=>'top',-bgcolor=>$VENNBGCOLOR},
			  strong($subject)),
		       td({-width=>100, -align=>'right', -valign=>'top',-bgcolor=>$VENNBGCOLOR},
			  strong($predicate))),
		    
		    Tr(td({-width=>200, -align=>'center', -colspan=>2, -valign=>'top',-bgcolor=>$VENNBGCOLOR},
			  $cgi->image_button(-name=>'premclick',
					     -src=>"$imagedir/$premimage",
					     -alt=>$premimage,
					     -align=>'center',
					     -border=>0))),
		    
		    Tr(td({-width=>200, -align=>'center', -colspan=>2, -valign=>'top'},
			  strong("Conclusion: $conclusion"))),
		    
		    Tr(td({-width=>100, -align=>'left', -valign=>'top',-bgcolor=>$VENNBGCOLOR},
                          strong($subject)),
                       td({-width=>100, -align=>'right', -valign=>'top',-bgcolor=>$VENNBGCOLOR},
                          strong($predicate))),
		    
		    Tr(td({-width=>200, -align=>'center', -colspan=>2, -valign=>'top',-bgcolor=>$VENNBGCOLOR},
			  $cgi->image_button(-name=>'concclick',
					     -src=>"$imagedir/$concimage",
					     -alt=>$concimage,
					     -align=>'center',
					     -border=>0)))
		    ),
			
	    $cgi->endform(),
	;

    &pol_footer();
}

sub action_table {
    return $cgi->table({-border=>1, -align=>'center'},
		       Tr(td({-align=>'center'},
			     "<font color=\"$LEFTPAGECOLOR\">",
			     strong("<em>",
				    "Select action below<br>then click on one of the images at left",
				    "</em>"),
			     "</font>\n<br>\n",
			     $cgi->radio_group(-name=>'action',
					       -values=>['Shading',
							 'Check',
							 'Particular',
							 'Clear'],
					       -default=>'Shading',
					       -onclick=>'this.form.submit()',
					       -columns=>2))));
}

sub nextimage {
    my($image,$region) = @_;
    return "0000.gif" if $POL::action =~ /Clear/;
    return $image if $POL::action =~ /Check/;

    # can't shade outside circles
    # well maybe we can do this - how to handle?
    return $image if $region==0;

    $image =~ /(\d)(\d)(\d)(\d)\.gif/;
    my $s1   = $1;
    my $s2   = $2;
    my $s3   = $3;
    my $ob   = $4;

    if ($POL::action =~ /shad/i) {
	if ($region == $ob) {
	    $errmsg = "You must delete the X from the selected area before you can shade it.";
	    return $image;
	}

	if ($region == 1) {
	    ($s1 == 0 and $s1 = 1) or $s1 = 0;
	} elsif ($region == 2) {
	    ($s2 == 0 and $s2 = 1) or $s2 = 0;
	} elsif ($region == 3) {
	    ($s3 == 0 and $s3 = 1) or $s3 = 0;
	} 
	return "$s1$s2$s3$ob.gif";
    } 
    
    if ($POL::action =~ /Partic/) {
	$shading = "$s1$s2$s3";
	if (($region == 1 and $s1) or 
	    ($region == 2 and $s2) or
	    ($region == 3 and $s3)) {
	    $errmsg = "You may not place an X in a shaded area.";
	    return $image;
	}
	
	if ($ob eq $region) { # delete it
	    return $shading."0.gif";
	} else { # add it
	    return "$shading$region.gif";
	}
	
	# shouldn't ever get here, so make a comment if we do
	$errmsg = "Is this what you wanted?";
	return $image;
    }
}

sub incircle {
    my($x,$y,$xc,$yc,$rc)=@_;
    $rc = $rc - 1; # keep away from the border
    if ((($x-$xc)**2 + ($y-$yc)**2) < $rc**2) {
	return 1;
    }
    return 0;
}

sub vennregion {
    my ($x,$y) = @_;
    $circ1 = &incircle($x,$y,@circle1);
    $circ2 = &incircle($x,$y,@circle2);
    return 2 if $circ1 and $circ2;
    return 1 if $circ1;
    return 3 if $circ2;
    return 0;
}


sub checkvalidity {
    &pol_header($title);

    my $score = 0;
    if ($POL::action eq $validity) {
	$score = 1;
	$response = "correct";
    } else {
        $response = "incorrect. The inference is ".lc($validity);
    }
    print
	"<table border=0 cellspacing=0 cellpadding=2>\n",
	"<tr><td width=80 align=left valign=top>\n",
	"<strong>$subject</strong>\n",
	"</td><td width=80 align=right valign=top>\n",
	"<strong>$predicate</strong>\n",
	"</td><td width=160>\n",
	"</td></tr>\n",
	"<tr><td width=160 align=center valign=top colspan=2>\n",
	strong("Premise"),
	"<p>",
	"<img src=$imagedir/$POL::premimage align=center>",
	"<p>",
	strong("Conclusion"),
	"<p>",
	"<img src=$imagedir/$POL::concimage align=center>",
	"</td>\n",
	"<td width=240 align=center>\n",
	$syllogism,
	"\n<br>\n",
	"<font color=\"maroon\">\n",
	strong("Your answer of \"$POL::action\" is $response."),
	"</font>\n",
	"\n<p>\n",
	$cgi->startform(),
	$cgi->hidden('exercise'),
	$cgi->hidden('prevchosen'),
	$cgi->submit("Another from $POL::exercise?"),
	$cgi->endform(),
	
	"</td></tr>",
	"</table>";
    
    &pol_footer;


   # send result to page out
    my %pageoutdata = %pageoutid;
    if (%pageoutdata) {
	$pageoutdata{'vendor_assign_id'} = $POL::exercise;
	$pageoutdata{'assign_probs'} = [ $POL::probnum, 34, 23 ];
	$pageoutdata{'student_score'} = [ $score, 1, 0 ];
	&send_to_pageout(%pageoutdata);
    }
}

## following not currently in use - 6.5.2002 - CA
sub random_pick {
    if (!$POL::exercise) {
	print "You did not specify an exercise";
	return"Some As are not Bs. So, some Bs are not As.::A::B::0001.gif::0003.gif::Not valid";
    } else {
	my @questions;
        my ($chapter,$foo) = split(/\./,$POL::exercise,2);
        my $probfile = "$EXHOME$chapter/".$POL::exercise;

	$probfile =~ s/\||\.\.//g; # close pipeline exploit; CA 9-17-2004
        open(FILE,$probfile) || die("Could not open problem file $probfile");
        while (<FILE>) {
            next if /^\#|^\w*$/;
            chomp;
            push @questions, $_;
        }
        close(FILE);

	## now we random pick
	if (@POL::prevchosen >= @questions) {           # If user has already been quizzed on all 
	    $cgi->delete('prevchosen');                # of the questions, make prevchosen nil;
	}

	@prevchosen = $cgi->param('prevchosen');   # find out what nums have already been used
	my $stillpicking = 1;
	my $pick = 0;
      PICK:
	while ($stillpicking) {
	    last PICK if ++$count > 100; # just in case!
	    $pick = int(rand @questions); # find a number in range
	    for (@prevchosen) {
		next PICK if $pick == $_;
	    }
	    # if we get here then this is a new one
	    $stillpicking = 0;
	}
	
	
	push @prevchosen, $pick;
	$cgi->param('prevchosen',@prevchosen);
	return $questions[$pick];
    }
}

