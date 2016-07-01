#!/usr/bin/perl

require "wff-subrs.pl";

while (<>) {
    if (/^\#/) {   #print preamble lines, comments, and problem nums
	print;
	next;
      }
    s/([^:])\. /$1 /g;  # remove periods between premises
    my ($prems,$conc) = split(/ :\. | \.: /,$_);
    my @prems = split(/ /,$prems);
    @newarg = map {&strip_outer_parens($_).', '} @prems;
    my $lastwff = pop @newarg;
    $lastwff =~ s/,//;
    push @newarg, $lastwff;
    push @newarg, ':. '.&strip_outer_parens($conc);
    print @newarg;
}
