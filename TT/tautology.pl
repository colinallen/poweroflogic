#!/usr/bin/perl -w
# tautology.pl
# Chris Menzel
# The main function here, &tautology, reads in a wff (with our without
# parens) and determines whether or not it is a tautology.  It is used
# in particular by the predicate logic symbolization module for
# determining whether or not a user's attempted translation is
# logically equivalent to the canonical translation given in the
# problem file.

require "../TT/make-tt-template.pl";
require "../TT/calculate-tv.pl";
require "../lib/wff-subrs.pl";

#$wff = '([(Av[E.(F.(G.H))])v((Bv[E.(F.(G.H))])v((Cv[E.(F.(G.H))])v(Dv[E.(F.(G.H))])))].[Ev(Fv(GvH))])';

# This one is a tautology
#$wff = '(~[(Av[E.(F.(G.H))])v((Bv[E.(F.(G.H))])v((Cv[E.(F.(G.H))])v(Dv[E.(F.(G.H))])))]<->[(~A.[~Ev(~Fv(~Gv~H))]).((~B.[~Ev(~Fv(~Gv~H))]).((~C.[~Ev(~Fv(~Gv~H))]).(~D.[~Ev(~Fv(~Gv~H))])))])';

#$wff = '(([(A->I).((B->J).((C->K).((D->L).((E->M).((F->N).((G->O).(H->P)))))))]->[(I.Q)v((J.R)v((K.S)v((L.T)v((M.U)v((N.V)v((O.W)v(P.X)))))))])<->([(A->I).((B->J).((C->K).((D->L).((E->M).((F->N).((G->O).(H->P)))))))]->[(I.Q)v((J.R)v((K.S)v((L.T)v((M.U)v((N.V)v((O.W)v(P.X)))))))]))';

#print &tautology($wff),"\n";

#my $wf = '[~A->(A->B)]';
#my $wf = '[P->(P->Q)]';
#&tautology($wf);

###
sub tautology {

    local $wff = shift;
#    $wff =~ s/\s*//g;
    local $atoms = &get_atoms($wff);
    local $num_atoms = $atoms =~ tr/A-Z/A-Z/;
    local $num_rows = 2**$num_atoms;
    print "num_rows: $num_rows\n";

#    return "$wff is not a WFF!" if not &wff($wff);

    for ($i=0;$i<$num_rows;$i++) {
	my $ith_tva = "";
	my $ats = $atoms;

	my $tvs = &make_tv_string($i,$num_rows);
	$tvs =~ tr/01/TF/;
#        print "\$tvs: $tvs\n";

	while ($ats) {
	    $ith_tva = chop($ats) . chop($tvs) . " " . $ith_tva;
	}
	chop $ith_tva;
#	print "ith_tva_$i: $ith_tva\n";
	$ith_tva =~ s/(\w)(\w)/$1 $2/g;	# put spaces between atoms and tv's, e.g., "A T B F C T"
	@ith_tva = split(/ /,$ith_tva);
	local $ith_wff_tv = &calculate_tv($wff,@ith_tva);
#	print "$i\_th_wff_tv: $ith_wff_tv\n";
	return 0
	    if $ith_wff_tv eq "F";
    }
#    print "It's a tautology!";
    return 1;
}

###
sub get_atoms {
    my $atoms = shift;
    $atoms =~ s/[^A-Z]//g;
    while ($atoms =~ /(.).*\1/)         # remove duplicates
	{$atoms =~ s/(.)(.*)\1/$1$2/g;}
    return $atoms;
}

###
sub make_tv_string {
    my $str = unpack("B32", pack("N", shift));
    my $numrows = shift;
    my $del = 32-$numrows;
    $str =~ s/^0{$del}(.*)/$1/;
    return $str;
}
