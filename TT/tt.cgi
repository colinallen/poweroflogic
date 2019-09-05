#!/usr/bin/perl

# tt.cgi
# 

# Version 0.1

# Library
use IPC::Open2;
require "../lib/header.pl";
require "../lib/wff-subrs.pl";
require "./evaluate-tt.pl";
require "./make-tt-template.pl",
require "./check-validity.pl";
require "./messages.pl";

$debug=0;
$mailto='cmenzel';
$program = $cgi->url;

@prev_chosen = @POL::prev_chosen if @POL::prev_chosen;
shift @prev_chosen if (@prev_chosen and !@prev_chosen[0]); # get rid of that damn empty first element

####################################################
# ADD LOCAL MENU ITEMS HERE
# $polmenu{"Main Menu"} = "../menu.cgi";
$polmenu{"Help with truth tables"} = "../help.cgi?helpfile=tt-help.html";

if ($POL::exercise) { # add menu items
    my($chapter,$rest)=split(/\./,$POL::exercise,2);
    if ($POL::action !~ /New/) {
        $prev_chosen_string = '&prev_chosen='.join('&prev_chosen=',@prev_chosen);
        $polmenu{"More from Ex. $POL::exercise"} = "$program?exercise=$POL::exercise&action=New$prev_chosen_string";
    }
    $polmenu{"More from Ch. $chapter"} = "../menu.cgi?chapter=$chapter";
}
#####################################################

#$IP = $cgi->url;
#$IP =~ s/http:\/\/(.*?)\/.*/$1/;
#$arg = eval ('$POL::argument_'.$POL::problem_num) ;

for ($POL::action) {
#    /Template/ and do { &send_tt_template($POL::template_arg) };
    /Another|New|Choose/ and do { &picktt; last };
    /Problem/            and do { &tt_form($POL::argument); last };
    /Make/               and do { &process_user_argument($POL::user_argument); last };
    /Check/              and do { &evaluate_tt; last };
    /Valid|Invalid/      and do { &check_validity; last};
    /Return/             and do {
	print $cgi->redirect(-uri=>"../menu.cgi?chapter=$chapter");
	last;
    };
    &roll_yer_own_tt;
}

&bye_bye();  # CHECK AT SOME POINT WHETHER THIS IS DOING ANYTHING...

############################################################
sub picktt {
    my @problems;
    my ($chapter) = split(/\./,$POL::exercise,2);
    my $probfile = "$EXHOME$chapter/$POL::exercise";
    my $subtitle = "Exercise $POL::exercise".": Truth Tables";
    $subtitle = "Create your own truth table" unless $subtitle;
    my $instructions = "<span style=\"color: $INSTRUCTCOLOR; font-weight: bold \">Pick an argument to work on!</span>";
    my $preamble = "";
    
    $cgi->delete('tt'); # delete any previous selection

    $probfile =~ s/\||\.\.//g; # close pipeline exploit; CA 9-17-2004
    open(FILE,$probfile) || &html_error("Could not open problem file $probfile");
    while (<FILE>) {
	$preamble .= $_ and next if /^\#!preamble/;
	next if /^\s*$|^\#/;
	chomp;
	push @problems, $_;
    }
    close(FILE);
    $preamble =~ s/\#!preamble//g;
    $instructions .= "<br>".$preamble;
    if (@prev_chosen) {
	$instructions .= $PREVCHOICEINSTRUCTION;   # Note that $smallgreyPoLogo indicates previous selection
    }


    &start_polpage('Choose an argument');
    &pol_header($subtitle,$instructions);  # create outer table, print the PoL header

    print                    # create a table containing all the problems in the exercise
      "<table width=100% border=0>\n";

    foreach $argument (@problems) {
	++$count;
        $cgi->param('problem_num',$count);
	$pretty_arg = ascii2utf_html($argument);
#	$pretty_arg = &prettify_seq($argument);  # &prettify_seq found in make-tt-template.pl
#	$pretty_arg =~ s/[<]/&lt;/g;
#	$pretty_arg =~ s/[>]/&gt;/g;
#	$pretty_arg = "(Too long to display)" if length($pretty_arg) > 70;
#	$pretty_arg =~ s/(:\.)|(\.:)/<img align=bottom src=$therefore>/ if $pretty_arg !~ /Too/;

        print           # Start a new row, new form
	    "<tr>\n",
	    $cgi->startform(),
	    ;

        my $logo = $smallPoLogo;
        $logo = $smallgreyPoLogo if (grep {$count == $_} @prev_chosen);

	print        # Print the image button with problem info
	    "<td valign=\"bottom\" align=\"left\" width=\"30px\">\n",
	    $cgi->image_button(-name=>'void',-src=>$logo,
			       -style=>"border: 1px dotted gray;"),"\n",
	    "</td>";
	
	print           # Print the problem number
          "<td valign=\"center\" align=\"left\" bgcolor=\"$RIGHTPAGECOLOR\" width=\"30px\">",
          "<b>$count.</b>",
          "</td>";

        print           # Print the problem
	    "<td valign=\"center\" align=\"left\">",
	    "<tt>\n",
	    "$pretty_arg",
	    "</tt>\n",
	    "</td>\n";

        print           # End the form & row
	    $cgi->hidden(-name=>'exercise',-value=>$POL::exercise,-override=>1),"\n",
	    $cgi->hidden(-name=>'action',-value=>"Problem",-override=>1),"\n",
	    $cgi->hidden(-name=>'argument',-value=>$argument,-override=>1),"\n",
	    $cgi->hidden('problem_num',-override=>1),"\n",
	    $cgi->hidden(-name=>'prev_chosen',-value=>[ @prev_chosen ], override=>1),"\n",
	    $cgi->endform,
	    "</tr>\n";
    }

    print "</table>\n";

    &pol_footer;                                              # Close the table started by pol_header
    &end_polpage;                                             # Close the table started by start_polpage
}

##############################################################
# Takes as input either the argument from a problem file or an
# argument created by the user and creates a TT template to be
# completed by user.

sub tt_form {

    local ($arg,$flag) = @_;  # $flag indicates $tt is being redisplayed in error msg
    my $tt_template = &make_tt_template($arg);
    $border = 3 unless defined $border;

### prev_chosen maintenance
    push (@prev_chosen, $POL::problem_num) if $POL::problem_num;
    @prev_chosen = &remove_array_dups(@prev_chosen);
    $cgi->param('prev_chosen',@prev_chosen);

    $subtitle = "Exercise $POL::exercise Problem $POL::problem_num\n" if $POL::exercise;
    $subtitle = "Create your own truth table" unless $subtitle;
    $instructions = "Complete the truth table!"; # unless $answer;

    local $atoms = $tt_template;
    $atoms =~ s/^(.*?)\|.*/$1/s;
    local $numatoms = $atoms =~ tr/A-Z/A-Z/;
    local $numrows = 2**$numatoms;
    local $pretty_seq = $tt_template;
    $pretty_seq =~ s/^.*?\| (.*?)\n.*/$1/s;  # extract the sequent from tt_template
    $pretty_seq =~ s/\s*$//;             # remove any trailing spaces or tabs

#    local $row_1_length = length("$atoms| $pretty_seq");
    local $table_width = length("$atoms| $pretty_seq")+5;
    local $table_length = $numrows+5;

#    print 
#	"arg: $arg<br>",
#	"tt_template: $tt_template<br>",
#	"atoms: $atoms<br>",
#	"table_width: $table_width<br>",
#	"table_length: $table_length<br>";

    local $dashes;
    for ($i=1;$i<=length($atoms);$i++) {
	$dashes .= "-";
    }
    $dashes .= "|";  # that's a vertical bar in case you are looking at this in xemacs
    for ($i=1;$i<=length($pretty_seq)+1;$i++) {
	$dashes .= "-";
    }

# $assigned_tvs is a string that looks like this: T T T|T T F|T F T| ...  used in evaluate_tt

    local $assigned_tvs = $tt_template;
    $assigned_tvs =~ s/(.*?\n){2}(.*)/$2/;

    &start_polpage('Power of Logic: Truth Table exercise') if not $flag;
    &pol_header($subtitle,$instructions) if not $flag;


#    print "prev_chosen: @prev_chosen<br>";
#    print "problem_num: $POL::problem_num<br>";
#    print "PRETTY_SEQ: \'$pretty_seq\'";

    print # begin a one column, one row table to contain the truth table template
	"<center>\n",
	"<script language=\"javascript\" type=\"text/javascript\" src=\"$JSDIR/replace.js\" charset=\"UTF-8\"></script>",
	$cgi->startform(-onsubmit=>"replaceCharsRev(document.getElementById('tt'))"),
	"<table border=0>\n",
	;

    print # The one row contains the truth table template in a textarea
	"<tr><td align=left>\n",
        "<textarea onSelect=\"\" onkeyup=\"process(this)\" id=\"tt\" name=\"tt\" rows=$table_length cols=$table_width style=\"font-family: monospace\">",
	ascii2utf_html($tt or $tt_template),
	"</textarea>",
	"</td></tr>\n";
    
    print # close TT table
	"</table>\n";

    print
	"<hr width=98%>";

    print
	$cgi->submit(-name=>'action',-value=>'Check Truth Table Now!'),"\n",
	$cgi->hidden(-name=>'argument',-value=>$arg),"\n",
	$cgi->hidden(-name=>'atoms',-value=>$atoms),"\n",
	$cgi->hidden(-name=>'pretty_seq',-value=>$pretty_seq),"\n",
	$cgi->hidden(-name=>'dashes',-value=>$dashes),"\n",
	$cgi->hidden(-name=>'assigned_tvs',-value=>$assigned_tvs),"\n",
	$cgi->hidden(-name=>'exercise',-value=>$POL::exercise,-override=>1),"\n",
	$cgi->hidden(-name=>'problem_num',-value=>$POL::problem_num,-override=>1),"\n",
	$cgi->hidden(-name=>'prev_chosen',-value=>[ @prev_chosen ],-override=>1),"\n",
	$cgi->endform,"\n",
	"</center>\n";
    
    &pol_footer;                                              # Close the table started by pol_header
    &end_polpage;                                             # Close the table started by start_polpage

#    &footer();
#    &bye_bye();
}

###########################################################
# This subroutine takes a user-created argument and ensures
# that all of its components are wffs, and then turns it 
# into problem file format and hands it to &tt_form.

sub process_user_argument {
    local $arg = shift;
    chomp($arg);

    if ($arg =~ /^\s*$/) {              # Case where nothing (except perhaps whitespace) is entered
	&start_polpage();
	&pol_template($head_NothingEntered,&msg_NothingEntered);
	&end_polpage;                   # Close the table started by start_polpage
    }

    if ($arg !~ /:\.|\.:/) {            # Case where no :. is entered
	&start_polpage();
	&pol_template($head_NoTherefore,&msg_NoTherefore);
	&bye_bye();
    }	

    $conclusion = $arg;
    $conclusion =~ s/^(.*)((:\.)|(\.:))\s*(.*)/$5/;  # Extract the purported conclusion
    my $premises = $1;
    $premises =~ s/\s*//g;
    $conclusion =~ s/\s*//g;              # remove whitespace

    if ($conclusion =~ /^\s*$/) {
	&start_polpage();
	&pol_template($head_NoConclusion,&msg_NoConclusion);
	&bye_bye();
    }

    if ($premises) {
        my @premises = split(/,/,$premises);
        foreach $premise (@premises) {
            if (!&wff($premise)) {
                &start_polpage();
                &pol_template($head_RYOPremiseNotWff,&msg_RYOPremiseNotWff($premise));
                &end_polpage;
                &bye_bye();
            }
        }
    }

    if (!&wff($conclusion)) {           # Check for WFFness of $conclusion

	&start_polpage();
	&pol_template($head_ConclusionNotWff,&msg_ConclusionNotWff);
	&end_polpage;
    }

    $arg =~ s/((:\.)|(\.:)).*//g;          # remove :. or .: and conclusion
    $arg =~ s/\s*//g;                      # remove spaces
    $arg .= ":.$conclusion";
    &tt_form($arg);

}



###########################################################
sub roll_yer_own_tt {

    local $subtitle = 	"Create your own truth table",
    local $instructions .= "<span style=\"color: $INSTRUCTCOLOR; font-weight: bold\">Enter an argument in the text area.</span><br>";
    $instructions .= "Click below to complete a truth table for your argument.<br>";
    $instructions .= "</strong>(Be sure that adjacent premises are separated by a comma<br>";
    $instructions .= "and that a <tt>:.</tt> precedes the conclusion, e.g., <tt>PvQ, ~Q.S :. P</tt>.)</font><br>";

    &start_polpage('Power of Logic: Truth Table exercise');

    print
	$cgi->startform();

    &pol_header($subtitle,$instructions);

    print
	"<center>\n",
	"<p>",
	#"<div style=\"border: 1px solid green; width: 150px\">",
	$cgi->textfield(-name=>'user_argument',
			-style=>'font-family: monospace',
			-size=>50,-default=>''),
	#"</div>",
	"<br>",
	$cgi->submit(-name=>'action',-value=>'Make the truth table!'),
	$cgi->endform,
	"</center>";

    &pol_footer;    # Close the table started by pol_header
    &end_polpage;   # Close the table started by start_polpage

}

###
sub prettify_argument {
    my $arg = $_[0];
    $arg =~ s/([^:])\. /$1\+ /g;
    $arg =~ s/([^:])([\.v]|->|<->)([^:])/$1 $2 $3/g;  # add spaces b/w binary connectives
    $arg =~ s/\+/\./g;
    $arg =~ s/\+/&nbsp;/g;
    return $arg;
}


############################################################
sub html_error { # dirty exit
    my ($err_msg) = @_;

    &start_polpage('Error');
    print
	$err_msg,
	$cgi->Dump,
	end_html;
    &end_polpage;                                             # Close the table started by start_polpage
#    &bye_bye();
}
