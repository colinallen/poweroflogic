#!/usr/bin/perl
require 'wff-subrs.pl';
require 'qlwff-subrs.pl';
while (1) {
    print "Formula: ";
    my $form = <>;
    chomp $form;
    print &wff($form);
    print "\n";
}
