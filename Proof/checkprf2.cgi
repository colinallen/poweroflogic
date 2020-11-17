#!/usr/bin/perl

# checkprf.cgi
# This script is designed to be called with a partial proof
# to allow user to complete.

# Version 1.0 by CA 9/26/98
# Version 0.9 by Colin Allen 9/13/98
# - integrated with menu.cgi
# - code still needs comments
# Version 0.4 by Colin Allen 9/11/98
# - working prototype now handles variety of partial proofs
# - no documentation yet
# Version 0.3 CA Sep 5 1998
#  - modified proof check box to conform to general style
# Version 0.2 Colin Allen Aug 18 1998
#  - modified to use CGI.pm
#  - quick hack for input only; cgi output still needs editing
# Version 0.1 used old cgi.pl library

# Library
use IPC::Open2;

require "../lib/header.pl";
require "./line-subrs.pl";
require "./prf-subrs.pl";
require "../lib/wff-subrs.pl";

$program = $cgi->url;
$checker = "./proof.pl";

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
$polmenu{"Help with proofs"} = "../help.cgi?helpfile=proofhelp.html";

$polmenu{"Example Proof"} = "$program?usrchc=Example&exercise=$POL::exercise"
    unless $POL::usrchc eq "Example";

if ($POL::exercise) { # add menu items
    my($chapter,$rest)=split(/\./,$POL::exercise,2);
    $polmenu{"More from Ch. $chapter"} = "../menu.cgi?chapter=$chapter";
    $polmenu{"More from Ex. $POL::exercise"} = "$program?exercise=$POL::exercise&prevchosenstring=$prevchosen_string"
	if $POL::prf;
}
#####################################################

$mailto = 'random';
#$mailto = 'nobody';

my $instruction = "Complete the proof at right";

chomp $POL::prf;

if (!$POL::prf && $POL::arg) {
    my ($prems,$conc) = split(/:\.|\.:/,$POL::arg);
    my $lineno = 0;
    foreach my $prem (split(/,/,$prems)) {
	&error_out("Premise $prem is not well formed")
	    unless &wff($prem);
	$POL::prf .= ++$lineno.".".$prem;
    }
    $POL::prf .= " :. $conc";
    &error_out("Conclusion '$conc' is not well formed")
	unless &wff($conc);

}

if ($POL::exercise && !$POL::prf && !$POL::usrchc) {
    &pickprf;
}

for ($POL::usrchc) {
    /Example/   and do { &example; last };
    /Another/   and do { &pickprf; last };
    /Begin/     and do { &begin; last };
    /Check/     and do { &check; last };
    &begin;
}

############################################################
sub begin {
    my $prf = $POL::prf;
    my ($proof,$ans) = &prftoproof($prf);

    my $title = "$POL::exercise Proof Checker";
    $title .= " Example" if $POL::usrchc =~ /Example/;

    &start_polpage;
    &pol_header("$title");
    &proofcheckform($proof,$ans);
    &pol_footer;
    &end_polpage;
}

###########################################################
sub proofcheckform {
    my ($proof,$answer,$border) = @_;
    $border = 0 unless defined $border;

    my $instruction = "Continue proof in the box at right"
	unless $answer;
    $instruction = "Enter proof in the box at right"
	if !$POL::exercise;

    print
	"<table border=\"$border\"><!-- proof table -->\n",
	$cgi->startform(),
	$cgi->hidden(-name=>'prf', -default=>$proof),
	$cgi->hidden('exercise'),
	$cgi->hidden('probnum'),
	$cgi->hidden('prevchosen'),
	;
    
    
    my $task = "Prove this";
    $task = "Annotate this" if $POL::annotate;
	
    print # next row if $proof
	Tr(td({-valign=>'top',
	       -align=>'right'},
	      strong($task),
	      "&nbsp;"),
	   td({-valign=>'top',
	       -align=>'left'},
	      "<pre>$proof</pre>"))
	    if ($proof);
    
    print # next row column 1
	"<tr>\n",
	"<td align=right valign=top>\n";

    print
	"<p>",
	"<center>",
	"<font color=\"$LEFTPAGECOLOR\"><strong>",
	"Use</font></strong> \$ <font color=\"$LEFTPAGECOLOR\"><strong>",
	"to represent&nbsp;<img src=\"$existential\"></font></strong>",
	"</center>"
	    if $proof =~ /[A-Z][w-z]/;

    print
	"<strong>$instruction</strong><br>\n",
	"\n<br>\n",
	$cgi->hidden(-name=>'annotate',-value=>$annotate),
	$cgi->submit(-name=>'usrchc',-value=>'Check Proof Now!'),
	"</td>\n";
    
    my $cols = &longest_line_length($POL::answer)+8;
    $cols = 55 if 55 > $cols;   # changed by cm -- area was too small; also rows lengthened to 20 from 15 below

    $cgi->delete('answer'); # prevent old value replacing new value
    print # column 2 proof text area
	"<td align=left>\n",
	"<textarea name=\"answer\" rows=20 cols=$cols style=\"font-family: monospace\">",
	$answer,
	"</textarea>",
	"\n</td></tr>\n";

    print # rule reminders
	Tr(td(" "),
	   td({-align=>'left'},
	      $cgi->popup_menu(-style=>"font-family: monospace",
			       -values=>[
					 'Rule Reminder List',
					 '------- Implicational Rules -------',
					 'MP: p->q, p :. q',
					 'MT: p->q, ~q :. ~p',
					 'DS: pvq, ~p :. q or pvq, ~q :. p',
					 'Simp: p.q :. p or p.q :. q',
					 'Conj: p, q :. (p.q)',
					 'HS: p->q, (q->r) :. (p->r)',
					 'Add: p :. pvq or p :. qvp',
					 'CD: pvq, p->r, q->s :. rvs',
					 '------- Proof Procedures -------',
					 'CP: Assume p; get q :. p -> q',
					 'RAA: Assume p (or ~p); get q.~q :. ~p (or p)',
					 '------- Equivalence Rules -------',
					 'DN: p :: ~~p',
					 'EX: (p.q)->r :: p->(q->r)',
					 'Com: p.q :: q.p or pvq :: qvp',
					 'Dist: p.(qvr) :: (p.q)v(p.r)',
					 'Dist: pv(q.r) :: (pvq).(pvr)',
					 'As: pv(qvr) :: (pvq)vr',
					 'As: p.(q.r) :: (p.q).r',
					 'Re: p :: p.p or p :: pvp',
					 'DeM: ~(p.q) :: ~pv~q or ~(pvq) :: ~p.~q',
					 'ME: p<->q :: (p->q).(q->p)',
					 'ME: p<->q :: (p.q)v(~p.~q)',
					 'Cont: p->q :: ~q->~p',
					 'MI: p->q :: ~p v q',
					 '------- Quantifier Rules -------',
					 'UI: (x)Fx :. Ft',
					 'EI: ($x)Fx :. Fy (restricted)',
					 'UG: Fy :. (x)Fx (restricted)',
					 'EG: Ft :. ($x)Fx',
					 'QN: ~($x)Fx :: (x)~Fx or ~(x)Fx :: ($x)~Fx',
					 '------- Identity Rules --------',
					 'LL: x=y, f(x) :. f(y)',
					 'ID: :. x=x',
					 'SM: x=y :. y=x',
					 ])));
    
    print # end tables and form
	"</table><!-- end proof table -->\n",
	$cgi->endform,
	;

}

############################################################
sub check {
    my ($proof,$answer) = &prftoproof($POL::prf);
    my $logstuff = $proof.$POL::answer. "\n\n$POL::prf\n-\n$POL::answer\n";

    # must run open 2 before any cgi output
    open2('RD','WR',$checker) || die "cannot open pipe";
    print WR $proof, $POL::answer;
    close(WR);

    while (<RD>) {
	push @output,$_;
	$logstuff.=$_;
    }
    close(RD);
    
    &start_polpage();
    &pol_header("Proof Checker Results");

    print
	"\n<table border=\"0\" align=\"center\"><!-- begin results table -->\n",
	"\n<tr>\n",
	"\n<td align=\"left\" valign=\"top\" colspan=2>\n";

    my $score=0;
    foreach (@output) {
	chomp;
	my $lop = 1 if /OK|\*\*/;
	s/ /&nbsp\;/g if $lop;
	s/&nbsp;\// \//g; # restore tags such as <br />
	s/OK/<img src="$greentick" border="0">/;
	s/\*\*/<img src="$redx" border="0">/;
	print "$_";
	$score=1 if /congrat/i;
    }
    

    if (!$score) {
	print
	    "\n<center>\n",
	    h3("Continue below..."),
	    "\n</center>\n";
	$answer = $POL::answer; # unless $answer; # kludge bug fix
	#print "answer is $answer"; # debug

	$answer =~ s/ |\t//g;
	my @answer = split(/\n/,$answer);

	$answer = '';
	$answer = shift @answer
	    if $answer[0] =~ /^(\.:|:\.)/; # putative theorem

	foreach my $lineofproof (@answer) {
	    chomp $lineofproof;
	    my $indent = &get_indent($lineofproof);
	    my $linenumber  = &get_linenum($lineofproof);
	    my $sentence    = &get_linesent($lineofproof);
	    my $annote  = &get_annotation($lineofproof);
	    $answer .= &pretty_line($indent,$linenumber,$sentence,$annote);
	}
	
	&proofcheckform($proof,$answer);
    } else {
	my $whence=" from Exercise $POL::exercise" if $POL::exercise;
	print
	    "\n<center>",
	    "\n<hr width=98%>",
	    $cgi->startform(),
	    $cgi->hidden('exercise'),
	    $cgi->hidden('prevchosen'),
	    $cgi->submit(-name=>'action',
			 -value=>"Another$whence?"),
	    $cgi->endform(),
	    "\n</center>\n";
    }
    print "</td></tr></table><!-- end results table -->\n";
    &pol_footer;
    &end_polpage;
}


############################################################
sub example {
    $POL::prf="1.P->~Q2.R->Q:.P->~R|3.PAssume|4.~Q1,3MP|5.~R2,4MT6.P->~R3,5CP";
    $cgi->delete('answer');
    &begin;
}
############################################################
sub pickprf {
    # set up
    my @problems;
    my ($chapter,$foo) = split(/\./,$POL::exercise,2);
    my $probfile = "$EXHOME$chapter/$POL::exercise";
    
    $cgi->delete('prf'); # delete any previous selection

    $probfile =~ s/\||\.\.//g; # close pipeline exploit; CA 9-17-2004
    open(FILE,$probfile) || &html_error("Could not open problem file $probfile");
    while (<FILE>) {
	$preamble .= $_ and next if /^\#!preamble/;
	next if /^\#|^\w*$/;
	chomp;
	push @problems, $_;
    }
    close(FILE);
    $preamble =~ s/\#!preamble//g;
    $annotate = 1 if $preamble =~ /Annotat/i;

    # html out

    &start_polpage();
    &pol_header("Exercise ".$POL::exercise . ": Proofs");

    my $instruction = "Pick an argument";
    $instruction = "Click the icon to work on this problem" if $#problems == 0;
    
    print
	table({-border=>0},
	      Tr(td({-align=>'left',-colspan=>2},
		    "<font color=\"$LEFTPAGECOLOR\">",
		    $preamble,
		    "<p>",
		    strong($instruction),
		    "</font>",
		    )),
	      Tr(td({-align=>'left',-valign=>'middle',-width=>15},
		    "<img src=\"$smallgreyPoLogo\">"),
		 td({-align=>'left',-valign=>'middle'},
		    "<font size=\"-2\">",
		    "= previously selected during this session",
		    "</font>")));

    print "\n<table width=\"100%\"><!-- begin selection table -->\n";

    my $left=1;
    my $count=0;
    my $program = $cgi->self_url;
    foreach $problem (@problems) {
	++$count;
	my @pp = &prftoproof($problem);
	my $button_image = $prevchosen{$count} ? $smallgreyPoLogo : $smallPoLogo;
	print "<tr>\n" if $left;
	print
	    td({-valign=>'top',-align=>'left',-bgcolor=>'white'},
	       $cgi->startform,
	       $cgi->hidden(-name=>'prf',-value=>$problem),
	       $cgi->hidden('prevchosen'),
	       $cgi->hidden(-name=>'exercise',-value=>$POL::exercise),
	       $cgi->hidden(-name=>'annotate',-value=>$annotate),
	       $cgi->hidden(-name=>'probnum',-value=>$count),
	       $cgi->image_button(-name=>'usrchc',-src=>$button_image),
	       $cgi->endform),

	    td({-valign=>'top',-align=>'left',-bgcolor=>$RIGHTPAGECOLOR},
	       "\n<font size=-1>\n",
	       strong("#$count"),
	       "</font>"),

	    td({-valign=>'top',-align=>'left',-width=>'40%'},
	       "<pre><font size=\"-1\">$pp[0]</font></pre>"),
	    ;
	print "\n</tr>\n" if !$left;
	$left = !$left; #toggle left to right
    }
    print "\n</table><!-- end selection table -->";

    &pol_footer;
    &end_polpage();
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
}

sub longest_line_length {
    my ($text) = @_;
    my  $this;
    my $longest = 0;
    while ($text) {
	($this,$text) = split(/\n/,$text,2);
	my $length = length($this);
	$longest = $length if $length > $longest;
    }
    return $longest;
}

# THIS IS THE COMMON FORMAT FOR ALL LINES OF PROOF
# Currently just a quick hack.  Can be improved considerably.
sub pretty_line {
    my ($ind,$num,$sent,$ann) = @_;
    return "" unless $ind.$num.$sent.$ann; # skip blank line
    $sent =~ s/\r//g; # quick fix for a bug in the splitter

    my ($result,$i,$packfactor);

    if ($sent =~ /(:\.|\.:)/) { # special handling for conclusion line
	my $therefore = $1;
	($sent,$ann) = split(/$therefore/,$sent);
	$ann = "$therefore $ann";
    } else { # regular line annotation
	my $nums = &get_ann_nums($ann);
	$nums =~ s/,/-/
	    if ($ann =~ /cp|raa/i and $nums =~ /^\d+,\d+$/);
	my $rule = &get_rule($ann);
	$ann = "$nums, $rule";
	$ann =~ s/^, //; # if no numbers!
    }

    my $annlength = length $ann;

    $result .= "$ind$num. ";
    $packfactor = length $result;
    $packfactor = 5 if 5 > $packfactor;
    $result = pack "A$packfactor", $result;
    $result .= "$sent ";
    $packfactor = length $result;
    $packfactor = 30 if 30 > $packfactor; # left justify annotation
#    $packfactor = 37-$annlength if 37-$annlength > $packfactor; # right justify
    $result = pack "A$packfactor", $result;
    $result .= $ann;
    $result .= "\n";
    return $result;
}

sub error_out {
    &start_polpage;
    &pol_header("$title");
    print
	"<center>",
	h3(@_[0]),
	"</center>",;
    &pol_footer;
    &end_polpage;
    exit;
}
