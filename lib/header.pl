# Filename: header.pl

use CGI qw(:standard :html3 -no_xhtml);
$cgi = new CGI;
$cgi->import_names('POL');

#push @INC, "/home/www/sites/$site/cgi" if $site;

if (-f "lib/pol.conf") { # running from upper level
    require "./lib/pol.conf";
    require "./lib/logit.pl";
    require "./lib/pageout.pl";
} else { # down and dirty
    require "../lib/pol.conf";
    require "../lib/logit.pl";
    require "../lib/pageout.pl";
}

@chapternums = sort(keys %chapters);

$program = url();
if ($program =~ /(\/\de\w*)\//) {
    $EDITION = $1;
    $cgibase = "/cgi$EDITION";
} else {
    $cgibase = '/cgi';
}

# &logit($cgi->Dump,1) if $program =~ /(tt|taut).cgi/;

%polmenu =
    ('About this site'=>($EDITION|'/'),
     'Bug Webmaster'=>"$cgibase/help.cgi?helpfile=bugs.html;helpsubject=Email+Logic+Pedallers",
     'Web Site by ...'=>"$EDITION/about.html",
     );

$polmenu{'Main Menu'} = "$cgibase/menu.cgi"
    unless $program =~ /menu/ and !$POL::chapter;

$cryptkey='fjkdf43943.';

#%pageoutid = cookie('pageout');

#relax wff rules Exercise 9.7 and beyond
$longjunctions = 1 if $POL::exercise =~ /^9\.[78]/;

#########################################################
# start_polpage generates:
#  (1) beginning of table for an entire PoL page
#      -- THIS TABLE IS CLOSED IN THE end_polpage SUBROUTINE.
#  (2) the Menu cell to the left of the page (which itself contains a table)
#      via &polmenu
#  (3) the beginning of the Workspace cell -- just a <td>

sub start_polpage {
    my ($title) = @_;
    $title = "Power Of Logic Tutor" if !defined($title);

    my $return = $cgi->self_url;

# COOKIE block
# no cookies currently required
#    if ($cgi->param('student_id')
#	&& $cgi->param('course_id')) { # new authentication
#	$polmenu{'Logout'} = "$cgibase/login.cgi?logout=$return";
#	
#	# make data available globally
#	%pageoutid = ('student_id'=> $cgi->param('student_id'),
#		      'course_id' => $cgi->param('course_id'),
#		      'tool_id' => $cgi->param('tool_id'));
#	
#	# create cookie
#	$pageoutcookie = &create_pageout_cookie($cgi->param('student_id'),
#						$cgi->param('course_id'),
#						$cgi->param('tool_id'));
#	
#	
#    } elsif (%pageoutid) {  # previously authenticated
#	
#	# give logout option
#	$polmenu{'Logout'} = "$cgibase/login.cgi?logout=$return";
#	
#	# refresh cookie
#	$pageoutcookie = &create_pageout_cookie($pageoutid{'student_id'},
#						$pageoutid{'course_id'},
#						$pageoutid{'tool_id'});
#	
#	
#    } else { # no authentication
#	
#	# provide login option
#	#$polmenu{'Login@PageOut'} = "$cgibase/login.cgi?login=$return"
#	#    unless $program =~ /login/;
#	
#	# make sure that cookie is nullified
#	$pageoutcookie = &null_pageout_cookie;
#    }
#    
#    if (!%pageoutid) {
#	$pageoutstatus = 'not logged in';
#    } else {
#	$pageoutstatus = join " ",%pageoutid;
#    }

    
    print # beginning of response page
	header(#-cookie=>$pageoutcookie,
	       -Pragma=>"no-cache",
	       -charset => 'utf-8'),
	start_html(#-title=>"$title -- $pageoutstatus",
		   -title=>"$title",
		   -author=>'logicpedallers@gmail.com',
		   -meta=>{'keywords'=>'logic propositional venn predicate',
			   'copyright'=>'copyright 2002-2019 Logic Pedallers',
			   'Content-type'=>'text/html; charset=utf-8'},
		   -background=>$polbg,
		   -style=>{'src'=>'/5e/Styles/main.css'}, ## <<<------UNCHANGED for 6e ??
		   -bgcolor=>$LEFTPAGECOLOR,
		   ),
	;


#    print
#	"<div style=\"background-color:$ALERTBGCOLOR\">",
#	"<h3 style=\"color:$ALERTTEXTCOLOR\">",
#	"Please note that we will be offline for a couple of hours for routine maintenance on Saturday December 23, from approximately 10:30 a.m. Eastern (US) time.",
#	"</h3>",
#	"</div>",
#	;
    
    print # BEGINNING OF TOP LEVEL TABLE (closed in end_polpage)
	"\n<table width=\"100%\" border=\"0\"><!-- top level table -->\n",
	"\n<tr><!--The single row within the top level table starts here-->\n",    # Closed in end_polpage
	"\n<td width=\"140\" valign=\"top\">",
	"<!--Menu cell starts here-->\n";

    &polmenu;

    print # END OF MENU CELL BEGINNING OF WORKSPACE CELL
	"\n</td><!--End of menu cell-->\n",
	"\n<td width=20>&nbsp;&nbsp;&nbsp;</td><!-- cell for spacing -->\n",
	"\n<td valign=\"top\">",
	"<!--Workspace cell starts here-->\n";  # Closed in end_polpage

#      print ## COMMENTED OUT BY CPM, 11 APRIL 2016
# 	 "<div style=\"color: maroon; background-color: ivory; font-size: 12px; border: 1px solid red; padding: 5px; width: 698px\">",
# 	 "This is the site for the Power of Logic 5th edition. ",
# 	 "If you discover something that is not working as expected, please send email via the \"Bug Webmaster\" link at the left. ",
# 	 "<br>",
# 	 "<b>NOTE: Record keeping through McGraw-Hill's PageOut system has been discontinued effective immediately, but this website will remain active for student practice.</b>",
# 	 "</div>";
    
    
#    ### ALERT!!! ###
#    if (0 && $pageoutstatus eq 'not logged in' && $program !~ /login/) {
#	print
#	    "<div style=\"color: #000000; background: ivory; font-size: small; padding: 5px; width: 700px\">",
#	    "You are not currently logged in with a <a
#	    href=\"http://www.pageout.net/\">PageOut</a>&reg; student
#	    account. You may continue using this site without being
#	    logged in, but if you are a student with a registered
#	    PageOut&reg; account your work will not be recorded unless
#	    you log in first. If you were previously logged in but your
#	    session has been inactive for an hour, your cookie has
#	    expired and you must go back to your instructor's
#	    PageOut&reg; site and log in again. If your login id is
#	    being dropped immediately after logging in, please read 
#	    <a href=\"$cgibase/help.cgi#LoginProb\">these instructions</a>.",
#	    "</div>\n",
#	    ;
#    }

    print # a bit of padding
 	"<div style=\"margin: 10px;\">",
	"</div>",
	;


}


###############################
# polmenu generates the content of the menu inside the Menu Cell.  It puts the content within a table.
# This table is closed off inside the routine.
## CA started shift to CSS on 2/11/07

sub polmenu {
    # compute chapter if we can
    my $file = $cgi->param('probfile');
    my $exercise = $cgi->param('exercise');
    my $chapter = $cgi->param('chapter');
    my $title = '';

    my $menuimage = "<img src=\"$EDITION/$cover6e\" #######<<<==== remove $EDITION/ for 6e release
                          alt=\"$EDITION cover image\" 
                          style=\"border: 0px\" width=\"150\">";  # <<<========= NEED 6E UPDATE

    if (!defined($chapter)) {
	if ($file) {
	    $file =~ /.*\/(\d\d?)\..+$/;
	    $chapter = $1;	
	} elsif ($exercise) {
	    $exercise =~ /(\d\d?)\..+$/;
	    $chapter = $1;	
	}
    } else {
	$title = $chapters{$chapter};
	$title =~ s/:/:<br>/g;
    }
    # assign image based on chapter
    
    my $chindex = $chapter;
    $chindex = "0$chapter" if $chindex =~ /^\d$/;
    $chapterimage = "<div style=\"height: 200px; background-color: $ChIMGCOLOR; text-align:center;\"><img src=\"/6e/Images/6e-ch$chapter.jpeg\" alt=\"$EDITION ch$chapter logo\" style=\"height: 165px; margin-top: 2px;\"/></div>"
	if $chapters{$chindex};

    $chapterimage = "<div style=\"height: 200px; background-color: $ChIMGCOLOR; text-align:center;\"><img src=\"/6e/Images/6ebulb.jpeg\" alt=\"6th edition lightbulb logo\" style=\"height: 165px; margin-top: 2px;\"/></div>"
	unless $chapterimage;
    
    #start table
    print
	"\n\n<table border=\"0\" cellspacing=\"0\" cellpadding=\"2\" width=\"140\">",
	"<!--Begin Menu Table-->\n";
	
    #image
    print
	Tr([ td({-colspan=>2,-align=>'left'},
		"<a href=\"$cgibase/menu.cgi\">$menuimage</a>"),
	     td({-colspan=>2,-align=>'center'},
		"\n<font color=\"$MENUTEXTCOLOR\">",
		"\n<strong>PoL WEB TUTOR</strong>",
		"\n</font>"),
	     ]);

    #top element -- "MENU"
    print
	Tr(td({-colspan=>2, -align=>'center'},
	      "<hr color=\"black\">",
	      "\n<strong>",
	      "\n<font color=\"$MENUTEXTCOLOR\" size=\"+1\">MENU</font>",
	      "\n</strong>",
	      "<hr color=\"black\">",
	      ));

    #include variable elements
    my @items = sort (keys %polmenu);
    foreach $item (@items) {
	&polmenu_item($item,$polmenu{$item});
    }

    print # menu footer
	Tr(td({-align=>'left',-colspan=>2},
	      "\n<hr color=\"black\">",
	      &grading_status ## will page out be disabled for 5e?
	      )),
	"\n</table><!--End Menu Table-->\n";
    print
	"<div style=\"padding:5px; font-size:10px; text-align:left\">",
	"&copy; 2012&ndash;",
	"<script>document.write(new Date().getFullYear())</script>",
	" ",
	"Logic Pedallers and McGraw-Hill",
	"</div>";

}

sub polmenu_item {
    my($title,$uri) = @_;
    $title =~ tr/a-z/A-Z/;
    
    my $special;
    if ($title =~ /^help/i) {
	$special .= "<div style=\"color: red; font-size: 12px;\">";
	$special .= "<a href=\"$uri\" target=\"help\" style=\"color: $MENUTEXTCOLOR\; text-decoration: none;\">";
	$special .= "--&gt;";
	$special .= "[in new window]";
	$special .= "</a>";
	$special .= "</div>";
    }
    
    print
	Tr(td({-align=>'center',-valign=>'top',-width=>"20"},
	      "\n<a href=\"$uri\" target=\"_top\">",
	      "\n<img src=\"$smallPoLogo\" border=\"0\" valign=\"bottom\" alt=\"pointer graphic\"></a>",
	      ),
	   td({-align=>'left',-valign=>'middle',width=>120},
	      "\n<a href=\"$uri\" target=\"_top\">",
	      "\n<font color=\"$MENUTEXTCOLOR\" size=\"-1\">",
	      "\n<strong>$title</strong>",
	      "</font>",
	      "</a>",
	      $special));
}

sub polmenu_item_old {
    my($title,$uri) = @_;
    $title =~ tr/a-z/A-Z/;
    my $special;
    $special = 	join "", ("\n<br>",
			  "<NOBR>",
			  "\n<FONT COLOR=$MENUTEXTCOLOR SIZE=-3>",
			  "--&gt;",
			  "</FONT>",
			  "\n<a href=\"$uri\" target=\"help\">",
			  "<FONT COLOR=$MENUTEXTCOLOR SIZE=-3>",
			  "[in new window]",
			  "</FONT>",
			  "</a>",
			  "\n</NOBR>")
	if $title =~ /^help/i;
    
    print
	Tr(td({-align=>'center',-valign=>'top',-width=>"20"},
	      "\n<a href=\"$uri\" target=\"_top\">",
	      "\n<img src=\"$smallPoLogo\" border=\"0\" valign=\"bottom\" alt=\"small diamond\"></a>",
	      ),
	   td({-align=>'left',-valign=>'middle',width=>120},
	      "\n<a href=\"$uri\" target=\"_top\">",
	      "\n<font color=$MENUTEXTCOLOR size=-2>",
	      "\n<strong>$title</strong>",
	      "</font>",
	      "</a>",
	      $special));
}


#########################################################
# pol_header prints the header for the Workplace Cell
# (within the top-level table) on the right side of a PoL page
# It puts the header inside of a table within the Workplace Cell
# -- note that the inner table (logo table below) 
# is closed off in this subroutine but THE TABLE WITHIN THE
# WORKSPACE CELL (TABLE 1) IS CLOSED IN pol_footer!
# MUTATIS MUTANDIS for new div version - CA
#########################################################

sub pol_header {
    my ($subtitle,$instructions,$width) = @_;
    $subtitle =~ s/--/<br>/;

    $width="700px" unless $width;

    print  # bounding div to replace table by CA
	"<div style=\"width: $width; border: 2px solid yellow; padding: 5px; background: $WORKSPACEBGCOLOR\">\n", # not closed until footer
	## infobox
	"<div style=\"height: 178px; background-color: $HEADERBGCOLOR; padding: 5px; border: 0px solid black\"><!--bounding box for header-->\n",


	# header content	
	"<div style=\"height: 165px; border: 0px solid $PAGEBGCOLOR; margin: 0px;\"><!--  -->\n",
	#images at top
	## CHAPTER SPECIFIC IMAGE
	"<div style=\"float: left; padding: 0px 10px 0px 0px\">$chapterimage</div>\n",
	"<img src=\"$polcsl\" style=\"border: 0px solid green; margin: 0px 0px 0px 0px\" alt=\"$EDITION book banner\" width=\"450px\"/>\n",

	###text
	"<div style=\"height: 138px; text-align: left; padding: 2px; margin: 0px 0px 0px 0px; font-weight: bold; color: $MENUTEXTCOLOR; border: 0px solid black\"><!--textbox-->\n",
	"<span style=\"font-size: 24px;line-height: 1.5em\">$subtitle</span>\n",
	"<br />\n",
	"<span style=\"font-size: 14px; font-weight: normal; color: $INSTRUCTCOLOR\">$instructions</span>\n",
	"</div><!--end textbox-->\n", # for title and subtitle

	#image at bottom
	"<img src=\"$polcsl\" style=\"border: 0px solid green; margin: 0px 0px 0px 0px\" alt=\"$EDITION book banner\" width=\"450\"/>\n",
	"</div>\n", # close inner div
	###
	
	"</div><!--end bounding box for header-->\n",
	## end infobox
	"<br />",
	#"<hr />",
	;
}

# short_pol footer: should no longer be used - for retro code only
$short_pol_footer=" ";
$pol_footer=$short_pol_footer;

sub pol_footer { # canonical name of bookend for pol_header 
    &footer();
}

sub footer { # old function name - remove after retrofit
    print                                  # end of pol_header table
	"</div><!-- end workspace div -->\n";

    #"</table><!-- end workspace table contained within workplace cell -->\n";

}

###
sub remove_array_dups {
    my %seen = ();
    return grep { ! $seen{$_} ++ } @_;
}

###
sub remove_string_dups {
    my $str = shift;
    while ($str =~ /(.).*\1/) 
	{$str =~ s/(.)(.*)\1/$1$2/g}
    return $str;
}

####################################################################
sub end_polpage { # bookend for start_polpage
    &bye_bye(@_);
}

sub bye_bye {
    my $debug=0;
    my $debug=1 if ((url() =~ /beta/) || $POL::debug);

    print
	"\n</td><!--End of workspace cell-->",
	"\n</tr><!--End of single top level row-->",
	"\n</table><!-- End top level table -->",
	;
    
    print
	"<p>\n",
	"<hr>\n",
	"[Program run on $ENV{'SERVER_NAME'} -- debugging info shown below]\n",
	"<br>",
	$cgi->Dump()
	    if $debug;

    print
	"cookie : $pageoutcookie"
	    if $pageoutcookie and $debug;
    
    print end_html();

#    local ($codedog,$logstuff) = @_;

#    if ($logstuff) {
#	&logit($logstuff);
#	&mailit($codedog,$logstuff);
#    }

    exit;
}

###
sub rot {
    $string = shift;
    $string =~ tr/ -NP-~/P-~ -N/;
    return $string;
}

###
sub grading_status { # CA mods on 1/2/14
    return "" ## disabled since demise of PageOut
	if 1 or url() =~ /login\.cgi/;
    return join("\n",
		"<font size=\"-2\" color=\"$MENUTEXTCOLOR\">",
		strong("LOGGED IN AS ",
		       $pageoutid{student_id}),
		"<br>",
		"PageOut record keeping enabled ",
		"for course ",
		strong($pageoutid{course_id}).".",
		"Select <strong>LOGOUT</strong>",
		"if this is not your id",
		"or you have finished this session.",
		"<p>",
		"Authentication expires ",
		scalar(gmtime(time+3600)),
		" GMT",
		"</font>")
	if %pageoutid;

    return join("\n",
		"<FONT SIZE=\"-2\" COLOR=\"$MENUTEXTCOLOR\">",
		strong("NOT LOGGED IN"),
		"<BR>",
		"Result logging will not be activated ",
		"until you <strong>LOGIN</strong> via ",
		"the McGraw-Hill PageOut site for your course.",
		"<P>",
		"Successful login will require that your browser accepts cookies.",
		"If your login id is being dropped, please read the
		instructions in the section &ldquo;Unable to Stay Logged
		In&rdquo; on the <a
		href=\"$cgibase/help.cgi#LoginProb\" style=\"color: maroon;\">Help
		page</a>.",
		"</FONT>",
		);
}

sub chapter_menu_button {
    my $resume = $cgi->param('resume');
    my $hidden = "";
    if ($resume =~ /^\d+$/) { # chapter mode
	$hidden = hidden(-name=>'chapter',-value=>$resume);
    } elsif ($resume) {
	$hidden = hidden(-name=>'selected_exercise',-value=>$resume);
    }
    return join "\n",
    (
     startform(-action=>"$cgibase/menu.cgi"),
     $hidden,
     submit(-name=>'goto',-value=>"Continue..."),
     endform(),
     );
}

sub html_error { # dirty exit
    my ($err_msg) = @_;
    print
	header(),
	start_html(-title=>'Error'),
	$err_msg,
	$cgi->Dump,
	end_html;
    &bye_bye;
}
