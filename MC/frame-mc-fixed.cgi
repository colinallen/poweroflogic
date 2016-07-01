#!/usr/bin/perl -w
##
## mc_quiz.cgi
## By Chris Menzel, based loosely on some earlier code by me and Colin Allen
## ver 0.1, 15 Sept 98
##   Currently still pretty messy...

use CGI qw(:standard :html3);
require '/www/poweroflogic/cgi/lib/header.pl';

$cgi = new CGI;
$cgi->import_names('BR');
$IP = $cgi->url;
$IP =~ s/http:\/\/(.*?)\/.*/$1/;

srand; #seed random
$qsep = "-:-";
$sep = "::";

$debug=0;
$probfile = $BR::probfile;

for ($BR::action) {
    
    /Main/ and do { 
	print $cgi->redirect(-uri=>'http://$IP/cgi-pol/menu.cgi');
	last;
    };
    /Return/ and do { 
	print $cgi->redirect(-uri=>"http://$IP/cgi-pol/menu.cgi?chapter=7");
	last;
    };
    /Check/ and do { (&check_answers and &bye_bye) };
    &generate_quiz($probfile);
}
    
&bye_bye;

########################################################################
# subroutine to pick random selection of questions from a problem file ...
# and (with the help of (answer_form) generate an appropriate quiz 

sub generate_quiz {
    $probfile = $_[0];
    $section = $probfile;
    $section =~ s/^.*(\d+\.\d+)[A-Z]/$1/;
    $part = $probfile;
    $part =~ s/^.*\d+\.\d+([A-Z])/$1/;

    my @prevchosen = @BR::prevchosen;

    $qtype;
    $values;
    $qtype_marker = "\#!qtype";
    $preamble_marker = "\#!preamble";
    $preamble;
    my $numqs = 5;

    # Determine the number of questions in the quiz file

    open(PROBFILE,$probfile);
    
    while(<PROBFILE>){
	chop;
	($foo,$qtype) = split(/ /,$_,2) and next if /$qtype_marker/;  #get $qtype and continue
	($foo,$values) = split(/ /,$_,2) and next if /values/;
	($preamble .= $_) and next if /$preamble_marker/;
	next if /\#/;
	next if $_ eq "";
	push @questions, $_;                     # Push each line in $probfile onto @questions
    }

    $values =~ s/\s+$//;
    $values =~ s/\s+/ /;

    close PROBFILE;
    $cgi->param('qtype',$qtype);
    
    $numqs=@questions if @questions<$numqs;
    my $plural = "s" if $numqs > 1;
    
    $preamble =~ s/\#!preamble//g;

### The following chunk of code generates a random list of quiz questions w/o duplicates
### It also checks that no previously chosen questions show up in later rounds


    if (@BR::prevchosen >= @questions) {           # If user has already been quizzed on all 
#	$cgi->param('prevchosen','');              # of the questions, make prevchosen nil;
	$cgi->delete('prevchosen');
    }

    @prevchosen = $cgi->param('prevchosen');   # find out what nums have already been used

    my @selected;  # Variable to store random indices for selecting quiz questions
    $i=0;
    QUIZNUMS: while ($i<$numqs) {         
	                                  
	$j=int(rand @questions);          
	for ($n=0;$n<$i;$n++) {           
	    if ($j==$selected[$n]) {
		next QUIZNUMS;
	    }
	}
	if (@questions<=@selected+@prevchosen) {   # Check that we've got enough problems in the 
	    @selected=(@selected,$j);              # problem file to avoid repeats from previous 
                                                   # rounds, and if not,
	    $i++;                                  # just tack $j onto @selected directly ...
	    next QUIZNUMS;                         # and find the next number to put in @selected
	}
	for (@prevchosen) {        # If there are enough problems in the problem file,
	    if ($j==$_) {           # check to see if $j is equal to one of the nums in @prevchosen.
		next QUIZNUMS;      # If so, try another number...
	    }
	}
	@selected=(@selected,$j);   # If not, then $j isn't a repeat, so tack it onto @selected ...
	$i++;                       # and increment $i.
    }
    push @prevchosen, @selected;

    $cgi->param('prevchosen',@prevchosen);
    $j=0;
#    $rlqz="";

### Print out the form ###

    local $subtitle = "Problems for Section $section, Part $part";
    local $instructions = "";
    local $tablewidth = 450;

    print 
	$cgi->header(),
	$cgi->start_html(-title=>Quiz, -bgcolor=>'#aaccff');

    &pol_header($subtitle,$instructions,$tablewidth);  # create outer table, print the PoL header

    print
	$cgi->startform();

### Generate the quiz

    print
	"<table border=0>\n",
	"<tr><td align=left>\n",
	 $preamble,
	"</td></tr>\n",
	"</table>\n";

    print
	"<table border=0>\n";

    for(@selected){
	$j++;
	$rlqz="$rlqz$questions[$_]$qsep";
	($ques,$err,$ans)=split($sep,$questions[$_],3);
	$qnum=$j;
	$rlqz =~ s/ /+/g;
	&answer_form;
    }

    print 
	"</table>\n";

    print
	"<hr width=98%>\n",
	"<center>",
	$cgi->submit(-name=>'action',-value=>'Check answers!'),
	$cgi->hidden('quiz',$quiz),
	$cgi->hidden('qtype',$qtype),
	$cgi->hidden('rlqz',$rlqz),
	$cgi->hidden('prevchosen',@prevchosen),
	$cgi->hidden('section',$section),
	$cgi->hidden('part',$part),
	$cgi->hidden('probfile',$probfile),
	$cgi->end_form,
	$short_pol_footer;

    &bye_bye;
}


########################################################
# subroutine to generate each line of the quiz displayed
sub answer_form {

    my @values = split($sep,$values);
    push(@values,'?');
    
    print 
	"<tr><td align=left>\n",
	$cgi->popup_menu(-name=>"ans_$qnum",
			 -values=>\@values,
			 -size=>1,
			 -default=>'?'),
	"</td>\n",
	"<td align=left>\n",
	"$qnum.&nbsp;&nbsp;$ques</td>\n",
	"</tr>\n";
}


########################################################################
# subroutine to check answers

sub check_answers {
    local $i=0;
    my $rlqz = $BR::rlqz;
    local $nextq;
    local $subtitle = "Evaluation of your answers from Section&nbsp;$BR::section, Part&nbsp;$BR::part";
    local $instructions = "";
    local $tablewidth = 450;
    
### Print out PoL logo and header

    print 
	header(),
	$cgi->start_html(-title=>'Evaluation of your Quiz', -bgcolor=>'#aaccff'),
	startform();

    &pol_header($subtitle,$instructions,$tablewidth);

    print
	"<table>\n",  # put it all inside a one-cell table
	"<tr><td align=left>\n",
	h2("The Logic Tutor responds:"), 
	"<dl>\n";

    while ($rlqz) {
	$i++;                                            # question number
	($nextq,$rlqz) = split($qsep,$rlqz,2);           # put first ques in $rlqz in $nextq
	my ($ques,$errmsg,$ans) = split($sep,$nextq,3);  # split $nextq into 3 parts
	my $guess = $cgi->param("ans_$i");               # user guess
#	my $guess = $BR::$ans."_".$i;
	$ques =~ s/\+/ /g;                               # replace +'s with spaces in $ques
	my $rawguess = $guess;

	$ans =~ s/[+\s]//g;
	$guess =~ s/[+\s]//g;
	
	print "<dt>$i. $ques</dt>\n";

	if ($guess eq "?") {
	    print "<dd><img src=$qmark>&nbsp;<em>You did not answer this question.</em></dd><p>";
	} elsif ($guess eq $ans) {
	    print
		"<dd>",
		"<img src=$greentick>&nbsp;",
		"<em>Your answer of </em>``$rawguess\'\'<em> is correct!</em></dd><p>";
	    $currscore++;
	} else {
	    $errmsg =~ s/\+/ /g;
	    print 
		"<dd>",
		"<img src=$redx>&nbsp;",
		"<em>Your answer of </em>``$rawguess\'\'<em> is incorrect.</em></dd><p>";
	    if (0 && $errmsg) {
		print
		    "<font size=-1><em>Explanation:  $errmsg</em></font><p>";
	    }
	}
    }
    print
	"</dl>\n",
	"</td></tr>\n",
	"</table>\n";

    print
	"<hr width=98%>\n",
	"<center>",
	$cgi->hidden(-name=>'probfile', -value=>$BR::probfile),
	$cgi->startform,
	$cgi->submit(-name=>'action', -value=>"More problems from Section $BR::section$BR::part?"),
	"&nbsp;&nbsp;",
	$cgi->submit(-name=>'action',-value=>"Return to Chapter 7 menu"),
	$cgi->hidden(-name=>'prevchosen',-value=>@BR::prevchosen),
	$cgi->endform,
	"</center>\n";

    print
	$short_pol_footer;

    &bye_bye;
}
