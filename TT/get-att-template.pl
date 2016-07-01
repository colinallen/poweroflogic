#!/usr/bin/perl -w

use CGI  qw(:standard :html3);

require "make-tt-template.pl";

$template_arg = param('arg');
$template_arg =~ s/\s*//g;

my $template = &make_att_template($template_arg);
$template =~ s/</&lt;/g;
$template =~ s/>/&gt;/g;

print
  header(),
  start_html(-title=>"Abbreviated Truth Table Template for $template_arg"),
  "\n<pre>\n",
  $template,
  "\n</pre>\n",
  end_html;
