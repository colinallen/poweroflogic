#!/usr/bin/perl 

# equiv-rules.pl
# Subroutines to support proofcheck.pl
# equivalence rules from chapter 8

# Version 0.1 Colin Allen Sep 24, 1998
# - first stab at equiv rules - DN and COM

#require "../lib/header.pl";
require "../Proof/errors";

# RULE SUBROUTINES EXPECT TO RECEIVE AN ARRAY
# WHOSE LAST ELEMENT IS A LINE NUMBER (THE LINE TO CHECK)
# AND THE OTHER ELEMENTS ARE THE LINES OF PROOF
# THEY RETURN A NULL STRING IF THE RULE IS CORRECTLY APPLIED
# OTHERWISE THEY RETURN A DIAGNOSTIC STRING


sub DN { # DOUBLE NEGATION
    my $lnum = pop(@_);               # actual line number
    my $i = $lnum-1;                  # proof array index
    my $conc = &add_outer_parens(&get_linesent($_[$i])); # conclusion at current line
    my $premnums = &get_ann_nums(&get_annotation($_[$i]));
    my $foo;

    
    # CHECK NUMBER OF PREMNUMS (E.G. MP = 2)
    $foo = $premnums =~ tr/,/,/ + 1; # count the commas
    return($WRONGNUM . "DN: exactly 1") if $foo != 1;

    @prems = &get_prems($premnums);

    # CHECK RULE PATTERN
    # DN IS (...~~X...) <=> (...X...)
    if (&DN_recursive($prems[0],$conc)) {
	return ""; # CORRECT
    } else {
	return($BADDN);
    }
}

sub DN_recursive {
    my ($wf1,$wf2) = @_;

    my $type1 = &iswff($wf1);
    my $type2 = &iswff($wf2);

    if ($type1 eq $type2) {
	if ($type1 =~ /atomic|identity/) {
	    return 0;
	} elsif ($type1 eq "negation") {
	    return &DN_recursive(substr($wf1,1,length($wf1)),
				 substr($wf2,1,length($wf2)));
	} elsif ($type1 =~ /universal|existential/) {
	    return 0 if &getvar($wf1) ne &getvar($wf2);
	    return &DN_recursive(&getscope($wf1),&getscope($wf2));
	} elsif ((&DN_recursive(&lhs($wf1),&lhs($wf2))
		  && &samewff(&rhs($wf1),&rhs($wf2)))
		 ||
		 (&DN_recursive(&rhs($wf1),&rhs($wf2))
		  && &samewff(&lhs($wf1),&lhs($wf2)))) {
	    return 1;
	}
    } else {
	return &samewff($wf1,"~~$wf2") || &samewff($wf2,"~~$wf1");
    }
}

sub COM { # Commutation
    my $lnum = pop(@_);               # actual line number
    my $i = $lnum-1;                  # proof array index
    my $conc = &add_outer_parens(&get_linesent($_[$i])); # conclusion at current line
    my $premnums = &get_ann_nums(&get_annotation($_[$i]));
    my $foo;

    
    # CHECK NUMBER OF PREMNUMS (E.G. MP = 2)
    $foo = $premnums =~ tr/,/,/ + 1; # count the commas
    return($WRONGNUM . "Com: exactly 1") if $foo != 1;

    @prems = &get_prems($premnums);

    # CHECK RULE PATTERN
    # DN IS (...(A.B)...) <=> (...(B.A)...)
    if (&COM_recursive($prems[0],$conc)) {
	return ""; # CORRECT
    } else {
	return($BADCOM);
    }
}

sub COM_recursive {
    my ($wf1,$wf2) = @_;

    my $type1 = &iswff($wf1);
    my $type2 = &iswff($wf2);

    if ($type1 ne $type2) {
	return 0;
    } elsif ($type1 =~ /atomic|identity/) {
	return 0;
    } elsif (&samewff(&lhs($wf1),&rhs($wf2))
	     && &samewff(&lhs($wf2),&rhs($wf1))
	     && ($type1 =~ /junction/)) {
	return 1;
    } elsif ($type1 eq "negation") {
	return &COM_recursive(substr($wf1,1,length($wf1)),
			      substr($wf2,1,length($wf2)));
    } elsif ($type1 =~ /universal|existential/) {
	return 0 if &getvar($wf1) ne &getvar($wf2);
	return &COM_recursive(&getscope($wf1),&getscope($wf2));
    } else {
	return ((&COM_recursive(&lhs($wf1),&lhs($wf2))
		 && &samewff(&rhs($wf1),&rhs($wf2)))
		||
		(&COM_recursive(rhs($wf1),rhs($wf2))
		 && &samewff(&lhs($wf1),&lhs($wf2))));
    }
}

sub CONT { # CONTRAPOSITION
    my $lnum = pop(@_);               # actual line number
    my $i = $lnum-1;                  # proof array index
    my $conc = &add_outer_parens(&get_linesent($_[$i])); # conclusion at current line
    my $premnums = &get_ann_nums(&get_annotation($_[$i]));
    my $foo;
    
    # CHECK NUMBER OF PREMNUMS (E.G. MP = 2)
    $foo = $premnums =~ tr/,/,/ + 1; # count the commas
    return($WRONGNUM . "CONT: exactly 1") if $foo != 1;

    @prems = &get_prems($premnums);

    # CHECK RULE PATTERN
    # CONT IS (X->Y) <=> (~Y->~X)
    if (&CONT_recursive($prems[0],$conc)) {
	return ""; # CORRECT
    } elsif (&CONT_recursive($conc,$prems[0])) {
	return ""; # CORRECT
    } else {
	return($BADCONT);
    }
}

sub CONT_recursive {

    my ($wf1,$wf2) = @_;

    my $type1 = &iswff($wf1);
    my $type2 = &iswff($wf2);

    if ($type1 eq $type2) {
	if ($type1 =~ /atomic|identity/) {
	    return 0;
	} elsif ($type1 eq "negation") {
	    return &CONT_recursive(substr($wf1,1,length($wf1)),
				   substr($wf2,1,length($wf2)));
	} elsif ($type1 =~ /universal|existential/) {
	    return 0 if &getvar($wf1) ne &getvar($wf2);
	    return &CONT_recursive(&getscope($wf1),&getscope($wf2));
	} elsif (($type1 eq "conditional") && ($type2 eq "conditional")) {
	    return 1
		if ((&samewff(&lhs($wf1),substr(&rhs($wf2),1,length(&rhs($wf2)))) &&
		     (&samewff(&rhs($wf1),substr(&lhs($wf2),1,length(&lhs($wf2)))))));
	    return
		((&CONT_recursive(&lhs($wf1),&lhs($wf2))
		  and &samewff(&rhs($wf1),&rhs($wf2)))
		 ||
		 (&samewff(&lhs($wf1),&lhs($wf2))
		  and &CONT_recursive(&rhs($wf1),&rhs($wf2))))
		    if ($type1 eq $type2);
	} else {
	    return
		((&CONT_recursive(&lhs($wf1),&lhs($wf2))
		  and &samewff(&rhs($wf1),&rhs($wf2)))
		 ||
		 (&samewff(&lhs($wf1),&lhs($wf2))
		  and &CONT_recursive(&rhs($wf1),&rhs($wf2))))
		    if ($type1 eq $type2);
	}
    }
}

sub MI { # MATERIAL IMPLICATION
    my $lnum = pop(@_);               # actual line number
    my $i = $lnum-1;                  # proof array index
    my $conc = &add_outer_parens(&get_linesent($_[$i])); # conclusion at current line
    my $premnums = &get_ann_nums(&get_annotation($_[$i]));
    my $foo;
    
    # CHECK NUMBER OF PREMNUMS (E.G. MP = 2)
    $foo = $premnums =~ tr/,/,/ + 1; # count the commas
    return($WRONGNUM . "MI: exactly 1") if $foo != 1;

    @prems = &get_prems($premnums);

    # CHECK RULE PATTERN
    # MI IS (X->Y) <=> (~XvY)
    if (&MI_recursive($prems[0],$conc)) {
	return ""; # CORRECT
    } else {
	return($BADMI);
    }
}

sub MI_recursive {
    my ($wf1,$wf2) = @_;
    my $type1 = &iswff($wf1);
    my $type2 = &iswff($wf2);

    if ($type1 =~ /atomic|identity/ || $type2 =~ /atomic|identity/) {
	return 0;
    } elsif ($type1 eq "negation" && $type2 eq "negation") {
	return &MI_recursive(substr($wf1,1,length($wf1)),
			     substr($wf2,1,length($wf2)));
    } elsif ($type1 =~ /universal|existential/ && $type2 =~ /universal|existential/ ) {
	return 0 if &getvar($wf1) ne &getvar($wf2);
	return &MI_recursive(&getscope($wf1),&getscope($wf2));
    } elsif ($type1 eq "conditional" && $type2 =~ /disjunction/) {
	return 1 if (&samewff((&lhs($wf2)),"~".&lhs($wf1)) &&
		     &samewff(&rhs($wf2),&rhs($wf1)));
    } elsif ($type1=~ /disjunction/ && $type2 eq "conditional") {
	return 1 if (&samewff((&lhs($wf1)),"~".&lhs($wf2)) &&
		     &samewff(&rhs($wf1),&rhs($wf2)));
    } else {
	return 0 if ($type1 ne $type2);
	return
	    ((&MI_recursive(&lhs($wf1),&lhs($wf2))
	      and &samewff(&rhs($wf1),&rhs($wf2)))
	     ||
	     (&samewff(&lhs($wf1),&lhs($wf2))
	      and &MI_recursive(&rhs($wf1),&rhs($wf2))));
    }
}

sub RE { # REDUNDANCY
    my $lnum = pop(@_);               # actual line number
    my $i = $lnum-1;                  # proof array index
    my $conc = &add_outer_parens(&get_linesent($_[$i])); # conclusion at current line
    my $premnums = &get_ann_nums(&get_annotation($_[$i]));
    my $foo;
    
    # CHECK NUMBER OF PREMNUMS (E.G. MP = 2)
    $foo = $premnums =~ tr/,/,/ + 1; # count the commas
    return($WRONGNUM . "RE: exactly 1") if $foo != 1;

    @prems = &get_prems($premnums);

    # CHECK RULE PATTERN
    # RE IS (X) <=> (X.X) OR 
    #       (X) <=> (XvX)
    if (&RE_recursive($prems[0],$conc)) {
	return ""; # CORRECT
    } else {
	return($BADRE);
    }
}

sub RE_recursive {
    my ($wf1,$wf2) = @_;
    my $type1 = &iswff($wf1);
    my $type2 = &iswff($wf2);
#    print "comparing $wf1 ($type1) and $wf2 ($type2)\n";
    if (($type1 =~ /junction/) ||($type2 =~ /junction/)) {
	return 1 if (((&samewff(($wf2),&rhs($wf1))) &&
		      (&samewff(($wf2),&lhs($wf1)))) ||
		     ((&samewff(($wf1),&rhs($wf2))) &&
		      (&samewff(($wf1),&lhs($wf2))))); 
        return
            ((&RE_recursive(&lhs($wf1),&lhs($wf2))
              and &samewff(&rhs($wf1),&rhs($wf2)))
             ||
             (&samewff(&lhs($wf1),&lhs($wf2))
              and &RE_recursive(&rhs($wf1),&rhs($wf2))));
    } elsif ($type1 =~ /negation/ && $type2 =~/negation/) {
	return &RE_recursive(substr($wf1,1,length($wf1)),
			     substr($wf2,1,length($wf2)));
    } elsif ($type1 =~ /universal|existential/ && $type1 eq $type2) {
	return 0 if &getvar($wf1) ne &getvar($wf2);
	return &RE_recursive(&getscope($wf1),&getscope($wf2));
    } else {
	return 0 if (($type1 ne $type2) || ($type1 =~ /atomic|identity/));
	return
	    ((&RE_recursive(&lhs($wf1),&lhs($wf2))
	      and &samewff(&rhs($wf1),&rhs($wf2)))
	     ||
	     (&samewff(&lhs($wf1),&lhs($wf2))
	      and &RE_recursive(&rhs($wf1),&rhs($wf2))));
    }    
}

sub ME { # MATERIAL EQUIVALENCE
    my $lnum = pop(@_);               # actual line number
    my $i = $lnum-1;                  # proof array index
    my $conc = &add_outer_parens(&get_linesent($_[$i])); # conclusion at current line
    my $premnums = &get_ann_nums(&get_annotation($_[$i]));
    my $foo;
    
    # CHECK NUMBER OF PREMNUMS (E.G. MP = 2)
    $foo = $premnums =~ tr/,/,/ + 1; # count the commas
    return($WRONGNUM . "ME: exactly 1") if $foo != 1;

    @prems = &get_prems($premnums);

    # CHECK RULE PATTERN
    # ME IS (X<->Y) <=> ((X->Y).(Y->X)) OR 
    #       (X<->Y) <=> ((X.Y)v(~X.~Y))
    if (&ME_recursive($prems[0],$conc)) {
	return ""; # CORRECT
    } else {
	return($BADME);
    }
}

sub ME_recursive {

    my ($wf1,$wf2) = @_;

    my $type1 = &iswff($wf1);
    my $type2 = &iswff($wf2);

    if ($type1 eq "biconditional" && $type2 eq "conjunction") {
	return 1 if ((&iswff(&lhs($wf2)) eq "conditional") &&
		     (&iswff(&rhs($wf2)) eq "conditional") &&
		     ((&samewff(&lhs($wf1), &lhs(&lhs($wf2)))) &&
		      (&samewff(&lhs($wf1), &rhs(&rhs($wf2)))) &&
		      (&samewff(&rhs($wf1), &rhs(&lhs($wf2)))) &&
		      (&samewff(&rhs($wf1), &lhs(&rhs($wf2))))));
    } elsif ($type1 eq "biconditional" && $type2 eq "disjunction") {
	return 1 if ((&iswff(&lhs($wf2)) eq "conjunction") &&
		     (&iswff(&rhs($wf2)) eq "conjunction") &&
		     ((&samewff(&lhs($wf1), &lhs(&lhs($wf2)))) &&
		      (&samewff(&rhs($wf1), &rhs(&lhs($wf2)))) &&
		      (&samewff("~".&lhs($wf1), &lhs(&rhs($wf2)))) &&    
		      (&samewff("~".&rhs($wf1), &rhs(&rhs($wf2))))));   
	} elsif ($type1 =~ /conjunction/ && $type2 =~ /biconditional/) {
	    return 1 if ((&iswff(&lhs($wf1)) eq "conditional") &&
			 (&iswff(&rhs($wf1)) eq "conditional") &&
			 ((&samewff(&lhs($wf2), &lhs(&lhs($wf1)))) &&
			  (&samewff(&lhs($wf2), &rhs(&rhs($wf1)))) &&
			  (&samewff(&rhs($wf2), &rhs(&lhs($wf1)))) &&
			  (&samewff(&rhs($wf2), &lhs(&rhs($wf1))))));
	} elsif ($type1 =~ /disjunction/ && $type2 =~ /biconditional/) {
	    return 1 if ((&iswff(&lhs($wf1)) eq "conjunction") &&
			 (&iswff(&rhs($wf1)) eq "conjunction") &&
			 ((&samewff(&lhs($wf2), &lhs(&lhs($wf1)))) &&
			  (&samewff(&rhs($wf2), &rhs(&lhs($wf1)))) &&
			  (&samewff("~".&lhs($wf2), &lhs(&rhs($wf1)))) &&  
			  (&samewff("~".&rhs($wf2), &rhs(&rhs($wf1)))))); 
	} elsif ($type1 =~ /negation/ && $type2 =~ /negation/) {
	    return &ME_recursive(substr($wf1,1,length($wf1)),
				 substr($wf2,1,length($wf2)));
	} elsif ($type1 =~ /universal|existential/  && $type2 =~ /universal|existential/) {
	    return 0 if &getvar($wf1) ne &getvar($wf2);
	    return &ME_recursive(&getscope($wf1),&getscope($wf2));
	} else {
	    return 0 if (($type1 ne $type2) || ($type1 =~ /atomic|identity/));
	    return
		((&ME_recursive(&lhs($wf1),&lhs($wf2))
		  and &samewff(&rhs($wf1),&rhs($wf2)))
		 ||
		 (&samewff(&lhs($wf1),&lhs($wf2))
		  and &ME_recursive(&rhs($wf1),&rhs($wf2))));
	}
}

sub EX { # EXPORTATION
    my $lnum = pop(@_);               # actual line number
    my $i = $lnum-1;                  # proof array index
    my $conc = &add_outer_parens(&get_linesent($_[$i])); # conclusion at current line
    my $premnums = &get_ann_nums(&get_annotation($_[$i]));
    my $foo;
    
    # CHECK NUMBER OF PREMNUMS (E.G. MP = 2)
    $foo = $premnums =~ tr/,/,/ + 1; # count the commas
    return($WRONGNUM . "EX: exactly 1") if $foo != 1;

    @prems = &get_prems($premnums);

    # CHECK RULE PATTERN
    # EX IS ((X.Y)->Z) <=> (X->(Y->Z))
    if (&EX_recursive($prems[0],$conc)) {
	return ""; # CORRECT
    } else {
	return($BADEX);
    }
}

sub EX_recursive {

    my ($wf1,$wf2) = @_;

    my $type1 = &iswff($wf1);
    my $type2 = &iswff($wf2);

    if (($type1 ne $type2) || ($type1 =~ /atomic|identity/)) {
	return 0;
    } elsif ($type1 eq "negation") {
	return &EX_recursive(substr($wf1,1,length($wf1)),
			       substr($wf2,1,length($wf2)));
    } elsif ($type1 =~ /universal|existential/) {
	return 0 if &getvar($wf1) ne &getvar($wf2);
	return &EX_recursive(&getscope($wf1),&getscope($wf2));
    } elsif ($type1 eq "conditional") {
	return 1 if ((&iswff(&lhs($wf1)) eq "conjunction") &&
		     (&iswff(&rhs($wf2)) eq "conditional") &&
		     (&samewff(&lhs(&lhs($wf1)), &lhs($wf2))) &&
		     (&samewff(&rhs(&lhs($wf1)), &lhs(&rhs($wf2)))));
	return 1 if ((&iswff(&rhs($wf1)) eq "conditional") &&
		     (&iswff(&lhs($wf2)) eq "conjunction") &&
		     (&samewff(&lhs(&lhs($wf2)), &lhs($wf1))) &&
		     (&samewff(&rhs(&lhs($wf2)), &lhs(&rhs($wf1)))));
	return
	    ((&EX_recursive(&lhs($wf1),&lhs($wf2))
	      and &samewff(&rhs($wf1),&rhs($wf2)))
	     ||
	     (&samewff(&lhs($wf1),&lhs($wf2))
	      and &EX_recursive(&rhs($wf1),&rhs($wf2))));
    } else {
	return
	    ((&EX_recursive(&lhs($wf1),&lhs($wf2))
	      and &samewff(&rhs($wf1),&rhs($wf2)))
	     ||
	     (&samewff(&lhs($wf1),&lhs($wf2))
	      and &EX_recursive(&rhs($wf1),&rhs($wf2))));
    }
}

sub AS { # ASSOCIATION
    my $lnum = pop(@_);               # actual line number
    my $i = $lnum-1;                  # proof array index
    my $conc = &add_outer_parens(&get_linesent($_[$i])); # conclusion at current line
    my $premnums = &get_ann_nums(&get_annotation($_[$i]));
    my $foo;
    
    # CHECK NUMBER OF PREMNUMS (E.G. MP = 2)
    $foo = $premnums =~ tr/,/,/ + 1; # count the commas
    return($WRONGNUM . "AS: exactly 1") if $foo != 1;

    @prems = &get_prems($premnums);

    # CHECK RULE PATTERN
    # AS IS ((XvY)vZ) <=> (Xv(YvZ)) or
    #       ((X.Y).Z) <=> (X.(Y.Z))
    if (&AS_recursive($prems[0],$conc)) {
	return ""; # CORRECT
    } else {
	return($BADAS);
    }
}

sub AS_recursive {
    my ($wf1,$wf2) = @_;
    my $type1 = &iswff($wf1);
    my $type2 = &iswff($wf2);

    # Added 31 March 2009
    # Check to prevent inferences like the following:
    # 1.   ~Zv(~X.~Y)               :. (~Zv~X)v~Y 
    # 2.   (~Zv~X)v~Y               1, as
    #
    # This check simply removes all parens from $wf1 and $wf2 and checks to make
    # sure that the resulting strings are identical.  Since paren placement should be
    # the only difference in a valid application of As, this should do the job.
    
    my $wf1_np = $wf1;
    my $wf2_np = $wf2;
    $wf1_np =~ s/[\(\)\[\]]//g; # remove parens from copy of $wf1
    $wf2_np =~ s/[\(\)\[\]]//g; # remove parens from copy of $wf2
    return 0 if $wf1_np ne $wf2_np;
    
    if ($type1 ne $type2) {
	return 0;
    } elsif ($type1 =~ /atom|identity/) {
	return 0;
    } elsif ($type1 eq "negation") {
	return &AS_recursive(substr($wf1,1,length($wf1)),
			     substr($wf2,1,length($wf2)));
    } elsif ($type1 =~ /universal|existential/) {
	return 0 if &getvar($wf1) ne &getvar($wf2);
	return &AS_recursive(&getscope($wf1),&getscope($wf2));
    } elsif ($type1 =~ /junction/) {
        return 1 if ((&samewff(&lhs($wf1),
			       &lhs(&lhs($wf2)))) &&
		     (&samewff(&lhs(&rhs($wf1)),
			       &rhs(&lhs($wf2))))  &&
		     (&samewff(&rhs(&rhs($wf1)),
			       &rhs($wf2))));
				 
	return 1 if ((&samewff(&rhs($wf1),
			       &rhs(&rhs($wf2)))) &&
		     (&samewff(&rhs(&lhs($wf1)),
			       &lhs(&rhs($wf2))))  &&
		     (&samewff(&lhs(&lhs($wf1)),
			       &lhs($wf2))));
	return 
	    ((&AS_recursive(&lhs($wf1),&lhs($wf2))
	      and &samewff(&rhs($wf1),&rhs($wf2)))
	     ||
	     (&samewff(&lhs($wf1),&lhs($wf2))
	      and &AS_recursive(&rhs($wf1),&rhs($wf2))));
    } elsif ($type1 eq $type2) {
	return 
	    ((&AS_recursive(&lhs($wf1),&lhs($wf2))
	      and &samewff(&rhs($wf1),&rhs($wf2)))
	     ||
	     (&samewff(&lhs($wf1),&lhs($wf2))
	      and &AS_recursive(&rhs($wf1),&rhs($wf2))));
    }
}

sub DIST { # DISTRIBUTION
    my $lnum = pop(@_);               # actual line number
    my $i = $lnum-1;                  # proof array index
    my $conc = &add_outer_parens(&get_linesent($_[$i])); # conclusion at current line
    my $premnums = &get_ann_nums(&get_annotation($_[$i]));
    my $foo;
    
    # CHECK NUMBER OF PREMNUMS (E.G. MP = 2)
    $foo = $premnums =~ tr/,/,/ + 1; # count the commas
    return($WRONGNUM . "DIST: exactly 1") if $foo != 1;

    @prems = &get_prems($premnums);

    # CHECK RULE PATTERN
    # DIST IS (X.(YvZ)) <=> ((X.Y)v(X.Z)) or
    #         (Xv(Y.Z)) <=> ((XvY).(XvZ))
    if (&DIST_recursive($prems[0],$conc)) {
	return ""; # CORRECT
    } else {
	return($BADDIST);
    }
}

sub DIST_recursive {

    my ($wf1,$wf2) = @_;

    my $type1 = &iswff($wf1);
    my $type2 = &iswff($wf2);

    if ($type1 =~ /atom|identity/ || $type2 =~ /atom|identity/) {
	return 0;
    } elsif ($type1 =~ /negation/ && $type2 =~ /negation/) {
	return &DIST_recursive(substr($wf1,1,length($wf1)),
			       substr($wf2,1,length($wf2)));
    } elsif ($type1 =~ /universal|existential/  && $type2 =~ /universal|existential/) {
	return 0 if &getvar($wf1) ne &getvar($wf2);
	return &DIST_recursive(&getscope($wf1),&getscope($wf2));
    } elsif ($type1 =~ /conjunction/ && $type2 =~ /disjunction/) {
	return 1 if ((&iswff(&rhs($wf1)) eq "disjunction") &&
		     (&iswff(&lhs($wf2)) eq "conjunction") &&
		     (&iswff(&rhs($wf2)) eq "conjunction") &&
		     (&samewff(&lhs($wf1), &lhs(&lhs($wf2)))) &&
		     (&samewff(&lhs($wf1), &lhs(&rhs($wf2)))) &&
		     (&samewff(&lhs(&rhs($wf1)), &rhs(&lhs($wf2)))) &&
		     (&samewff(&rhs(&rhs($wf1)), &rhs(&rhs($wf2)))));
	return 1 if ((&iswff(&lhs($wf1)) eq "disjunction") &&
		     (&iswff(&rhs($wf1)) eq "disjunction") &&
		     (&iswff(&rhs($wf2)) eq "conjunction") &&
		     (&samewff(&lhs($wf2), &lhs(&lhs($wf1)))) &&
		     (&samewff(&lhs($wf2), &lhs(&rhs($wf1)))) &&
		     (&samewff(&lhs(&rhs($wf2)), &rhs(&lhs($wf1)))) &&
		     (&samewff(&rhs(&rhs($wf2)), &rhs(&rhs($wf1)))));
    } elsif ($type1 =~ /disjunction/ && $type2 =~ /conjunction/) {
	return 1 if ((&iswff(&rhs($wf1)) eq "conjunction") &&
		     (&iswff(&lhs($wf2)) eq "disjunction") &&
		     (&iswff(&rhs($wf2)) eq "disjunction") &&
		     (&samewff(&lhs($wf1), &lhs(&lhs($wf2)))) &&
		     (&samewff(&lhs($wf1), &lhs(&rhs($wf2)))) &&
		     (&samewff(&lhs(&rhs($wf1)), &rhs(&lhs($wf2)))) &&
		     (&samewff(&rhs(&rhs($wf1)), &rhs(&rhs($wf2)))));
	return 1 if ((&iswff(&lhs($wf1)) eq "conjunction") &&
		     (&iswff(&rhs($wf1)) eq "conjunction") &&
		     (&iswff(&rhs($wf2)) eq "disjunction") &&
		     (&samewff(&lhs($wf2), &lhs(&lhs($wf1)))) &&
		     (&samewff(&lhs($wf2), &lhs(&rhs($wf1)))) &&
		     (&samewff(&lhs(&rhs($wf2)), &rhs(&lhs($wf1)))) &&
		     (&samewff(&rhs(&rhs($wf2)), &rhs(&rhs($wf1)))));
    } else  {
	return
	    ((&DIST_recursive(&lhs($wf1),&lhs($wf2))
	      and &samewff(&rhs($wf1),&rhs($wf2)))
	     ||
	     (&samewff(&lhs($wf1),&lhs($wf2))
	      and &DIST_recursive(&rhs($wf1),&rhs($wf2))))
		if ($type1 eq $type2);

	}
}


sub DEM { # DE MORGAN'S
    my $lnum = pop(@_);               # actual line number
    my $i = $lnum-1;                  # proof array index
    my $conc = &add_outer_parens(&get_linesent($_[$i])); # conclusion at current line
    my $premnums = &get_ann_nums(&get_annotation($_[$i]));
    my $foo;
    
    # CHECK NUMBER OF PREMNUMS (E.G. MP = 2)
    $foo = $premnums =~ tr/,/,/ + 1; # count the commas
    return($WRONGNUM . "DEM: exactly 1") if $foo != 1;

    @prems = &get_prems($premnums);

    # CHECK RULE PATTERN
    # DEM IS ~(X.Y) <=> (~Xv~Y) or
    #        ~(XvY) <=> (~X.~Y)
    if (&DEM_recursive($prems[0],$conc)) {
	return ""; # CORRECT
    } else {
	return($BADDEM);
    }
}

sub DEM_recursive {

    my ($wf1,$wf2) = @_;
    my $type1 = &iswff($wf1);
    my $type2 = &iswff($wf2);
    
    if ($type1 =~ /atom|identity/ || $type2 =~ /atom|identity/) {
	return 0;
    } elsif ($type1 =~ /universal|existential/  && $type2 =~ /universal|existential/) {
	return 0 if &getvar($wf1) ne &getvar($wf2);
	return &DEM_recursive(&getscope($wf1),&getscope($wf2));
    } elsif ($type1 =~ /negation/ && $type2 =~ /negation/) {
	return &DEM_recursive(substr($wf1,1,length($wf1)),
			      substr($wf2,1,length($wf2)));
    } elsif ($type1 =~ /negation/ && $type2 =~ /junction/) {
	return 1 if ((&iswff(substr($wf1,1,length($wf1))) eq "conjunction") &&
		     (&iswff($wf2) eq "disjunction") &&
		     (&samewff("~".&lhs(substr($wf1,1,length($wf1))), &lhs($wf2))) &&
		     (&samewff("~".&rhs(substr($wf1,1,length($wf1))), &rhs($wf2))));
	return 1 if ((&iswff(substr($wf1,1,length($wf1))) eq "disjunction") &&
		     (&iswff($wf2) eq "conjunction") &&
		     (&samewff("~".&lhs(substr($wf1,1,length($wf1))), &lhs($wf2))) &&
		     (&samewff("~".&rhs(substr($wf1,1,length($wf1))), &rhs($wf2))));
    } elsif ($type1 =~ /junction/ && $type2 =~ /negation/) {
	return 1 if ((&iswff(substr($wf2,1,length($wf2))) eq "conjunction") &&
		     (&iswff($wf1) eq "disjunction") &&
		     (&samewff("~".&lhs(substr($wf2,1,length($wf2))), &lhs($wf1))) &&
		     (&samewff("~".&rhs(substr($wf2,1,length($wf2))), &rhs($wf1))));
	return 1 if ((&iswff(substr($wf2,1,length($wf2))) eq "disjunction") &&
		     (&iswff($wf1) eq "conjunction") &&
		     (&samewff("~".&lhs(substr($wf2,1,length($wf2))), &lhs($wf1))) &&
		     (&samewff("~".&rhs(substr($wf2,1,length($wf2))), &rhs($wf1))));
    } else {
	return
	    ((&DEM_recursive(&lhs($wf1),&lhs($wf2))
	      and &samewff(&rhs($wf1),&rhs($wf2)))
	     ||
	     (&samewff(&lhs($wf1),&lhs($wf2))
	      and &DEM_recursive(&rhs($wf1),&rhs($wf2))))
		if ($type1 eq $type2);
    }
}
1; # required by require














































