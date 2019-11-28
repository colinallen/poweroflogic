#!/usr/bin/perl

# taut.cgi
#   Code for using TT's to determine whether a given sentence 
#   is tautologous, contradictory, or contingent.  Cloned from tt.cgi.

# Version 0.1

# Library
use IPC::Open2;
require "../lib/header.pl";
require "evaluate-taut.pl";
require "make-tt-template.pl",
require "check-taut.pl";
require "extract_nth_subwff.pl";
require "pol-template.pl";
require "messages.pl";
require "../lib/wff-subrs.pl";


$debug=0;
$nomail=0;
$program = $cgi->url;

@prev_chosen = @POL::prev_chosen if @POL::prev_chosen;
shift @prev_chosen if (@prev_chosen and !@prev_chosen[0]); # get rid of that damn empty first element

####################################################
# ADD LOCAL MENU ITEMS HERE
# $polmenu{"Main Menu"} = "../menu.cgi";

if ($POL::exercise) { # add menu items
    my($chapter,$rest)=split(/\./,$POL::exercise,2);
    if ($POL::action !~ /New/) {
        $prev_chosen_string = '&prev_chosen='.join('&prev_chosen=',@prev_chosen);
        $polmenu{"More from Ex. $POL::exercise"} = "$program?exercise=$POL::exercise&action=New$prev_chosen_string";
    }
    $polmenu{"More from Ch. $chapter"} = "../menu.cgi?chapter=$chapter";
}
#####################################################

#$EXHOME = '../../docs/ProbSets/Ch';

for ($POL::action) {
    /Choose|Another|New/    and do { &pickwff; last };
    /Problem/        and do { &tt_form($POL::wff); last };
    /Make/           and do { &process_user_argument($POL::user_argument); last };
    /Check/          and do { &evaluate_taut_tt; last };
    /Taut|Cont/      and do { &check_taut($POL::action); last};
    /Return/         and do { 
	print $cgi->redirect(-uri=>"../menu.cgi?chapter=7");
	last;
    };
    &roll_yer_own_tt; 
}

&bye_bye();

############################################################
sub pickwff {
    my @problems;
    my ($chapter) = split(/\./,$POL::exercise,2);
    my $probfile = "$EXHOME$chapter/$POL::exercise";
#    my$probfile = $POL::probfile;
    my $subtitle = "Exercise $POL::exercise: Tautologies, Contradictions, and Contingent Statements";
#    my $instructions = "Pick an argument to work on!";
    my $instructions = "";
    my $preamble = "";

    $cgi->delete('tt'); # delete any previous selection

    $probfile =~ s/\||\.\.//g; # close pipeline exploit; CA 9-17-2004
    open(FILE,$probfile) || &html_error("Could not open problem file $probfile");
    while (<FILE>) {
	$preamble .= $_ and next if /preamble/;
	next if /^\#|^\w*$/;
	chomp;
	push @problems, $_;
    }
    close(FILE);

    $preamble =~ s/\#!preamble//g;
    $instructions = $preamble;

    $instructions .= $PREVCHOICEINSTRUCTION # Note that $smallgreyPoLogo indicates previous selection
	if @POL::prev_chosen; 

    &start_polpage('Choose an argument');
    &pol_header($subtitle,$instructions);  # create outer table, print the PoL header and instructions

    print                                  # create a table containing all the problems in the exercise
	"<table border=0>\n";

#    print
#	"<tr><td colspan=2>",
#	$preamble,
#	"</td></tr>";

    my $count=0;
#    my $program = $cgi->self_url;  # why is this here?

    foreach $wff (@problems) {
	++$count;
	my $pretty_wff = ascii2utf(&prettify($wff));
	#$pretty_wff =~ s/[<]/&lt;/g;
	#$pretty_wff =~ s/[>]/&gt;/g;
	#$pretty_wff =~ s/(:\.)|(\.:)/<img align=bottom src=$therefore>/;

        my $logo = $smallPoLogo;
        $logo = $smallgreyPoLogo if (grep {$count == $_} @prev_chosen);

	print 
	    "<tr>\n",
	    "<td>\n";
	print  # print the submit button
	    $cgi->startform(),
          "<td valign=bottom align=right>",
          $cgi->hidden(-name=>'action', -value=>"Problem",-override=>1),
          $cgi->image_button(-name=>'void',
                             -src=>$logo),
          $cgi->hidden(-name=>'exercise',-value=>$POL::exercise),
          $cgi->hidden(-name=>'problem_num',-value=>$count),
#          $cgi->hidden(-name=>'prev_chosen',-value=>@prev_chosen),"\n",
          $cgi->hidden('prev_chosen'),"\n",
          $cgi->hidden(-name=>'wff',-value=>$wff),
          "</td>",
          $cgi->endform;
	
	print
          "<td valign=\"center\" align=\"left\" bgcolor=$RIGHTPAGECOLOR>",
          "$count. ",
          "</td>",
          "<td valign=center align=left>",
          "<tt>\n",
          "$pretty_wff",
          "</tt>\n",
          "</td>\n",
          "</tr>\n";
    }
    
    print
      "</table>\n";

    &footer();                       # close the outer table, print the footer message   

    &bye_bye();
}

###########################################################
# Takes as input either the argument from a problem file
# or an argument created by the user.

sub tt_form {

    local ($wff) = @_;  # presence of $tt will indicate that TT form will follow an error msg
    my $tt_template = &make_tt_template($wff);
    my $default_tt = $tt_template;
    $default_tt = $tt if $tt;
    $default_tt =  ascii2utf($default_tt);

    $border = 3 unless defined $border;

    push (@prev_chosen, $POL::problem_num) if $POL::problem_num;
    @prev_chosen = &remove_array_dups(@prev_chosen);
    $cgi->param('prev_chosen',@prev_chosen);

    $subtitle = "Exercise $POL::exercise Problem $POL::problem_num\n" if $POL::exercise;
    $instructions = "Complete the truth table!"; # unless $answer;

    local $atoms = $tt_template;
    $atoms =~ s/^(.*?)\|.*/$1/s;
    local $numatoms = $atoms =~ tr/A-Z/A-Z/;
    local $numrows = 2**$numatoms;
    local $pretty_wff = $tt_template;
    $pretty_wff =~ s/^.*?\| (.*?)\n.*/$1/s;  # extract the sequent from tt_template
    $pretty_wff =~ s/[\t\s]*$//;            # remove any trailing spaces or tabs

    #$pretty_wff =~ ascii2utf($pretty_wff);

    local $table_width = length("$atoms| $pretty_wff")+5;
    local $table_length = $numrows+3;

    local $dashes;
    for ($i=1;$i<=length($atoms);$i++) {
	$dashes .= "-";
    }
    $dashes .= "|";  # that's a vertical bar in case you are looking at this in xemacs and see it italicized
    for ($i=1;$i<=length($pretty_wff)+1;$i++) {
	$dashes .= "-";
    }

# $assigned_tvs is a string that looks like this: T T T|T T F|T F T| ...  used in evaluate_tt

    local $assigned_tvs = $tt_template;
    $assigned_tvs =~ s/(.*?\n){2}(.*)/$2/;

    &start_polpage('Power of Logic: Truth Table exercise') if not $tt;

    print
	"<script language=\"javascript\" type=\"text/javascript\" src=\"$JSDIR/replace.js\" charset=\"UTF-8\"></script>";

    &pol_header($subtitle,$instructions) if not $tt;
    $tt=$default_tt if not $tt;
    
    print # begin a one column, one row table to contain the truth table template
	"<center>\n",
	$cgi->startform(-onsubmit=>"replaceCharsRev(document.getElementById('tt'))"),
	"<table border=0>\n";

    print # Only row contains the truth table template in a textarea
	"<tr><td align=left>\n",
	"<textarea onSelect=\"\" onkeyup=\"process(this)\" id=\"tt\" name=\"tt\" default=\"$default_tt\" rows=\"$table_length\" cols=\"$table_width\"s style=\"font-family: monospace\">",
	$tt,
	"</textarea>",
	"</td></tr>\n";
    
    print # close TT table
	"</table>\n";

    print
	"<hr width=98%>";

    print # submit button, some hidden params
	$cgi->submit(-name=>'action',-value=>'Check Truth Table Now!'),"\n",
	$cgi->hidden(-name=>'original_wff',-value=>$wff),"\n",
	$cgi->hidden(-name=>'atoms',-value=>$atoms),"\n",
	$cgi->hidden(-name=>'pretty_wff',-value=>$pretty_wff),"\n",
	$cgi->hidden(-name=>'dashes',-value=>$dashes),"\n",
	$cgi->hidden(-name=>'assigned_tvs',-value=>$assigned_tvs),"\n",
	$cgi->hidden(-name=>'exercise',-value=>$POL::exercise),"\n",
	$cgi->hidden(-name=>'problem_num',-value=>$POL::problem_num),"\n",
	$cgi->hidden('prev_chosen'),"\n",
	$cgi->endform,"\n",
	"</center>\n";
    
    &footer();

    &bye_bye();
}

###
sub prettify_argument {
    $arg = $_[0];
    $arg =~ s/([^:])\. /$1\+ /g;
    $arg =~ s/([^:])([\.v]|->|<->)([^:])/$1 $2 $3/g;  # add spaces b/w binary connectives
#    $arg =~ s/\+/\./g;
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
    &bye_bye();
}


###########################################################
sub roll_yer_own_tt {

    local $subtitle = 	"Create your own truth table",
    local $instructions = "Enter an argument in the area below.<br>Click below to create an empty truth table for it.";

    &start_polpage('Power of Logic: Tautologies, Contradictions, Contingent Statements');
    
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

###########################################################
# This subroutine takes a user-created argument and ensures
# that all of its components are wffs, and then turns it 
# into problem file format and hands it to &tt_form.

sub process_user_argument {
    local $arg = $_[0];
    chomp($arg);
    local $probfile_arg;                # This will contain the user argument in prob file format

    if ($arg =~ /^\s*$/) {              # Case where nothing (except perhaps whitespace) is entered
	&start_polpage();
	&pol_template($head_NothingEntered,&msg_NothingEntered);
	&bye_bye();
    }

    if ($arg !~ /:\.|\.:/) {            # Case where no :. is entered
	&start_polpage();
	&pol_template($head_NoTherefore,&msg_NoTherefore);
	&bye_bye();
    }	

    $conclusion = $arg;                 
    $conclusion =~ s/^.*((:\.)|(\.:))\s*(.*)/$4/;  # Extract the purported conclusion 
    $conclusion =~ s/ //g;              # remove spaces

    if ($conclusion =~ /^\s*$/) {
	&start_polpage();
	&pol_template($head_NoConclusion,&msg_NoConclusion);
	&bye_bye();
    }

    if (!&wff($conclusion)) {           # Check for WFFness of $conclusion

	&start_polpage();
	&pol_template($head_ConclusionNotWff,&msg_ConclusionNotWff);
	&bye_bye();
    }

    $arg =~ s/((:\.)|(\.:)).*//g;       # remove :. or .: and conclusion
    $arg =~ s/([^\s])[\.,;] /$1 /g;     # remove periods etc being used as premise delimiters
    $arg =~ s/\s*//g;                     # remove spaces
    $probfile_arg = ":. $conclusion" if $arg eq "";

    while ($arg) {                      # got to find the formulas cuz might not be any delimiters
	local $wff = $arg;
	until (&wff($wff) or !$wff) {
	    chop $wff;
	}
	if (!$wff) {
	    &start_polpage;
	    &pol_template($head_PremiseNotWff,&msg_PremiseNotWff);
	    &bye_bye();
	}
	$esc_wff = $wff;
	$esc_wff =~ s/\(/\\\(/g;          # got to escape the parens and brackets in $wff...
	$esc_wff =~ s/\)/\\\)/g;
	$esc_wff =~ s/\[/\\\[/g;
	$esc_wff =~ s/\]/\\\]/g;
	$arg =~ s/$esc_wff//;             # ...in order to use it as a substitution pattern
	$probfile_arg .= "$wff. " and next if $arg;
	$probfile_arg .= "$wff :. $conclusion";	
    }
    &tt_form($probfile_arg);
}

