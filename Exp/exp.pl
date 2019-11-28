#!/usr/bin/perl -w

# exp.pl
# 

# Version 0.1

# Library

require "../lib/header.pl";
require "../Exp/make-exp-template.pl";
require "../lib/wff-subrs.pl";

###########################################################
# Takes as input either the argument from a problem file
# or an argument created by the user.

sub exp_form {
    my ($pred_arg,@scheme) = @_;
    $pred_arg =~ tr/[]/()/;
    
    # $pred_arg is sometimes a whole tt template
    # so here we strip out the atomic sentences and the
    # stuff after the sequent
    my @stuff = split("\n", $pred_arg);
    my $sequent = $stuff[0];
    $sequent =~ s/.*\|//;

    $atoms = &extract_atoms(&pred2prop($sequent,@scheme));

    my $atomic_wffs = &prop2pred($atoms,@scheme);

    $atomic_wffs =~ s/([a-uw-z])([A-Z])/$1 $2/g;
    my $exp_template = &make_exp_template($sequent,$atomic_wffs);

    print "\n", "exp_template: \n$exp_template\n" if $stand_alone;

    local $pretty_pred_arg = $exp_template;
    $pretty_pred_arg =~ s/^.*?\| (.*?)\n.*/$1/s;  # extract the argument from att_template
    $pretty_pred_arg =~ s/[\t\s]*$//g;            # remove any trailing spaces or tabs

    $pretty_prop_arg = &pred2prop($pretty_pred_arg,@scheme);

    local $row_1_length = length("$atomic_wffs| $pretty_pred_arg");

    local $dashes = $exp_template;
    $dashes =~ s/^.*?\| .*?\n(.*?)\n.*/$1/s;  

    print $cgi->startform(-onsubmit=>"replaceCharsRev(document.getElementById('exp_att'))");

    print # begin a one column, two row table to contain atoms, argument, and text area for tva rows and answers
	"<center>\n",
	"<table border=0>\n";

    print # Only row contains the truth table in a textarea
	"<tr><td align=left>\n",
	"<script language=\"javascript\" type=\"text/javascript\" src=\"/4e/javascript/replace.js\" charset=\"UTF-8\"></script>",
		"<textarea onSelect=\"\" onkeyup=\"process(this)\" id=\"exp_att\" name=\"exp_att\" rows=6 cols=".($row_1_length+10)." style=\"font-family: monospace\">",
	        ascii2utf_html($exp_template),
		"</textarea>",
	"</td></tr>\n";
    
    print # close TT table
	"</table>\n";

    print
	"<hr width=98%>";

    print # submit button, some hidden params
	$cgi->submit(-name=>'usrchc',-value=>'Evaluate truth table!'),"\n",
	$cgi->hidden(-name=>'atoms',-value=>$atoms),"\n",
	$cgi->hidden(-name=>'scheme',-default=>[@scheme]),"\n",
	$cgi->hidden(-name=>'pretty_prop_arg',-value=>$pretty_prop_arg),"\n",
	$cgi->hidden(-name=>'pretty_pred_arg',-value=>$pretty_pred_arg),"\n",
	$cgi->hidden(-name=>'dashes',-value=>$dashes),"\n",
	$cgi->hidden(-name=>'exercise',-value=>$POL::exercise, -override=>1),"\n",
	$cgi->hidden(-name=>'probnum',-value=>$POL::probnum),"\n",
	$cgi->hidden('prevchosen'),"\n",
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
