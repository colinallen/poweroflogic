#! /usr/bin/perl -w

##########################################################################
# pol_template calls pol_header to generate a page with a message,       #
# usually an error or success message.  Currently called by              #
# evaluate-tt.pl, evaluate-att.pl, evaluate-taut.pl, evaluate-exp-att.pl #
# and check-validity.pl.                                                 #
#                                                                        #
# Chris Menzel, Oct 98                                                   #
#   * revised Feb 00 to use pol_header and pol_footer                    #
##########################################################################

###
sub pol_template {
    my ($head,$msg,$probref,$function) = @_;

    my $subtitle = "Exercise $probref";
    $subtitle = "Create your own truth table" unless $probref;
    
    my $instructions = "";  # This standard parameter for pol_header won't be used here
    &pol_header($subtitle,$instructions,450);

    print  # print the heading of the message
	"<center>",
	$head,
	"</center>";

    print  # print the message -- looks better (text not contiguous w/ table border) if put inside a one-cell table
      "<table width=100% border=0>\n",
      "<tr><td>\n",
      $msg,
      "<p>",
      "</td></tr>\n",
      "</table>";

    print
      "<p>",
      "<center>",
      "<b>Your truth table:</b>",
      "<p>",
#      "<table cellpadding=5 border=3>\n",
      "<table border=0>\n",
      "<tr><td>\n",
      "<pre>",
      ascii2utf_html($att),
#      $att,
      "</pre>",
      "</td></tr>\n",
      "</table>",
      "<hr>",
      $cgi->startform(),
      $cgi->hidden(-name=>'exercise',-value=>$POL::exercise),"\n",
      $cgi->hidden('prev_chosen',@prev_chosen),"\n",

      $cgi->submit(-name=>'action',-value=>"Choose more problems from Exercise $POL::exercise?"),
      $cgi->end_form,
      "</center>"
        if $function eq 'display';

    eval $function;  # Nothing happens if $function eq 'display', obviously...

    print  # close off the surrounding table
      "</td></tr>\n",
      "</table>\n",
      "</center>",
      ;


    &pol_footer;
}

1;
