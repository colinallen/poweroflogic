#!/usr/bin/perl -w
# make-tt-template.pl
# Chris Menzel 30 Sept 98
# Builds a truth table template from a sequent

###

sub send_tt_template {

    $template_arg = shift;

    print
      header(),
        start_html(-title=>"Truth Table Template for $template_arg"),
          "\n<pre>\n",
          &make_tt_template($template_arg),
            "\n</pre>\n",
              end_html;
    exit;

}

1;
