#!/usr/bin/perl

# falsify.cgi
# 

# Version 0.1

# Library
use IPC::Open2;
require "../lib/header.pl";
require "../lib/wff-subrs.pl";
require "./evaluate-false.pl";
require "./make-tt-template.pl",
require "./check-validity.pl";

$debug=1;
$program = $cgi->url;

$POL::exercise="7.2C"; # should not be hardcoded

@prev_chosen = @POL::prev_chosen if @POL::prev_chosen;
shift @prev_chosen if (@prev_chosen and !@prev_chosen[0]); # get rid of that damn empty first element

####################################################
# ADD LOCAL MENU ITEMS HERE
# $polmenu{"Main Menu"} = "../menu.cgi";
$polmenu{"Help with abbreviated truth tables"} = "../help.cgi?helpfile=att-help.html";

if ($POL::exercise) { # add menu items
    my($chapter,$rest)=split(/\./,$POL::exercise,2);
    if ($POL::action !~ /New/) {
        $prev_chosen_string = '&prev_chosen='.join('&prev_chosen=',@prev_chosen);
        $polmenu{"More from Ex. $POL::exercise"} = "$program?exercise=$POL::exercise&action=New$prev_chosen_string";
    }
    $polmenu{"More from Ch. $chapter"} = "../menu.cgi?chapter=$chapter";
}
#####################################################

for ($POL::action) {
    /Choose|Another|New/ and do { &pick_att; last };
    /Problem/            and do { &att_form($POL::argument); last };
    /Make/               and do { &process_user_argument($POL::user_argument); last };
    /Check/          and do { &evaluate_false; last };
#    /Valid|Invalid/  and do { &check_validity($POL::action); last};
    /Return/         and do { 
	print $cgi->redirect(-uri=>"../menu.cgi?chapter=7");
	last;
    };
    &roll_yer_own_att;  ##  clean up this subroutine
}

&bye_bye();

############################################################
sub pick_att {
    my @problems;
    my ($chapter) = split(/\./,$POL::exercise,2);
    my $probfile = "$EXHOME$chapter/$POL::exercise";
    my $subtitle = "Exercise $POL::exercise".": Assigning Truth Values";
    my $instructions = "<center><strong><font color=$LEFTPAGECOLOR>Pick a compound statement to work on!</font></strong></center>";
    my $preamble = "";
    
    $cgi->delete('att'); # delete any previous selection

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

    &start_polpage('Choose an argument');
    &pol_header($subtitle);  # create outer table, print the PoL header and instructions

    print                                   # Print the preamble in the probfile
	"<table border=0>\n",
	"<tr><td align=left>\n",
	 $preamble,
	"</td></tr>\n",
	"</table>\n";

    if (@prev_chosen) {
            print $PREVCHOICEINSTRUCTION;       # Note that $smallgreyPoLogo indicates previous selection
    }

    print                                   # create a table containing all the problems in the exercise
	"<table width=100% border=0>\n";

    my $count=0;

    foreach $argument (@problems) {
	++$count;
        $cgi->param('problem_num',$count);
	
	$pretty_arg = ascii2utf_html($argument);	
# Old pretty arg
#	$pretty_arg = &prettify_argument($argument);
#	$pretty_arg =~ s/[<]/&lt;/g;
#	$pretty_arg =~ s/[>]/&gt;/g;
#	$pretty_arg =~ s/(:\.)|(\.:)/<img align=bottom src=$therefore>/;
#	$pretty_arg = "(Too long to display)" if length($pretty_arg) > 85;
#	$pretty_arg =~ s/(:\.)|(\.:)/<img align=bottom src=$therefore>/ if $pretty_arg !~ /Too/;  
	
	print 
	    $cgi->startform(),
	    "<tr>\n";
	
        my $logo = $smallPoLogo;
        $logo = $smallgreyPoLogo if (grep {$count == $_} @prev_chosen);

	print  # print the submit button
          "<td valign=bottom align=left>",
          $cgi->image_button(-name=>'void',-src=>$logo,
			     -style=>"border: 1px dotted gray;"),"\n",
          $cgi->hidden(-name=>'action',-value=>"Problem",-override=>1),"\n",
          $cgi->hidden(-name=>'exercise',-value=>$POL::exercise),"\n",
          $cgi->hidden(-name=>'argument',-value=>$argument),"\n",
          $cgi->hidden(-name=>'prev_chosen',-value=>@prev_chosen),"\n",
          $cgi->hidden('problem_num'),"\n",
          "</td>",
          ;
        
	print
          "<td valign=\"center\" align=\"left\" bgcolor=$RIGHTPAGECOLOR>",
          "$count. ",
          "</td>",
          "<td valign=\"center\" align=\"left\">",
          "<tt>\n",
          "$pretty_arg",
          "</tt>\n",
          "</td>\n",
          ;

        print
          $cgi->endform,
          "</tr>\n",
          ;
    }
    
    print
      "</table>\n";                # Close the table containing the problems

    &pol_footer;                   # Close the table started by pol_header
    &end_polpage;                  # Close the table started by start_polpage
}

###########################################################
# Takes as input either the argument from a problem file
# or an argument created by the user.

sub att_form {

    local ($arg,$flag) = @_;  # $arg is an unformatted argument from the prob file
                              # $flag indicates $att is being redisplayed in error msg
    my $att_template = &make_att_template($arg);
    $border = 3 unless defined $border;

### prev_chosen maintenance
    push (@prev_chosen, $POL::problem_num) if $POL::problem_num;
    @prev_chosen = &remove_array_dups(@prev_chosen);
    $cgi->param('prev_chosen',@prev_chosen);

    local $atoms = $att_template;
       $atoms =~ s/^(.*?)\|.*/$1/s;

    local $pretty_arg = $att_template;
    $pretty_arg =~ s/^.*?\| (.*?)\n.*/$1/s;  # extract the argument from att_template
    $pretty_arg =~ s/[\t\s]*$//g;            # remove any trailing spaces or tabs
    local $row_1_length = length("$atoms| $pretty_arg");

    local $dashes;
    for ($i=1;$i<=length($atoms);$i++) {
	$dashes .= "-";
    }
    $dashes .= "|";  # that's a vertical bar in case you are looking at this in xemacs and see it italicized
    for ($i=1;$i<=length($pretty_arg)+1;$i++) {
	$dashes .= "-";
    }

    $subtitle = "Exercise $POL::exercise Problem $POL::problem_num\n" if $POL::exercise;
    $instructions = "<center><strong><font color=$LEFTPAGECOLOR>Assign truth values to the atomic statements to make the compute <em>false</em></font></strong></center>\n"; # unless $answer;

    &start_polpage('Power of Logic: Assigning Truth Values') if not $flag;
    &pol_header($subtitle,$instructions) if not $flag;

    print
	$cgi->startform(-onsubmit=>"replaceCharsRev(document.getElementById('att'))");

    print #
	"<center>\n",
	"<table border=0>\n";
    
    $cols = $row_1_length+8;
    print # Only row contains the truth table in a textarea
	"<tr><td align=left>\n",
	"<script language=\"javascript\" type=\"text/javascript\" src=\"$JSDIR/replace.js\" charset=\"UTF-8\"></script>",
	"<textarea onSelect=\"\" onkeyup=\"process(this)\" id=\"att\" name=\"att\" rows=6 cols=$cols style=\"font-family: monospace\">",
	ascii2utf_html($att_template),
	"</textarea>",
	"</td></tr>\n";
    
    print # close TT table
	"</table>\n";

    print
	"<hr width=98%>";

    print
	$cgi->submit(-name=>'action',-value=>'Check'),"\n",
	$cgi->hidden(-name=>'argument',-value=>$arg),"\n",
	$cgi->hidden(-name=>'atoms',-value=>$atoms),"\n",
	$cgi->hidden(-name=>'pretty_arg',-value=>$pretty_arg),"\n",
	$cgi->hidden(-name=>'dashes',-value=>$dashes),"\n",
	$cgi->hidden(-name=>'exercise',-value=>$POL::exercise),"\n",
	$cgi->hidden('problem_num',@prev_chosen),"\n",
	$cgi->hidden('prev_chosen'),"\n",
	$cgi->hidden(-name=>'att_template',-value=>$att_template),"\n",
	$cgi->endform,"\n",
	"</center>\n";
    
    &footer();

    &bye_bye;
}


###########################################################
sub roll_yer_own_att {

    local $subtitle = 	"Create your own truth table",
    local $instructions = "<center><strong><font color=$LEFTPAGECOLOR>Enter an argument in the area below.<br>Click below to create an empty truth table for it.</font></strong></center>";

    &start_polpage;
    print
	$cgi->startform();

    &pol_header($subtitle,$instructions);

    print
	"<center>\n",
	"<p>",
	$cgi->textfield(-name=>'user_argument',
			-style=>'font-family: monospace',
			-size=>50,-default=>''),
	"<br>",
	$cgi->submit(-name=>'action',-value=>'Make the truth table!'),
	$cgi->endform,
	"</center>";

    &footer();

    &bye_bye();
}

#########################################################*
# This subroutine takes a user-created argument and ensures
# that all of its components are wffs, and then turns it 
# into problem file format and hands it to &tt_form.

sub process_user_argument {
    local $arg = $_[0];
    chomp($arg);
    local $probfile_arg;                # This will contain the user argument in prob file format

    $conclusion = $arg;                 
    $conclusion =~ s/ //g;              # remove spaces
    if (!&wff($conclusion)) {           # Check for WFFness of $conclusion
	print
	    $cgi->header(),
	    $cgi->start_html(-bgcolor=>$RIGHTPAGECOLOR);
#	&pol_template($head_ConclusionNotWff,&msg_ConclusionNotWff);
	&pol_template($conclusion,&msg_ConclusionNotWff);
	&bye_bye;
    }
    
    &tt_form($conclusion);
}


############################################################
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

