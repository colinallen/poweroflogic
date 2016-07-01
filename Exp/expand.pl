#!/usr/bin/perl -w
# JM - I can't tell that this file is being used anywhere - seems to be replaces by exp.pl
# att.cgi
# 

# Version 0.1

# Library

require "../lib/header.pl";
#require "evaluate-exp.pl";
require "../Exp/make-exp-template.pl";
#require "check-validity.pl";
require "../lib/wff-subrs.pl";

$stand_alone = 1;

if ($stand_alone) {
#    use CGI qw(:standard :html3);
#    use IPC::Open2;
#    $cgi = new CGI;
#    $cgi->import_names('EXP');

    local $pred_arg = "[(x)Fx->(x)Gx]. ~(GavBa) :. ~Fa";
    local @scheme = qw(A Fa B Ga C Ba);
    &exp_form($pred_arg,@scheme);
}

###########################################################
# Takes as input either the argument from a problem file
# or an argument created by the user.

sub exp_form {
    my ($pred_arg,@scheme) = @_;
    $pred_arg =~ tr/[]/()/;

    $atoms = &extract_atoms(&pred2prop($pred_arg,@scheme));
    my $atomic_wffs = &prop2pred($atoms,@scheme);
    $atomic_wffs =~ s/([a-uw-z])([A-Z])/$1 $2/g;

    my $exp_template = &make_exp_template($pred_arg,$atomic_wffs);
    print "\n", "exp_template: \n$exp_template\n" if $stand_alone;

    print
	$cgi->startform(-onsubmit=>"replaceCharsRev(document.getElementById('exp_att'))");

    local $pretty_pred_arg = $exp_template;

    print "pretty_pred_arg: $pretty_pred_arg<br>";

    $pretty_pred_arg =~ s/^.*?\| (.*?)\n.*/$1/s;  # extract the argument from att_template

    print "pretty_pred_arg: $pretty_pred_arg<br>";

    $pretty_pred_arg =~ s/[\t\s]*$//g;            # remove any trailing spaces or tabs

    $pretty_prop_arg = &pred2prop($pretty_pred_arg,@scheme);

    local $row_1_length = length("$atomic_wffs| $pretty_pred_arg");

    local $dashes = $exp_template;
    $dashes =~ s/^.*?\| .*?\n(.*?)\n.*/$1/s;  

    print "pretty_pred_arg: $pretty_pred_arg<br>pretty_prop_arg: $pretty_prop_arg<br>row_1_length: $row_1_length<br>";

    print # begin a one column, two row table to contain atoms, argument, and text area for tva rows and answers
	"<center>\n",
	"<table border=0>\n";

    print # Only row contains the truth table in a textarea
	"<tr><td align=left>\n",
	"<script language=\"javascript\" type=\"text/javascript\" src=\"/4e/javascript/replace.js\" charset=\"UTF-8\"></script>",
	"<textarea onSelect=\"\" onkeyup=\"process(this)\" id=\"exp_att\" name=\"exp_att\" rows=6 cols=".($row_1_length+2)." style=\"font-family: monospace\">",
	ascii2utf_html($exp_template),
	"</textarea>",
	"</td></tr>\n";
    
    print # close TT table
	"</table>\n";

    print
	"<hr width=98%>";

    print # submit button, some hidden params
#	$cgi->submit(-name=>'usrchc',-value=>'Valid'),"\n",
	$cgi->submit(-name=>'usrchc',-value=>'Evaluate truth table!'),"\n",
	$cgi->hidden(-name=>'atoms',-value=>$atoms),"\n",
	$cgi->hidden(-name=>'scheme',-default=>[@scheme]),"\n",
	$cgi->hidden(-name=>'pretty_prop_arg',-value=>$pretty_prop_arg),"\n",
	$cgi->hidden(-name=>'pretty_pred_arg',-value=>$pretty_pred_arg),"\n",
	$cgi->hidden(-name=>'dashes',-value=>$dashes),"\n",
	$cgi->hidden(-name=>'exercise',-value=>$EXP::exercise),"\n",
	$cgi->hidden(-name=>'problem_num',-value=>$EXP::problem_num),"\n",
	$cgi->hidden(-name=>'exp_template',-value=>$exp_template),"\n",
	$cgi->endform,"\n",
	"</center>\n";
}

###
sub prop2pred {
    my ($prop_arg,%scheme) = @_;
    my $pred_arg = $prop_arg;

    return $scheme{$prop_arg} if length($prop_arg) == 1;


    for (keys(%scheme)) {
	$pred_arg =~ s/$_([^a-uw-z])/$scheme{$_}$1/g;
    }
    return $pred_arg;
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

###
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

sub pred2prop {
    my ($arg,@scheme) = @_;
    my $i;
    for ($i=0;$i<@scheme;$i=$i+2) {
	$arg =~ s/$scheme[$i+1]/$scheme[$i]/g;
    }
    return $arg;
}

1;
