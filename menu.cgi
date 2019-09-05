#!/usr/bin/perl -T
# Revisions
# 15 Sep 98 
#   CM - added redirect to mc-fixed.cgi
#      - Changed "Exerciser" to "Web Tutor"
#      - Changed "Power of Logic" to be italic in header
#      - put footer subroutine into lib/header.pl 

push @INC, cwd;
require './lib/header.pl';

if ($cgi->param('chapter')) {
    if (-d "$EXHOME".$cgi->param('chapter')) {
	$cgi->delete('chapter')
	    if $chapters{$chapter};
    } elsif ($cgi->param('chapter') !~ /RYO/) { # no such chapter
	&html_error("No such chapter $EXHOME");
    }
}

# $polmenu{'Main Menu'} = 'menu.cgi' if $cgi->param('chapter');
$polmenu{'Help'} = 'help.cgi';

# the stuff that can happen
{
    if ($cgi->param('chapter') =~ /(\d\d?)/) {
	&generate_exercise_menu($1);
	last;
    }
    
    if ($cgi->param('chapter') =~ /RYO_XP/) {  # RYO = RollYerOwn ;-)
	print $cgi->redirect(-uri=>"Proof/checkprf.cgi");
	last
    }

    if ($cgi->param('chapter') =~ /RYO_TT/) {
	print $cgi->redirect(-uri=>"TT/tt.cgi");
	last;
    }

    if ($cgi->param('chapter') =~ /RYO_DV/) {
	print $cgi->redirect(-uri=>"Venn/venn.cgi");
	last;
    }

    if ($cgi->param('selected_exercise')) {
	&my_redirect;
	last;
    }

    &generate_chapter_menu;
}

&pol_footer;
&end_polpage;

#########################
# begin subroutines
#########################
sub my_redirect {
    my $exercise = $cgi->param('selected_exercise');
    my ($chapter)  = split(/\./,$exercise);
    my $probfile = "$EXHOME$chapter/$exercise";
    my $extype;

    $probfile =~ s/\||\.\.//g;  # close pipeline exploit by CA 9-17-04
    open(FILE,$probfile) || &html_error("The file for Exercise $exercise could not be opened.<br>  The webmaster has been notified and will correct the problem.");
    while (<FILE>) {
	next unless $_ =~ /^\#!qtype\w*(.*)/;
	$extype = $1;
	chomp $extype;
	last;
    }
    close(FILE);

  TYPES: {
      if ($extype =~ /PRF/i) {
	  print
	    $cgi->redirect(-uri
			   =>
			   "Proof/checkprf.cgi?exercise=$exercise");
	  last TYPES;
	  }
      if ($extype =~ /MC_FIXED/i) {
	  print
	      $cgi->redirect(-uri
			     =>
			     "MC/mc-fixed.cgi?exercise=$exercise");
	  last TYPES;
      }
#      if ($extype =~ /TR_CLASSIC/i) {
#	  print
#	      $cgi->redirect(-uri
#			     =>
#			     "Trans/trans-classic.cgi?exercise=$exercise&action=New");
#	  last TYPES;
#      }
      if ($extype =~ /TR/i) {
	  print
	      $cgi->redirect(-uri
			     =>
			     "Trans/trans.cgi?exercise=$exercise&action=Choose");
	  last TYPES;
      }
      if ($extype =~ /MC_MULTI/i) {
	  print
	      $cgi->redirect(-uri
			     =>
			     "MC/mc-multi.cgi?exercise=$exercise");
	  last TYPES;
      }
      if ($extype =~ /MC_VAR/i) {
	  print
	      $cgi->redirect(-uri
			     =>
			     "MC/mc-var.cgi?exercise=$exercise");
	  last TYPES;
      }
      if ($extype =~ /ATT/i) {
	  print
	      $cgi->redirect(-uri
			     =>
			     "TT/att.cgi?exercise=$exercise&action=New");
	  last TYPES;
      }
      if ($extype =~ /TT/i) {
	  print
	      $cgi->redirect(-uri
			     =>
			     "TT/tt.cgi?exercise=$exercise&action=New");
	  last TYPES;
      }
      if ($extype =~ /TAUT/i) {
	  print
	      $cgi->redirect(-uri
			     =>
			     "TT/taut.cgi?exercise=$exercise&action=New");
	  last TYPES;
      }
      if ($extype =~ /EXP/i) {
	  print
	      $cgi->redirect(-uri
			     =>
			     "Exp/finiteuni.cgi?exercise=$exercise&action=New");
	  last TYPES;
      }
      if ($extype =~ /venn2/i) {
	  $extype =~ s/\s//g;
	  print
	      $cgi->redirect(-uri
			     =>
			     "Venn/$extype.cgi?exercise=$exercise");
	  last TYPES;
      }
      if ($extype =~ /venn/i) {
	  print
	      $cgi->redirect(-uri
			     =>
			     "Venn/venn.cgi?exercise=$exercise");
	  last TYPES;
      }
      if ($extype =~ /DIAG/i) {
	  print
	      $cgi->redirect(-uri
			     =>
			     "Diag/diags.cgi?exercise=$exercise");
	  last TYPES;
      }
      if ($extype =~ /CE/i) {
	  print
	      $cgi->redirect(-uri
			     =>
			     "CE/counterexample.cgi?exercise=$exercise");
	  last TYPES;
      }
      if ($extype =~ /ARITH/i) {
	  print
	      $cgi->redirect(-uri
			     =>
			     "Arith/arithmetic.cgi?exercise=$exercise");
	  last TYPES;
      }
      if ($extype =~ /SV_COND/i) {
	  print
	      $cgi->redirect(-uri
			     =>
			     "SV/sv-cond.cgi?exercise=$exercise");
	  last TYPES;
      }
      
      &start_polpage();

      print 
	  "Exercise $exercise is of type $extype and is not yet available";
  }

    &pol_footer;
    &end_polpage;
}

###
sub generate_chapter_menu { # this is the main menu
    $subtitle = "Exercises";
    $instructions = "Pick a chapter or area";

    #$polmenu{'McGraw-Hill'} = $PUBLISHER_URL;  # don't give them any space for 4e
    $polmenu{'Textbook HOME'} = $BOOKHOME_URL;  # but publicize the book

    &start_polpage;
    print  # create a table containing all the problems in the exercise
	"<table style=\"width: 700px; padding: 5px; margin: 5px; border: 1px solid black; background: $WORKSPACEBGCOLOR\"><!--begin probs-->\n";

    print # banner and separator
	"<tr><td colspan=\"4\" style=\"text-align: left; background-color: $HEADERBGCOLOR; padding: 4px\">",
	"<img src=\"/6ebeta/Images/6ebulb.jpeg\" alt=\"6th edition lightbulb logo\" style=\"height: 150px; margin-top: 2px; float: right\"/>",
	h1("Chapter Menu"),
	"<img src=\"$polcsl\" width=\"600\" alt=\"$EDITION banner image\">",
	"</td></tr>",
	"<tr><td colspan=\"4\" align=\"center\">",
	"</td></tr>",
	;
    
    my $left=1;
    foreach $item (@chapternums) { # two column mode
	## temporary throttle -- install until MH pays up!
	#next if ($site =~ /poweroflogic/ && $item =~ /\d/ && $item > 7);
	my $rawtitle = $chapters{$item};
	my ($title,$subtitle) = split(/:/,$rawtitle,2);
	my $url = $cgi->url;
	$subtitle =~ s/:/:<br>/;
	$subtitle = "<br><strong>$subtitle</strong>\n" if $subtitle;	
	$item =~ s/^0//; # strip leading zero
	print "<tr>\n" if $left;
	print 
	    td({-style=>'border: 0px solid blue; width: 20px; text-align: right; margin: 0px 10px 30px 10px;'},
	       $cgi->startform(),
	       $cgi->hidden(-name=>'chapter',-value=>$item),
	       $cgi->image_button(-src=>$smallPoLogo,
				  -style=>'border:1px dotted gray;'),
	       $cgi->endform),
	    td({-style=>'border: 0px solid blue; width: 100px; text-align: left; padding: 5px; color: $WORKSPACETEXTCOLOR'},
	       "<a href=\"$url?chapter=$item\" class=\"plain\">",
	       "$title",
	       "</a>\n",
	       $subtitle,
	       ),
	    ;
	print "</tr>\n" if !$left;
	$left = !$left;
    }

    print "</table><!--end probs-->";
    &end_polpage;
}

sub generate_exercise_menu {
    my $CONTENTS = 'contents.pl';
    local ($CHAPNUM) = @_;

    require "$EXHOME$CHAPNUM/$CONTENTS"; # now we can use %chapter
    local $subtitle = "Exercises for $chapter{'title'}";
    local $instructions = "<h3 style=\"color: $INSTRUCTCOLOR;\">Select an exercise</h3>";
    my $secnums = $chapter{'sections'};

#header
    &start_polpage();
    &pol_header($subtitle,$instructions);

# menu items

    print
	"<table border=\"0\" width=\"100%\"><!-- begin inner table -->";  

    while ($secnums) {
	($currsec,$secnums) = split(/ /,$secnums,2);
	my $section = "sec$currsec";
	my %labels = %{$chapter{$section}{labels}};
	my @values = sort(keys %labels);

	if ($currsec == 999) {
	    print Tr(td(&ryo_selection($section,\%labels)));
	} else {
	    print Tr(td(&section_menu($section,\%labels)));
	}
    }

    print
	"</table><!-- end inner -->\n",            # close inner table 
	;

    &pol_footer;
    &end_polpage;
}

sub section_menu {
    my ($section,$labelref) = @_;
    my $menu;
    $menu .= strong("$CHAPNUM.$currsec $chapter{$section}{'title'}");
    $menu .= "<table border=0>";
    foreach $section (sort keys %$labelref) {
	if ($$labelref{$section} =~ /not available/i) {
	    # note that even though they are redundant, we keep the form
	    # elements below so that the table cells align properly with
	    # those items where they are not redundant
	    $menu .= $cgi->startform;
	    $menu .= Tr(td({-valign=>'middle'},
			   ["&nbsp;&nbsp;",
                            join ("\n",
				  $cgi->hidden(-name=>'selected_exercise',
					       -value=>'void'),
				  "<img src=$smallgreyPoLogo border=0>"),
			    "<font color=\"gray\">$$labelref{$section}</font>",
			    "&nbsp;",
			    ]));
	    $menu .= $cgi->endform;

	} else {
	    $menu .= $cgi->startform;
	    $menu .= Tr(td({-valign=>'middle'},
			   ["&nbsp;&nbsp;",
			    join ("\n",
				  $cgi->hidden(-name=>'selected_exercise',
					       -value=>$section),
				  $cgi->image_button(-name=>'void',
						     -src=>$smallPoLogo,
						     -alt=>"click for $section",
						     -style=>'border:1px dotted gray;'
						     )),
			    $$labelref{$section},
			    ]));
	    $menu .= $cgi->endform;
	}
    }
    $menu .= Tr(td("&nbsp;"));
    $menu .= "</table>";
    return $menu;
}

sub ryo_selection {
    my ($section,$labelref) = @_;
    my $menu;
    $menu .= "<p>";
    $menu .= strong("User Created Exercises");

    $menu .= "<table border=0>";
    foreach $probset (sort keys %$labelref) {
	$menu .= $cgi->startform;
	$menu .= Tr(td({-valign=>'middle'},
		       ["&nbsp;&nbsp;",
			join ("\n",
			      $cgi->hidden(-name=>'chapter',
					   -value=>$probset,
					   -override=>1),
			      $cgi->image_button(-name=>'void',
						 -src=>$smallPoLogo,
						 -style=>'border:1px dotted gray;'
						 )),
			join ("",
			      "<a href=\"".$cgi->url,
			      "?chapter=$probset",
			      "\">X</a>. ",
			      $$labelref{$probset}),
			]));
	$menu .= $cgi->endform;
    }
    $menu .= Tr(td("&nbsp;"));
    $menu .= "</table>";
    $menu .= "</p>";
    
    return $menu;
}

sub html_error { # dirty exit
    my ($err_msg) = @_;

#    &mailit("logic.pedallers\@gmail.com",$err_msg);
    &start_polpage("Error");
    &pol_header("ERROR");
    print
	h2($err_msg),
	$cgi->startform,
	$cgi->submit(-name=>'void',-value=>'Click to continue'),
	$cgi->endform,
	$cgi->Dump;
    &pol_footer;

    &end_polpage;
}
