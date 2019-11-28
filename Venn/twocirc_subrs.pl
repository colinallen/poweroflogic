########################### subroutines ###########################
sub twocirc_checkdiag {
    my ($subject,$predicate,$statement,$title) = @_;
    my $output =
	"Compare guess='$POL::image' to answer='$diag'\nfor $statement\n";
    $title = "Venn Diagrams" unless $title;

    
    if (&twocirc_diag_eq($POL::image,$diag)) {
	&pol_header($title);
	print "<div align=\"center\">";
	print
	    "<table style=\"border:0px; cellspacing:0px; cellpadding:10px; align:center\">",
	    Tr(td({-width=>80, -align=>'left',
		   -valign=>'top', -bgcolor=>$VENNBGCOLOR},
		  $cgi->strong($subject)),
	       td({-width=>80, -align=>'right',
		   -valign=>'top', -bgcolor=>$VENNBGCOLOR},
		  $cgi->strong($predicate)),
	       td({-width=>260,-valign=>'top'},
		  "<font color=maroon>",
		  $cgi->strong("Correct Diagram"),
		  "</font>")),
	    
	    Tr(td({-width=>80,-align=>'center',-valign=>'top',
		   -colspan=>2, -bgcolor=>$VENNBGCOLOR},
		  "<img src=\"$imagedir/$POL::image\" align=\"center\" alt=\"$POL::image\">"),
	       td({-width=>340, -align=>'left'},
		  $statement)),
	    ;

	if ($syllogism =~ /<br>/i) { # syllogism
	    print
		Tr(td({-width=>500,-align=>'center',
		       -valign=>'top',-colspan=>3},
		      "<font color=$INSTRUCTCOLOR><strong>\n",
		      "The Venn Diagram correctly represents the syllogism's premise(s).\n",
		      "Now indicate whether the syllogism is valid.\n",
		      "</strong></font>\n<p>",
		      $cgi->startform(),
		      $cgi->hidden(-name=>'prob'),
		      $cgi->hidden(-name=>'probnum'),
		      $cgi->hidden('prevchosen'),
		      $cgi->hidden(-name=>'exercise'),
		      $cgi->hidden(-name=>'image'),
		      $cgi->submit(-name=>'action',-value=>'Valid'),
		      $cgi->submit(-name=>'action',-value=>'Invalid'),
		      $cgi->endform)),
		;
	      
	} else { #statement only
	    print
		Tr(td({-width=>500,-align=>'center',
		       -valign=>'top',-colspan=>3},
		      "<font color=$INSTRUCTCOLOR>",
		      $cgi->strong("The Venn Diagram correctly represents the statement."))),
		Tr(td({-colspan=>3,-align=>center},
		      $cgi->startform,
		      $cgi->hidden('prevchosen'),
		      $cgi->hidden('exercise'),
		      $cgi->submit("Another from $POL::exercise?"),
		      $cgi->endform)),
		;

	}
	print "</table>";
	print "</div>";
	&pol_footer;

    } else {
	$errmsg= &twocirc_diagnose_error($POL::image,$diag);
	&twocirc_draw($subject,$predicate,$statement,$POL::image);
    }
}

sub twocirc_diag_eq {
    my ($d1, $d2) = @_;
    return 1 if $d1 eq $d2;
    return 0;
}

sub twocirc_diagnose_error {
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

sub twocirc_redraw {
    my ($subject,$predicate,$statement,$title) = @_;
    $image=$POL::image;
    $x=$cgi->param('click.x');
    $y=$cgi->param('click.y');
    @circle1 = (50,50,40);
    @circle2 = (100,50,40);
    
    $region = &twocirc_vennregion;
    $Xloc = &twocirc_Xloc;
    
    $newimage = &twocirc_nextimage;
    
    &twocirc_draw($subject,$predicate,$statement,$newimage,$title);
}


sub twocirc_draw {
    my ($subject,$predicate,$statement,$newimage,$title) = @_;
    $cgi->delete('image');
    $title = "Venn Diagrams" unless $title;
    
    &pol_header($title,$preamble);

    my $type = 'statement';
    $type = 'premise(s)' if $statement =~ /<br>/i;
    print
	$cgi->startform(),
	$cgi->hidden(-name=>'image',-value=>$newimage),
	$cgi->hidden(-name=>'prob'),
	$cgi->hidden(-name=>'probnum'),
	$cgi->hidden(-name=>'exercise'),
	$cgi->hidden(-name=>'prevchosen'),
	table({-border=>0,-cellspacing=>0,-cellpadding=>10,-align=>'center'},
	      Tr(td({-width=>100,-align=>'left',-valign=>'top',-bgcolor=>$VENNBGCOLOR},
		    $cgi->strong($subject)),
		 td({-width=>100,-align=>'right',-valign=>'top',-bgcolor=>$VENNBGCOLOR},
		    $cgi->strong($predicate)),
		 td({-width=>200,-align=>'center',-valign=>'top'},
		    "<font color=$INSTRUCTCOLOR>",
		    $cgi->strong("Diagram the $type"),
		    "</font>",
		    "<br>",
		    $statement)),
	      Tr(td({-width=>200,-align=>'center',-colspan=>2,-valign=>'top',-bgcolor=>$VENNBGCOLOR},
		    $cgi->image_button(-name=>'click',
				       -src=>"$imagedir/$newimage",
				       -alt=>$newimage,
				       -align=>center,
				       -border=>0)),
		 td({-width=>300,-align=>'center',-valign=>'top'},
		    "<font color=\"maroon\"><strong>$errmsg</strong></font>",
		    "<p>",
		    table({-border=>1,-align=>'center'},
			  Tr(td({-align=>'center'},
				"<font color=$INSTRUCTCOLOR>",
				"<strong><em>\n",
				"Select action below",
				"<br>",
				"then click on image at left",
				"</em></strong>\n",
				"</font>\n<br>\n",
				$cgi->radio_group(-name=>'action',
						  -values=>['Shading',
							    'Check',
							    'Particular',
							    'Clear'],
						  -onclick=>'this.form.submit()',
						  -default=>'Shading',
						  -columns=>2))))))),
	$cgi->endform();

    &pol_footer();
}

sub twocirc_nextimage {
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
#	print "<br>*****region is $region***** $image to $s1$s2$s3$ob.gif<br>";

	return "$s1$s2$s3$ob.gif";
    } 
    
    if ($POL::action =~ /Partic/) {
	$shading = "$s1$s2$s3";
	if (($Xloc == 1 and $s1) or 
	    ($Xloc == 2 and $s2) or
	    ($Xloc == 3 and $s3)) {
	    $errmsg = "You may not place an X in a shaded area.";
	    return $image;
	}
	
#	$errmsg = "$ob $X1 $X2 $Xloc ";

	if ($ob eq $Xloc) { # delete it
	    return $shading."0.gif";
	} else { # add it
	    return "$shading$Xloc.gif";
	}
	
	# shouldn't ever get here, so make a comment if we do
	$errmsg = "Is this what you wanted?";
	return $image;
    }
}

sub twocirc_incircle {
    my($xc,$yc,$rc)=@_;
    $rc = $rc - 1; # keep away from the border
    if ((($x-$xc)**2 + ($y-$yc)**2) < $rc**2) {
	return 1;
    }
    return 0;
}

sub twocirc_vennregion {
    $circ1 = &twocirc_incircle(@circle1);
    $circ2 = &twocirc_incircle(@circle2);
    return 2 if $circ1 and $circ2;
    return 1 if $circ1;
    return 3 if $circ2;
    return 0;
}

sub twocirc_Xloc {
    my $circ1 = &twocirc_incircle(@circle1);
    my $circ2 = &twocirc_incircle(@circle2);
    return "2" if $circ1 and $circ2;
    return "3" if $circ2;
    return "1" if $circ1;
    return 0;
}

sub picksyll {
    $cgi->delete('syllogism'); # delete any previous selection

    # html out
    my $instructions = "<span style=\"color: $INSTRUCTCOLOR; font-weight: bold\">Pick a syllogism to diagram</span>";

    $instructions .= $PREVCHOICEINSTRUCTION
	if @POL::prevchosen;


    if (!$POL::exercise) {
	&pol_header($title, $instructions);
	print
	    "<strong>Construct a syllogism</strong>\n<br>\n",
	    $cgi->startform,
	    table({-width=>'100%',-border=>0},
		  Tr(td({-valign=>'top',-align=>'right',-width=>'35%'},
			"First premise:"),
		     td({-valign=>'top',-align=>'left'},
			$cgi->popup_menu(-name=>'prem1',
					 -values=>\@p1vals,
					 -labels =>\%prem1))),
		  Tr(td({-valign=>'top',-align=>'right'},
			"Second premise:"),
		     td({-valign=>'top',-align=>'left'},
			$cgi->popup_menu(-name=>'prem2',
					 -values=>\@p2vals,
					 -labels =>\%prem2))),
		  Tr(td({-valign=>'top',-align=>'right'},
			"Conclusion:"),
		     td({-valign=>'top',-align=>'left'},
			$cgi->popup_menu(-name=>'conc',
					 -values=>\@concvals,
					 -labels =>\%conc)))),
	    "<center>",
	    $cgi->hidden(-name=>'prob', -value=>"yes"),
	    $cgi->hidden(-name=>'prevchosen'),
	    $cgi->submit(-name=>'act', -value=>"Continue"),
	    "</center>",
	    $cgi->endform;

    } else { # going for canned problems
	my @problems;
	my ($chapter,$foo) = split(/\./,$POL::exercise,2);
	my $probfile = "$EXHOME$chapter/".$POL::exercise;

	open(FILE,$probfile) || die("Could not open problem file $probfile");
	while (<FILE>) {
	    next if /^\#|^\w*$/;
	    chomp;
	    push @problems, $_;
	}
	close(FILE);

	# html out
	&pol_header($title, $instructions);

	print "<table width=100%>";
	
	my $count=0;
	my $program = $cgi->self_url;
	foreach $problem (@problems) {
	    ++$count;
	    if ($problem =~ /unavailable/i) {
		print
		    Tr(td({-valign=>'top',-align=>'left'},
			  $cgi->image_button(-name=>'void',
					     -src=>$smallgreyPoLogo)),
		       td({-valign=>'top',-bgcolor=>'#dddddd'},
			  "<font size=\"-1\">",
			  strong("#$count"),
			  "</font>"),
		       td({-valign=>'top'},
			  "<font size=-1>\n",
			  em("This problem is currently unavailable"),
			  "</font>"));
		next;
	    }

	    my ($syllogism,$foo) = split("::",$problem,2);
	    my $button_image = $prevchosen{$count} ? $smallgreyPoLogo : $smallPoLogo;

	    $problem=&rot($problem);
	    print
		Tr(td({-valign=>'top',-align=>'left'},
		      $cgi->startform,
		      $cgi->hidden(-name=>prob,-value=>$problem),
		      $cgi->hidden(-name=>'exercise'),
		      $cgi->hidden(-name=>'prevchosen'),
		      $cgi->hidden(-name=>probnum,
				   -value=>$count,
				   -override=>1),
		      $cgi->image_button(-name=>'void',
					 -src=>$button_image),
		      $cgi->endform),
		   td({-valign=>'top',-bgcolor=>'#dddddd'},
		      "<font size=\"-1\">",
		      strong("#$count"),
		      "</font>"),

		   td({-valign=>'top'},
		      "<font size=-1>\n",
		      $syllogism,
		      "</font>"));
	}
	
	print "</table>";
	
    }
    &pol_footer;

}

# no longer used code - replaced by picksyll
sub twocirc_random_pick {
    if (!$POL::exercise) {
	print "You did not specify an exercise";
	return "All As are Bs::A::B::1000.gif";
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

1; # required by require
