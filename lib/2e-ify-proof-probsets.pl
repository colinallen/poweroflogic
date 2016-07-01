#!/usr/bin/perl -w
# A little utility for stripping outer parens from 1st edition 
# problem sets for proofs to create problem sets that comport
# with 2nd edition format.
# Problems to be processed in general are of the following form:
#
# 1.PREM_12.PREM_2...n.PREM_n.:CONCn+1.WFF_1n_2.WFF_2...m.CONC
#
# For ordinary proof problems m=0; for annotation problems m>0.
# By CM, 13 Nov 01

require "wff-subrs.pl";

while (<>) {           #print preamble lines, comments, blank lines, and problem nums
    if (/^\#|^\s*$/) { 
        print;
        next
    }
    local @newarg;
    local $linenum = 1;
    my @lines;
    my ($prems,$conc_lines) = split(/:\.|\.:/, $_);

# Grab the premises
    my @prems = split(/\d+\./, $prems);
    shift @prems;     # pop off the empty first element
# Grab the conclusion
    my $conc = $conc_lines;
    $conc =~ s/^(.*?)(\d.*)$/$1/;
    chomp($conc);
# Grab the lines in the proof after the last premise, if there are any
    if ($2) {
        @lines = split(/\d+\./, $2);
        shift @lines;
    }

    &build_newarg(@prems);
    if (@prems) {
        push @newarg, ' :. '.&strip_outer_parens($conc);
    } else {  # case for theorems
        push @newarg, ':. '.&strip_outer_parens($conc)
    }
    &build_newarg(@lines) if @lines;
    print @newarg,"\n";
}
                                       
sub build_newarg {
    foreach $wff (@_) {
        push @newarg, $linenum.'.'.&strip_outer_parens($wff);
        ++$linenum;
    }
}
