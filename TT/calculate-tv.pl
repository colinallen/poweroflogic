#!/usr/bin/perl -w

#####################################################################################
# Subroutine for calulating TV of a sentence on a given truth value assignment
# Takes a wff (no spaces, OUTER PARENS REQUIRED) and an array representing a TVA for 
# the atomic statements in the wff (and perhaps other atoms as well).


sub calculate_tv {
    $_ = shift;                          # Strip out the wff, put into $_ (@_ will now contain a tva...)
    local %local_tva;

    for ($n=0;$n<@_;$n=$n+2) {	         # Construct a tva hash out of the array
	$local_tva{$_[$n]} = $_[$n+1];
    }
    s/([A-Z])/$local_tva{$1}/g;	         # substitute the tv assigned to each atom for the atom in the wff

    while (/[.~\-v]/) {		         # Calculate til all connectives are gone
	&doitnow($_);
    }
#    s/\s//;                              # Make sure there aren't any extraneous spaces
    return $_;
}

# the TV calculation engine
sub doitnow {

#print "$_\n";
    shift;
#print "$_\n" if /~/;
    s/(.*?)~~(.*)/$1$2/g;  
    s/~T/F/g;
    s/~F/T/g;
#print "$_\n" if /\./;
    s/[\[\(]T\.T[\]\)]/T/g;
    s/[\[\(]T\.F[\]\)]/F/g;
    s/[\[\(]F\.T[\]\)]/F/g;
    s/[\[\(]F\.F[\]\)]/F/g;
#print "$_\n" if /v/;
    s/[\[\(]TvT[\]\)]/T/g;
    s/[\[\(]TvF[\]\)]/T/g;
    s/[\[\(]FvT[\]\)]/T/g;
    s/[\[\(]FvF[\]\)]/F/g;
#print "$_\n" if /[^<]->/;
    s/[\[\(]T->T[\]\)]/T/g;
    s/[\[\(]T->F[\]\)]/F/g;
    s/[\[\(]F->T[\]\)]/T/g;
    s/[\[\(]F->F[\]\)]/T/g;
#print "$_\n" if /<->/;
    s/[\[\(]T<->T[\]\)]/T/g;
    s/[\[\(]T<->F[\]\)]/F/g;
    s/[\[\(]F<->T[\]\)]/F/g;
    s/[\[\(]F<->F[\]\)]/T/g;
#print "$_\n";
}

'foo';
