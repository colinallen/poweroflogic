#!/usr/bin/perl
# started by CA Dec 17 2001

require './lib/header.pl';

$PAGEOUT_HOME = "http://www.pageout.net/";

if ($POL::login) {
    &start_polpage("Login to PageOut");
    &pol_header('How to Get Logged in to <BR> McGraw-Hill\'s PageOut&reg; System');
    print
	"If you are a registered student in a course for which ",
	"<EM>The Power of Logic</em> is a required text, and your ",
	"instructor has set up online assignments on the PowerofLogic ",
	"web tutor, then you must enter the PowerofLogic site through ",
	"the PageOut&reg; system in order for your scores to be recorded correctly.",
	"<P>",
	"Please check with your instructor to find out how to reach to ",
	"PageOut&reg; site for your specific course. Instructors should ",
	"visit ",
	"<A HREF=\"$PAGEOUT_HOME\">$PAGEOUT_HOME</A> for more ",
	"information about PageOut&reg;. ",
	"<P>",
	"All unregistered users are invited to work the exercises on the ",
	"site but we regret that no scorekeeping facility is available. ",
	;

    print
	"<p>",
	"Click <a href=\"$POL::login\">here</a> to go to main menu</a> (no login).",
	;

    if ($program !~ /poweroflogic/) {
	print
	    '<P ALIGN="CENTER">',
	    '[FOR MAYFIELD DEBUGGING ONLY]',
	    '<form>',
	    '<input type="hidden" name="student_id" value="723615">',
	    '<input type="hidden" name="course_id" value="107956">',
	    "<input type=\"hidden\" name=\"nextpage\" value=\"/cgi/$EDITION/menu.cgi\">",
	    '<input type="submit" name="action" value="Spoof Login">',
	    '</form>',
	    ;
    }

    &pol_footer;
    &bye_bye;

} elsif (param('logout')) {
    my $old_student_id = $pageoutid{'student_id'};
    my $old_course_id = $pageoutid{'course_id'};
    my $bookmark;
    if ($old_student_id and $old_course_id) {
        $bookmark = "http://$ENV{'SERVER_NAME'}/cgi/$EDITION/menu.cgi?";
        $bookmark .= "student_id=$old_student_id";
        $bookmark .= "&course_id=$old_course_id";
    }
    
    %pageoutid = ();
    $pageoutcookie = &null_pageout_cookie;
    
    $cgi->delete('student_id');
    $cgi->delete('course_id');
    
    &start_polpage('Disconnect PageOut&reg; Session');
    &pol_header('Disconnect from McGraw-Hill\'s PageOut&reg; System');
    
    print
        "You have disconnected from the PageOut&reg; record keeping system. ",
        "<P>",
        "To reconnect, with a different identity, you will need to log back in via the PageOut&reg; system using the special page that your instructor has created for your course. ",
        "<P>",
        "Click here to go to ",
        "<a href=\"/cgi/$EDITION/menu.cgi\">main menu</a>. ",
        "<P>",
        ;
    
    if (0 and $bookmark) { #### DISABLED ####
	print
	    "If you wish to reconnect using the previous identity, you may do so by clicking <a href=\"$bookmark\">here</a>. ",
	    "(You may wish bookmark this link if this is your identity.) ",
	    ;
    }

    &pol_footer;
    &bye_bye;
}


elsif (param('nextpage')) {
    my $uri = param('nextpage');
    my $et = '?';
    $et = '&' if $uri =~ /\?/;
    my $student_id = param('student_id');
    my $course_id = param('course_id');
    print $cgi->redirect($uri.$et."student_id=$student_id&course_id=$course_id");
}

else {
    print $cgi->redirect("/");
}

