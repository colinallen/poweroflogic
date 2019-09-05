#!/usr/bin/perl

# this is mentmod.cgi
# Version 0.1 2005-06-24 by CA
# adapted from venn.cgi ver. 0.2 

require "../lib/header.pl";
require "./twocirc_subrs.pl";

# comment out next line if you don't want mail to be sent
$mailto = 'random';
#$mailto = 'colin';

%prem1 = (
	  '0110000'=>'All of the archaeologists are biologists',
	  '0001001'=>'All of the biologists are archaeologists',
	  '0000110d'=>'None of the archaeologists  is a biologist',
	  '00001100'=>'None of the biologists is an archaeologist',
	  'bcd'=>'Some of the archaeologists are biologists',
	  'bcdd'=>'Some of the biologists are archaeologists',
	  '345'=>'Some of the archaeologists are not biologists',
	  '9eg'=>'Some of the biologists are not archaeologists',
	  );

%prem2 = (
	  '1100000'=>'All of the chess players are biologists',
	  '0000011h'=>'All of the biologists are chess players',
	  '0001100'=>'None of the  chess players is a biologist' ,
	  '00011000'=>'None of the biologists is a chess player' ,
	  '9ab'=>'Some of the chess players are biologists',
	  '9abb'=>'Some of the biologists are chess players',
	  '123'=>'Some of the chess players are not biologists',
	  'dfg'=>'Some of the biologists are not chess players',
	  );

%conc = (
	 '1001000'=>'All of the chess players are archaeologists',
	 '0010010'=>'All of the archaeologists are chess players',
	 '0100100'=>'None of the chess players is a archaeologist',
	 '01001000'=>'None of the archaeologists is a chess player',
	 '37b'=>'Some of the chess players are archaeologists',
	 '37bb'=>'Some of the archaeologists are chess players',
	 '169'=>'Some of the chess players are not archaeologists',
	 '58d'=>'Some of the archaeologists are not chess players',
	 );


%shadeXmap = (
	      '1' => '0',  # Xloc 1 corresponds to 0th position in shade string
	      '3' => '1',
	      '5' => '2',
	      '9' => '3',
	      'b' => '4',
	      'd' => '5',
	      'g' => '6',
	      );

@p1vals = sort {$prem1{$a} cmp $prem1{$b}} keys %prem1;
@p2vals = sort {$prem2{$a} cmp $prem2{$b}} keys %prem2;
@concvals = sort {$conc{$a} cmp $conc{$b}} keys %conc;

$debug = 1 if $cgi->url =~ /colin/i;


local $title ="Mental Models and Venn Diagrams";

$comeback = $cgi->self_url;

####################################################
# ADD LOCAL MENU ITEMS HERE
# $polmenu{"Main Menu"} = "../menu.cgi";

$polmenu{'Help with Venn'} = "../help.cgi?helpfile=vennhelp.html"
    if $POL::prob;

#####################################################

print # beginning of response page
    header(-Pragma=>"no-cache"),
    start_html(-title=>"$title",
	       -author=>'logic.pedallers@gmail.com',
	       -meta=>{'keywords'=>'logic venn predicate',
		       'copyright'=>'copyright 2002-2003 Logic Pedallers'},
	       -bgcolor=>$LEFTPAGECOLOR,
	       ),
    ;

if (!$POL::prob) {
    &picksyll;
} else {
    if ($POL::prob eq 'yes') {
	
	$POL::prob  = $prem1{$POL::prem1} . ". ";
	$POL::prob .= $prem2{$POL::prem2} . ". ";
	$POL::prob .= $conc{$POL::conc} . ".";
	$POL::prob .= "::Chess Players::Archaeologists::Biologists";
	$POL::prob .= "::" . $POL::prem1;
	$POL::prob .= "+"  . $POL::prem2;
	$POL::prob .= "::" . $POL::conc;
	
	$cgi->param('prob',&rot($POL::prob));
    } else {
	$POL::prob = &rot($POL::prob);
    }
    
    ($syllogism,$majorterm,$minorterm,$middleterm,$diag,$validity)
	= split("::",$POL::prob,6);
    
    $syllogism =~ s/\./\.<br>/g; # for pretty printing
    
    if ($middleterm) { # 3 circle problem
	if ($POL::action =~/Check/) {
	    &checkdiag;
	} elsif ($POL::action =~ /valid/i) {
	    &checkvalidity;
	} elsif ($POL::action =~ /Shad|Partic/) {
	    &redraw;
	} else {
	    &draw("00000000.gif");
	}
    } else { # 2 circle problem
	$imagedir="/Images/Venn2";
	if ($POL::action =~/Check/) {
	    &twocirc_checkdiag($majorterm,$minorterm,$syllogism);;
	} elsif ($POL::action =~ /valid/i) {
	    &checkvalidity;
	} elsif ($POL::action =~ /Shad|Partic/) {
	    &twocirc_redraw($majorterm,$minorterm,$syllogism,$title);
	} else {
	    &twocirc_draw($majorterm,$minorterm,$syllogism,"0000.gif",$title);
	}
    }
}

&end_polpage();

########################### subroutines ###########################
sub checkdiag {
    my $output =
	"Compare guess='$POL::image' to answer='$diag'\nfor $syllogism\n";

    if ((($diag =~ /\+/) and &diagmatch) or 
	&diag_eq($POL::image,$diag)) {
	&pol_header($title);
	print
	    table({-border=>0,-cellspacing=>0,-cellpadding=>5},
		  Tr(td({-width=>80,-align=>'left',-valign=>'top',-bgcolor=>$VENNBGCOLOR},
			$cgi->strong($majorterm)),
		     td({-width=>80,-align=>'right',-valign=>'top',-bgcolor=>$VENNBGCOLOR},
			$cgi->strong($minorterm)),
		     td({-width=>160},
			"<font color=maroon>",
			$cgi->strong("Correct Diagram"),
			"</font><br>\n")),
		  Tr(td({-width=>160,-align=>'center',-valign=>'top',-colspan=>2,-bgcolor=>$VENNBGCOLOR},
			"<img src=delivergif.cgi?image=$POL::image align=center>",
			$cgi->center($cgi->strong($middleterm))),
		     td({-width=>240,-align=>'left',-valign=>'top'},
			$syllogism,
			"\n<br>\n",
			"<font color=$LEFTPAGECOLOR>",
			$cgi->strong("The Venn Diagram correctly represents the syllogism's premises.\n",
				     "Now indicate whether the syllogism is valid.\n"),
			"</font>",
			"<p>",
			$cgi->startform(),
			$cgi->hidden(-name=>'prob'),
			$cgi->hidden(-name=>'probnum'),
			$cgi->hidden(-name=>'prevchosen'),
			$cgi->hidden(-name=>'exercise'),
			$cgi->hidden(-name=>'image'),
			$cgi->submit(-name=>'action',-value=>'Valid'),
			$cgi->submit(-name=>'action',-value=>'Invalid'))));

    } else {
	$errmsg= &diagnose_error($POL::image,$diag);

	&draw($POL::image);
    }
}

sub diag_eq {
    my ($d1, $d2) = @_;
    return 1 if $d1 eq $d2;
    $d1 =~ s/.gif//;
    $d2 =~ s/.gif//;
    if (length($d1)==9 and length($d2)==9) {
	# two Xs can come in either order
	$d1 =~ /0000000(\w)(\w)/;
	my ($x1,$x2) = ($1,$2);
	$d2 =~ /0000000(\w)(\w)/;
	my ($x3,$x4) = ($1,$2);
	return 1 if $x1 eq $x4 and $x2 eq $x3;
    }
    return 0;
}

sub diagnose_error {
    my($guess,$answer) = @_;
    $guess   =~ /(\d)(\d)(\d)(\d)(\d)(\d)(\d)(.+)\.gif/;
    my $gsum = $1+$2+$3+$4+$5+$6+$7;
    my $gob  = $8;
    
    my $errmsg = "Incorrect Diagram: ";

    if ($answer =~ /\+/) { #free form mode
	my ($p1diag,$p2diag) = split(/\+/,$answer,2);
	$p1diag = substr($p1diag,0,7) if length($p1diag) == 8;
	$p2diag = substr($p2diag,0,7) if length($p2diag) == 8;
	
	if (length($p1diag)==7 and length($p2diag)==7) { #answer has shading only
	    my $combined_prems = &merge_prems($p1diag,$p2diag);
	    $combined_prems  =~ /(\d)(\d)(\d)(\d)(\d)(\d)(\d)/;
	    my $asum = $1+$2+$3+$4+$5+$6+$7;
	
	    $errmsg .= "You have too few shaded areas. "
		if $asum > $gsum;
	    $errmsg .= "You have too many shaded areas. "
		if $asum < $gsum;
	    $errmsg .= "Check your shading. "
		if $asum == $gsum;
	    
	    $errmsg .= "You have an unnecessary X in your diagram. " if $gob;

	} elsif (length($p1diag)==7) {
	    if ($p1diag eq substr($guess,0,7)) {
		$errmsg .= "Check your X location(s). ";
	    } else {
		$errmsg .= "Check your shading. ";
	    }
	} elsif (length($p2diag)==7) {
	    if ($p2diag eq substr($guess,0,7)) {
		$errmsg .= "Check your X location(s). ";
	    } else {
		$errmsg .= "Check your shading. ";
	    }
	} else { # should be two Xs	
	    if (substr($guess,0,7) ne '0000000') {
		$errmsg .= "Check your shading. ";
	    } else {
		$errmsg .= "Check your X location(s). ";
	    }
	}

    } else { # not working in free form mode
	$answer  =~ /(\d)(\d)(\d)(\d)(\d)(\d)(\d)(.+)\.gif/;
	my $asum = $1+$2+$3+$4+$5+$6+$7;
	my $aob  = $8;
	
	$errmsg .= "You have too few shaded areas. "
	    if $asum > $gsum;
	$errmsg .= "You have too many shaded areas. "
	    if $asum < $gsum;
	$errmsg .= "Your shading is incorrect. "
	    if $asum == $gsum and
		substr($guess,0,7) ne substr($answer,0,7);
	
	if (length($gob)>length($aob)) {
	    $errmsg .= "You have too many Xs. ";
	} elsif (length($gob)<length($aob)) {
	    $errmsg .= "You have too few Xs. ";
	} else {
	    $errmsg .= "You have X in an incorrect position. "
		if $gob and $gob ne $aob;
	    $errmsg .= "You are missing an X. "
		if !$gob and $aob;
	}
    }
    return "$errmsg Try&nbsp;Again.";
}

sub checkvalidity {
    my $guess = $POL::action;
    $guess =~ tr/a-z/A-Z/;
    my $image=$POL::image;
    $image = "$imagedir/$POL::image" if $imagedir;
    
    my $output =
	"Compare guess='$guess' to answer='$validity'\nfor $syllogism\n";
    print $output;

    if ($validity =~ /\d/) { # RYO
	$validity = &diagvalid;
    }

    my $score = 0;
    if (lc($guess) eq lc($validity)) {
	$score = 1;
	&pol_header($title);

	print
	    "<center>",
	    table({-border=>0},
		  Tr(td({-align=>'left'},
			$cgi->strong($majorterm)),
		     td({-align=>'right'},
			$cgi->strong($minorterm))),
		  Tr(td({-align=>'center',-colspan=>2},
			"<img src=\"delivergif.cgi?image=$POL::image\">",
			"<br>",
			$cgi->strong($middleterm)))),
	    "<p>",
	    "$syllogism",
	    "<p>\n",
	    "<strong>You correctly answered that the syllogism is $guess.</strong>\n",
	    &restart,
	    "</center>";

	&mailit($mailto,"$output - answered correctly") if $mailto;

	&pol_footer;
    } else {
	&mailit($mailto,"$output - answered incorrectly") if $mailto;

        &pol_header("$title");

        print
            table({-border=>0,-cellspacing=>0,-cellpadding=>2},
		  Tr(td({-width=>80,-align=>'left',-valign=>'top'},
			"<strong>$majorterm</strong>\n"),
		     td({-width=>80,-align=>'right',-valign=>'top'},
			"<strong>$minorterm</strong>\n"),
		     td({-width=>160},
			"&nbsp;")),
			
		  Tr(td({-width=>160,-align=>'center',-valign=>'top',-colspan=>2},
			"<img src=delivergif.cgi?image=$POL::image align=center>",
			"<center><strong>$middleterm</strong></center>"),
		     td({-width=>240,-align=>'center'},
			$syllogism,
			"\n<br>\n",
			"<font color=maroon><strong>\n",
			"Your answer of $guess is incorrect.\n",
			"According to this diagram, the syllogism is $validity.",
			"</strong></font>\n",
			"\n<p>\n",
			$cgi->startform(),
			$cgi->hidden('exercise'),
			$cgi->hidden(-name=>'prevchosen'),
			$cgi->submit(-name=>act,-value=>"Attempt Another Venn Diagram"),
			$cgi->endform())),
		  );
        &pol_footer;
	
    }
}

sub redraw {
    $image=$POL::image;
    $x=$cgi->param('click.x');
    $y=$cgi->param('click.y');
    @circle1 = (50,50,40);
    @circle2 = (100,50,40);
    @circle3 = (75,93,40);
    
    $region = &vennregion;
    $Xloc = &Xloc;
    
    $newimage = &nextimage;
    
    &draw($newimage);
}


sub draw {
    my ($newimage) = @_;

    $cgi->delete('image');

    &pol_header($title);

    $errmsg = "<font color=maroon><strong>$errmsg</strong></font><br>" if $errmsg;
    
    print
	$cgi->startform(),
	$cgi->hidden(-name=>'image',-value=>$newimage),
	$cgi->hidden(-name=>'prob'),
	$cgi->hidden(-name=>'probnum'),
	$cgi->hidden(-name=>'prevchosen'),
	$cgi->hidden(-name=>'exercise'),
	table({-border=>0,-cellspacing=>0,-cellpadding=>2,-align=>'center'},
	      Tr(td({-width=>100,-align=>'left',-valign=>'top',-bgcolor=>$VENNBGCOLOR},
		    "<strong>$majorterm</strong>\n"),
		 td({-width=>100, -align=>'right',-valign=>'top',-bgcolor=>$VENNBGCOLOR},
		    "<strong>$minorterm</strong>\n"),
		 td({-width=>200,-align=>'center',-valign=>'top'},
		    "<font color=$LEFTPAGECOLOR>",
		    "<strong>Diagram the syllogism's premises</strong>",
		    "</font>")),
	      Tr(td({-width=>200,-align=>'center',-colspan=>2,-valign=>'top',-bgcolor=>$VENNBGCOLOR},
		    $cgi->image_button(-name=>'click',
				       -src=>"delivergif.cgi?image=$newimage",
				       -align=>center,
				       -border=>0),
		    "<br><center><strong>$middleterm</strong></center>\n"),
		 td({-width=>300,-align=>'center',-valign=>'top'},
		    $errmsg,
		    $syllogism,
		    "<p>",
		    table({-border=>1,-align=>'center'},
			  Tr(td({-align=>"center"},
				"<font color=$LEFTPAGECOLOR>",
				"<strong><em>\n",
				"Select action below<br>then click on image at left",
				"</em></strong>\n",
				"</font>\n<br>\n",
				$cgi->radio_group(-name=>'action',
						  -values=>['Shading','Check','Particular','Clear'],
						  -default=>'Shading',
						  -columns=>2))))))),
	$cgi->endform(),
	;

    &pol_footer;
}

sub nextimage {
    return "00000000.gif" if $POL::action =~ /Clear/;
    return $image if $POL::action =~ /Check/;

    # can't shade outside circles
    return $image if $region==0;

    $image =~ /(\d)(\d)(\d)(\d)(\d)(\d)(\d)(.+)\.gif/;
    my $s1   = $1;
    my $s2   = $2;
    my $s3   = $3;
    my $s4   = $4;
    my $s5   = $5;
    my $s6   = $6;
    my $s7   = $7;
    my $ob   = $8;

    if ($POL::action =~ /shad/i) {
	if (($region == 1 and $ob =~ /[126]/) ||
	    ($region == 2 and $ob =~ /[2347]/) ||
	    ($region == 3 and $ob =~ /[458]/) ||
	    ($region == 4 and $ob =~ /[69ae]/) ||
	    ($region == 5 and $ob =~ /[7abc]/) ||
	    ($region == 6 and $ob =~ /[8cdf]/) ||
	    ($region == 7 and $ob =~ /[efg]/)) {
	    $errmsg = "You must delete the X from the selected area before you can shade it.";
	    return $image;
	}
	
	if ($region == 1) {
	    ($s1 == 0 and $s1 = 1) or $s1 = 0;
	} elsif ($region == 2) {
	    ($s2 == 0 and $s2 = 1) or $s2 = 0;
	} elsif ($region == 3) {
	    ($s3 == 0 and $s3 = 1) or $s3 = 0;
	} elsif ($region == 4) {
	    ($s4 == 0 and $s4 = 1) or $s4 = 0;
	} elsif ($region == 5) {
	    ($s5 == 0 and $s5 = 1) or $s5 = 0;
	} elsif ($region == 6) {
	    ($s6 == 0 and $s6 = 1) or $s6 = 0;
	} elsif ($region == 7) {
	    ($s7 == 0 and $s7 = 1) or $s7 = 0;
	}

	# can't have more than four shaded areas
	if ($s1+$s2+$s3+$s4+$s5+$s6+$s7 > 4) {
	    $errmsg = "The syllogistic form entails that no more than four areas may be shaded simultaneously.";
	    return $image;
	}

	return "$s1$s2$s3$s4$s5$s6$s7$ob.gif";
    } 
    
    if ($POL::action =~ /Partic/) {
	$shading = "$s1$s2$s3$s4$s5$s6$s7";
	if  # no object allowed on edge of shaded area
	    (($Xloc == 1 and $s1) or 
	     ($Xloc == 2 and ($s1 or $s2)) or
	     ($Xloc == 3 and $s2) or
	     ($Xloc == 4 and ($s2 or $s3)) or
	     ($Xloc == 5 and $s3) or
	     ($Xloc == 6 and ($s1 or $s4)) or
	     ($Xloc == 7 and ($s2 or $s5)) or
	     ($Xloc == 8 and ($s3 or $s6)) or
	     ($Xloc == 9 and $s4) or
	     ($Xloc eq "a" and ($s4 or $s5)) or
	     ($Xloc eq "b" and $s5) or
	     ($Xloc eq "c" and ($s5 or $s6)) or
	     ($Xloc eq "d" and $s6) or
	     ($Xloc eq "e" and ($s4 or $s7)) or
	     ($Xloc eq "f" and ($s6 or $s6)) or
	     ($Xloc eq "g" and $s7)) {
		$errmsg = "You may not place an X in a shaded area or on the border of a shaded area.";
		return $image;
	    }

#	$errmsg = "$ob $X1 $X2 $Xloc ";
	
	if ($ob eq '0') { # no Xs present - just add one
	    return "$shading$Xloc.gif";
	} elsif (length($ob) == 1) { # one X already present
	    if ($ob eq $Xloc) { # delete X
		return $shading."0.gif";
	    } else { # add second X
		return "$shading$ob$Xloc.gif";
	    }
	} elsif (length($ob) == 2) { # already have two Xs
	    if ($ob =~ s/$Xloc//) { # see if we're deleting one
		return "$shading$ob.gif";
	    } else { # trying to add a third
		$errmsg .= "The syllogistic form entails that no more than two Xs may be present in this diagram.";
		return $image;
	    }
	}
    }

    # shouldn't ever get here, so make a comment if we do
    $errmsg = "Is this what you wanted?";
    return $image;
}

sub incircle {
    my($xc,$yc,$rc)=@_;
    $rc = $rc - 1; # keep away from the border
    if ((($x-$xc)**2 + ($y-$yc)**2) < $rc**2) {
	return 1;
    }
    return 0;
}

sub onborder {
    my($xc,$yc,$rc)=@_;
    return 1 if &incircle($xc,$yc,$rc+10) and !&incircle($xc,$yc,$rc-4);
    return 0;
}


sub vennregion {
    $circ1 = &incircle(@circle1);
    $circ2 = &incircle(@circle2);
    $circ3 = &incircle(@circle3);
    return 5 if $circ1 and $circ2 and $circ3;
    return 2 if $circ1 and $circ2;
    return 4 if $circ1 and $circ3;
    return 6 if $circ2 and $circ3;
    return 1 if $circ1;
    return 3 if $circ2;
    return 7 if $circ3;
    return 0;
}

sub Xloc {
    my $circ1 = &incircle(@circle1);
    my $circ2 = &incircle(@circle2);
    my $circ3 = &incircle(@circle3);
    my $bord1 = &onborder(@circle1);
    my $bord2 = &onborder(@circle2);
    my $bord3 = &onborder(@circle3);
    return "c" if $bord1 and $circ2 and $circ3;
    return "a" if $circ1 and $bord2 and $circ3;
    return "7" if $circ1 and $circ2 and $bord3;
    return "b" if $circ1 and $circ2 and $circ3;
    return "4" if $bord1 and $circ2;
    return "2" if $circ1 and $bord2;
    return "3" if $circ1 and $circ2;
    return "e" if $bord1 and $circ3;
    return "6" if $circ1 and $bord3;
    return "9" if $circ1 and $circ3;
    return "f" if $bord2 and $circ3;
    return "8" if $circ2 and $bord3;
    return "d" if $circ2 and $circ3;
    return "1" if $circ1;
    return "5" if $circ2;
    return "g" if $circ3;
    return 0;
}

sub diagmatch {
    my ($p1diag,$p2diag) = split(/\+/,$diag,2);
    $POL::image =~ /(\d\d\d\d\d\d\d)(.+)\.gif/;
    my $shading   = $1;
    my $ob = $2;

    $p1diag = substr($p1diag,0,7) if length($p1diag) == 8;
    $p2diag = substr($p2diag,0,7) if length($p2diag) == 8;

    # print "checking '$p1diag' and '$p2diag' against '$shading$ob'\n";

    if (length($p1diag)==7 and length($p2diag)==7) {  ## both premises describe shading
	return 0 if $ob;
	for($i=0;$i<7;$i++) {
	    if (substr($shading,$i,1)) {
		return 0
		    unless (substr($p1diag,$i,1) or substr($p2diag,$i,1));
	    } else {
		return 0
		    if (substr($p1diag,$i,1) or substr($p2diag,$i,1));
	    }
	}
	return 1;
    }

    if (length($p1diag)==7) { # first prem shades; second has X
	return 0
	    if (($shading ne $p1diag) or
		(length($ob) != 1) or
		($ob !~ /[$p2diag]/));

	## here we need to figure out whether any of the $p2diag X locations
	## is required; basically if all three possible locations are open (unshaded)
	## then you have to be in the middle one.
	my @shadelocs = split(//,$p1diag);
	my @oblocs = split(//,$p2diag);

	## check to see whether both sides are unshaded
	if (!$shadelocs[$shadeXmap{$oblocs[0]}] and
	    !$shadelocs[$shadeXmap{$oblocs[2]}]) {
	    ## in which case, X must be on line
	    return 1 if $ob eq $oblocs[1];
	    return 0;
	} else { # shading will rule out options
	    return 1;
	}
    }

    if (length($p2diag)==7) { # second prem shades; first has X
        return 0
            if (($shading ne $p2diag) or
                (length($ob) != 1) or
                ($ob !~ /[$p1diag]/));
	## here we need to figure out whether any of the $p1diag X locations
	## is required; basically if all three possible locations are open (unshaded)
	## then you have to be in the middle one.
	my @shadelocs = split(//,$p2diag);
	my @oblocs = split(//,$p1diag);

	## check to see whether both sides are unshaded
	if (!$shadelocs[$shadeXmap{$oblocs[0]}] and
	    !$shadelocs[$shadeXmap{$oblocs[2]}]) {
	    ## in which case, X must be on line
	    return 1 if $ob eq $oblocs[1];
	    return 0;
	} else { # shading will rule out options
	    return 1;
	}
    }

    # if we get here then there must be two Xs marked
    return 0 if length($ob) != 2;
    $p1diag =~ s/[^24acef]//g; # only border Xs are allowed
    $p2diag =~ s/[^24acef]//g;
    return 1 if $ob =~ /[$p1diag][$p2diag]/;
    return 1 if $ob =~ /[$p2diag][$p1diag]/;
    return 0; # fail if we get to here
}

sub diagvalid {
    $POL::image =~ /(\d\d\d\d\d\d\d)(.+)\.gif/;
    my $shading = $1;
    my $ob = $2;

    $validity = substr($validity,0,7) if length($validity) == 8;

    if (length($validity)==7) {
	for($i=0;$i<7;$i++) {
	    return 'INVALID'
		if substr($validity,$i,1) and !substr($shading,$i,1);
	}
	return 'VALID';
    }
    
    return 'VALID' if $ob =~ /[$validity]/;
    return 'INVALID';
    
}

sub restart {
    return
	$cgi->startform .
        $cgi->hidden(-name=>'exercise') .
	$cgi->hidden(-name=>'prevchosen') .
	$cgi->submit(-name=>'action', -value=>'New Venn Diagram Problem') .
	$cgi->endform;
}

sub merge_prems {
    my ($p1,$p2) = @_;
    my $i;
    my $result;
    for ($i=0;$i<7;$i++) {
	if (substr($p1,$i,1) or substr($p2,$i,1)) {
	    $result .= '1';
	} else {
	    $result .= '0';
	}
    }
    return $result;
}

