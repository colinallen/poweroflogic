#!/usr/bin/perl

# impl-rules.pl
# Subroutines to support proofcheck.pl
# This file contains implicational rules for chatper 8

# Originally called rules.pl - renamed Sep 24, 1998 by CA

# Version 0.41 CA Aug 18
#  - finished CP...needs to be debugged still
# Version 0.4 CA Aug 17
#  - removed too_high subroutine; this check is now done in main in proof.pl
#  - need to add code to CP to pop boxed lines off AVAILABLE_STACK
# Version 0.31 CA Aug 15
#  - MT added; created stub for CP
# Version 0.3 Colin Allen Jul 14 1998
#  - added the %implemented hash to provide better security for
#    rule evaluation
# Version 0.2 Colin Allen 07/07/98
#  - finished coding MP
#  - general routines for rule checking include:
#    too_high: checks to see if cited rule is before current line
#    conv_prem_ranges: converts "1-3" to "1,2,3"
#    get_prems: returns list of formulas from premise numbers string
# Version 0.1 Colin Allen 07/06/98
# Basic support for MP
#  - still need to add actual rule checking (antecedent, consequent, etc.)

# RULE SUBROUTINES EXPECT TO RECEIVE AN ARRAY
# WHOSE LAST ELEMENT IS A LINE NUMBER (THE LINE TO CHECK)
# AND THE OTHER ELEMENTS ARE THE LINES OF PROOF
# THEY RETURN A NULL STRING IF THE RULE IS CORRECTLY APPLIED
# OTHERWISE THEY RETURN A DIAGNOSTIC STRING

sub MP { # MODUS PONENS, THE KING OF RULES
    my $lnum = pop(@_);               # actual line number
    my $i = $lnum-1;                  # proof array index
    my $conc = &add_outer_parens(&get_linesent($_[$i])); # conclusion at current line
    my $premnums = &get_ann_nums(&get_annotation($_[$i]));
    my $foo;
    
    
    # CHECK NUMBER OF PREMNUMS (E.G. MP = 2)
    $foo = $premnums =~ tr/,/,/ + 1; # count the commas
    return($WRONGNUM . "MP: exactly 2") if $foo != 2;
    
    # CHECK THAT PREMS [AND CONC] HAVE CORRECT FORMS
    # MP MUST HAVE AT LEAST ONE CONDITIONAL
    @prems = &get_prems($premnums);

    return("MP $CONDREQD")
	if (&wff($prems[0]) ne "conditional") &&
	    (&wff($prems[1]) ne "conditional");

    # CHECK RULE PATTERN
    # MP IS LHS->RHS,LHS:.RHS
    if (((&wff($prems[0]) eq "conditional")
	 && &samewff( &lhs($prems[0]), $prems[1] )
	 && &samewff( &rhs($prems[0]), $conc ))
	||
	((&wff($prems[1]) eq "conditional")
	 && &samewff( &lhs($prems[1]), $prems[0] )
	 && &samewff( &rhs($prems[1]), $conc ))) {
	return "";   # ALL TESTS PASSED!!
    } elsif ((&wff($prems[0]) eq "conditional"
	      && &samewff( &lhs($prems[0]), $prems[1] )
	      && !&samewff( &rhs($prems[0]), $conc )
	      ||
	      (&wff($prems[1]) eq "conditional")
	      && &samewff( &lhs($prems[1]), $prems[0] )
	      && !&samewff( &rhs($prems[1]), $conc ))) {
	return($BADMP_CONSEQ);
    } elsif ((&wff($prems[0]) eq "conditional"
	      && !&samewff( &lhs($prems[0]), $prems[1] )
	      && &samewff( &rhs($prems[0]), $conc )
	      ||
	      (&wff($prems[1]) eq "conditional")
	      && !&samewff( &lhs($prems[1]), $prems[0] )
	      && &samewff( &rhs($prems[1]), $conc ))) {
	return($BADMP_ANTEC);
    } else {
	return($BADMP);
    }
}

sub MT { # MODUS TOLLENS
    my $lnum = pop(@_);               # actual line number
    my $i = $lnum-1;                  # proof array index
    my $conc = &add_outer_parens(&get_linesent($_[$i])); # conclusion at current line
    my $premnums = &get_ann_nums(&get_annotation($_[$i]));
    my $foo;

    # CHECK NUMBER OF PREMNUMS
    $foo = $premnums =~ tr/,/,/ + 1; # count the commas
    return($WRONGNUM . "MT: exactly 2") if $foo != 2;

    # CORRECT FORMS - ONE PREMISE MUST BE CONDITIONAL
    # THE OTHER A NEGATION
    @prems = &get_prems($premnums);
    return("MT $CONDREQD") if
	((&wff($prems[0]) ne "conditional") &&
	 (&wff($prems[1]) ne "conditional"));
    return("MT $NEGREQD") if
	((&wff($prems[0]) ne "negation") &&
	 (&wff($prems[1]) ne "negation"));

    # CHECK FOR PATTERN LHS->RHS,~RHS:.~LHS
    if ((&samewff("~".&rhs($prems[0]), $prems[1]) &&
	 &samewff("~".&lhs($prems[0]), $conc) )
	||
	(&samewff("~".&rhs($prems[1]), $prems[0]) &&
	 &samewff("~".&lhs($prems[1]), $conc))) {
	return "";   # ALL TESTS PASSED!!
    } else {
	return($BADMT);
    }
}

sub CP {
    my $lnum = pop(@_);               # actual line number
    my $i = $lnum-1;                  # proof array index
    my $conc = &add_outer_parens(&get_linesent($_[$i])); # conclusion at current line
    my $premnums = &get_ann_nums(&get_annotation($_[$i]));

    my $saveprems = $premnums;

    # CHECK NUMBER OF PREMNUMS
    my $foo = $premnums =~ tr/,/,/ + 1; # count the commas
    return($WRONGCPSPAN) if $foo != 2;

    # ENSURE THAT CP IS BEING DONE RIGHT AT END OF SUBPROOF
    ($foo,$subproofend) = split(/,/,$premnums);
    return("The number $i not $subproofend".$BADSUBPROOFEND)
	if $i != $subproofend;

    # ENSURE THAT BEGINNING OF SUBPROOF IS CORRECTLY IDENTIFIED
    my $lastassump = pop @assumption_stack;
    my ($discharge,$foo2) = split(/,/,$saveprems);
    return ("$BADDISCH $lastassump.") if $lastassump != $discharge;
    

    # CORRECT FORMS
    # CONCLUSION MUST BE CONDITIONAL
    @prems = &get_prems($premnums);

    return "CP $CONDCONCREQD" if &wff($conc) ne "conditional";
    return $BADCPANTE if !&samewff(&lhs($conc), $prems[0]);
    return $BADCPCONS if !&samewff(&rhs($conc), $prems[1]);

    # AOK - NEED TO POP AVAILABLE LIST ETC.
    $foo = $lnum;
    while ($foo > $lastassump) {
	$foo = pop @available_lines;
    }
    return "";
}

sub RAA {
    my $lnum = pop(@_);               # actual line number
    my $i = $lnum-1;                  # proof array index
    my $conc = &add_outer_parens(&get_linesent($_[$i])); # conclusion at current line
    my $premnums = &get_ann_nums(&get_annotation($_[$i]));

    my $saveprems = $premnums;

    # CHECK NUMBER OF PREMNUMS
    my $foo = $premnums =~ tr/,/,/ + 1; # count the commas

    return($WRONGRAASPAN) if $foo != 2;

    # ENSURE THAT RAA IS BEING DONE RIGHT AT END OF SUBPROOF
    ($foo,$subproofend) = split(/,/,$premnums);
    return("The number $i not $subproofend".$BADSUBPROOFEND)
	if $i != $subproofend;

    # ENSURE THAT BEGINNING OF SUBPROOF IS CORRECTLY IDENTIFIED
    my $lastassump = pop @assumption_stack;
    my ($discharge,$foo2) = split(/,/,$saveprems);
    return ("$BADDISCH $lastassump.") if $lastassump != $discharge;
    

    @prems = &get_prems($premnums);

    return $RAABADPREM
	if &wff($prems[1]) ne 'conjunction';
    
    my ($premlhs,$premrhs) = (&lhs($prems[1]),&rhs($prems[1]));

    return $RAANOTCONTRAD
	unless (((substr($premlhs,0,1) eq "~") and
		 &samewff(substr($premlhs,1),$premrhs))
		||
		((substr($premrhs,0,1) eq "~") and
		 &samewff(substr($premrhs,1),$premlhs)));

    return $RAABADCONC
	unless (((substr($conc,0,1) eq "~") and
		 &samewff(substr($conc,1),$prems[0]))
		||
		((substr($prems[0],0,1) eq "~") and
                 &samewff(substr($prems[0],1),$conc)));

    # AOK - NEED TO POP AVAILABLE LIST ETC.
    $foo = $lnum;
    while ($foo > $lastassump) {
	$foo = pop @available_lines;
    }
    return "";
    
}

sub HS { # Hypothetical Syllogism
    my $lnum = pop(@_);               # actual line number
    my $i = $lnum-1;                  # proof array index
    my $conc = &add_outer_parens(&get_linesent($_[$i])); # conclusion at current line
    my $premnums = &get_ann_nums(&get_annotation($_[$i]));
    my $foo;

    # CHECK NUMBER OF PREMNUMS
    $foo = $premnums =~ tr/,/,/ + 1; # count the commas
    return($WRONGNUM . "HS: exactly 2") if $foo != 2;

    # CORRECT FORM - BOTH PREMS MUST BE CONDITIONAL
    # CONC MUST ALSO BE A CONDITIONAL
    @prems = &get_prems($premnums);

    return("HS $HSCONDREQD") if
	((&wff($prems[0]) ne "conditional") ||
	 (&wff($prems[1]) ne "conditional"));
    
    return($HSCONDCONC) if
	(&wff($conc) ne "conditional");
    
    # CHECK RULE PATTERN
    # HS IS LHS->MID,MID->RHS:.LHS->RHS
    if (((&samewff( &lhs($prems[0]), &lhs($conc))) &&
	 (&samewff( &rhs($prems[1]), &rhs($conc))) &&
	 (&samewff( &lhs($prems[1]), &rhs($prems[0]))))
	||
	((&samewff( &lhs($prems[1]), &lhs($conc))) &&
	 (&samewff( &rhs($prems[0]), &rhs($conc))) &&
	 (&samewff( &lhs($prems[0]), &rhs($prems[1]))))) {
	return "";  # ALL TESTS PASSED
    } else {
	return($BADHS);
    }
}

sub DS { # Disjunctive Syllogism

    my $lnum = pop(@_);               # actual line number
    my $i = $lnum-1;                  # proof array index
    my $conc = &add_outer_parens(&get_linesent($_[$i])); # conclusion at current line
    my $premnums = &get_ann_nums(&get_annotation($_[$i]));
    my $foo;

    # CHECK NUMBER OF PREMNUMS
    $foo = $premnums =~ tr/,/,/ + 1; # count the commas
    return($WRONGNUM . "DS: exactly 2") if $foo != 2;

    # CORRECT FORM - ONE PREM MUST BE A DISJUNCTION
    # THE OTHER PREM MUST BE A NEGATION
    @prems = &get_prems($premnums);

    return("DS $DSDISREQD") if
        ((&wff($prems[0]) ne "disjunction") &&
         (&wff($prems[1]) ne "disjunction"));
    return("DS $NEGREQD") if
        ((&wff($prems[0]) ne "negation") &&
         (&wff($prems[1]) ne "negation"));

    # CHECK FOR CORRECT PATTERN OF RULE
    # DS IS LHS v RHS, ~LHS :. RHS
    #    OR LHS v RHS, ~RHS :. LHS
    if ((&samewff(&lhs($prems[0]), $conc)) &&
	(&samewff("~".&rhs($prems[0]), $prems[1]))
	||
	((&samewff(&rhs($prems[0]), $conc)) &&
	 (&samewff("~".&lhs($prems[0]), $prems[1])))
	||
	(&samewff(&lhs($prems[1]), $conc)) &&        
        (&samewff("~".&rhs($prems[1]), $prems[0]))
        ||
        ((&samewff(&rhs($prems[1]), $conc)) &&
         (&samewff("~".&lhs($prems[1]), $prems[0])))) {
	return ""; # ALL TESTS PASSED!!
    } else {
	return($BADDS);
    }
}

sub SIMP { # Simplification

    my $lnum = pop(@_);               # actual line number
    my $i = $lnum-1;                  # proof array index
    my $conc = &add_outer_parens(&get_linesent($_[$i])); # conclusion at current line
    my $premnums = &get_ann_nums(&get_annotation($_[$i]));
    my $foo;

    # CHECK NUMBER OF PREMNUMS
    $foo = $premnums =~ tr/,/,/ + 1; # count the commas
    return($WRONGNUM . "SIMP: exactly 1") if $foo != 1;

    # CHECK CORRECT FORM
    @prems = &get_prems($premnums);

    return("$CONJREQD") if
        (&wff($prems[0]) ne "conjunction");

    # CHECK RULE PATTERN - SIMP IS LHS.RHS :. LHS OR LHS.RHS :. RHS
    if (&samewff( &lhs($prems[0]), $conc)
	||
	(&samewff( &rhs($prems[0]), $conc))) {
	return""; # ALL TESTS PASSED!!
    } else {
	return($BADSIMP);
    }

}

sub ADD { # ADDITION
    my $lnum = pop(@_);               # actual line number
    my $i = $lnum-1;                  # proof array index
    my $conc = &add_outer_parens(&get_linesent($_[$i])); # conclusion at current line
    my $premnums = &get_ann_nums(&get_annotation($_[$i]));
    my $foo;

    # CHECK NUMBER OF PREMNUMS
    $foo = $premnums =~ tr/,/,/ + 1; # count the commas
    return($WRONGNUM . "ADD: exactly 1") if $foo != 1;
    
    # CHECK CORRECT FORM - CONC MUST BE A DISJUNCTION
    @prems = &get_prems($premnums);

    return("ADD $ADDDISJREQD") if
        ((&wff($conc) ne "disjunction"));

    # CHECK RULE PATTERN 
    # ADD IS LHS :. LHS v RHS OR RHS :. LHS v RHS
    if (&samewff($prems[0], &lhs($conc))
	# uncomment next two lines if Layman relaxes rule
	# he did for 3e - yay!
	||
	&samewff($prems[0], &rhs($conc))
	) {
	return ""; # All checks passed
    } else {
	return($BADDADD);
    }
}

sub CONJ {  # CONJUNCTION
    my $lnum = pop(@_);               # actual line number
    my $i = $lnum-1;                  # proof array index
    my $conc = &add_outer_parens(&get_linesent($_[$i])); # conclusion at current line
    my $premnums = &get_ann_nums(&get_annotation($_[$i]));
    my $foo;

    # CHECK NUMBER OF PREMNUMS
    $foo = $premnums =~ tr/,/,/ + 1; # count the commas
    return($WRONGNUM . "CONJ: exactly 2") if $foo != 2;
    
    # CHECK CORRECT FORM - CONC MUST BE A CONJUNCTION
    @prems = &get_prems($premnums);

    return("CONJ $CONJCNJREQD") if
    ((&wff($conc) ne "conjunction"));

    # CHECK RULE PATTERN 
    # CONJ IS LHS, RHS :. LHS.RHS OR LHS, RHS :. RHS.LHS
    if ((&samewff($prems[0], &lhs($conc)) &&
	 &samewff($prems[1], &rhs($conc)))
	||
	(&samewff($prems[0], &rhs($conc)) &&
	 &samewff($prems[1], &lhs($conc)))) {
	return ""; # ALL TESTS PASSED
    } else {
	return($BADCONJ);
    }
    
}

sub CD { # Constructive Dilemma

    my $lnum = pop(@_);               # actual line number
    my $i = $lnum-1;                  # proof array index
    my $conc = &add_outer_parens(&get_linesent($_[$i])); # conclusion at current line
    my $premnums = &get_ann_nums(&get_annotation($_[$i]));

    my $foo;
    # CHECK NUMBER OF PREMNUMS
    $foo = $premnums =~ tr/,/,/ + 1; # count the commas

    return($WRONGNUM . "CD: exactly 3") if $foo != 3;
    
    # CHECK CORRECT FORM - 
    #CD MUST HAVE A DISJUNCTION, TWO CONDITIONALS & CONC MUST BE DISJUNCTION
    @prems = &get_prems($premnums);

    return("CD $CDDISJCONCREQD") if
	(&wff($conc) ne "disjunction");
    return("CD $CDCONDREQD") if
        (((&wff($prems[0]) ne "conditional") &&
	  (&wff($prems[1]) ne "conditional"))
	 ||
	 ((&wff($prems[0]) ne "conditional") &&
	  (&wff($prems[2]) ne "conditional"))
	 ||
	 ((&wff($prems[1]) ne "conditional") &&
	  (&wff($prems[2]) ne "conditional")));
    return("CD $DISJREQD") if
	((&wff($prems[0]) ne "disjunction") 
	 &&
	 (&wff($prems[1]) ne "disjunction")
	 &&
	 (&wff($prems[2]) ne "disjunction"));

    # CHECK RULE PATTERN
    # CD IS AvB, A->C, B->D :. CvD
    if (((&wff($prems[0]) eq "disjunction") &&
	((&samewff(&lhs($prems[0]), &lhs($prems[1]))) ||
	 (&samewff(&lhs($prems[0]), &lhs($prems[2])))) &&
	((&samewff(&rhs($prems[0]), &lhs($prems[1]))) ||
	 (&samewff(&rhs($prems[0]), &lhs($prems[2])))) &&
	((&samewff(&rhs($prems[1]), &lhs($conc))) ||
	 (&samewff(&rhs($prems[1]), &rhs($conc)))) &&
	((&samewff(&rhs($prems[2]), &lhs($conc))) ||
	 (&samewff(&rhs($prems[2]), &rhs($conc)))))
	||
	((&wff($prems[1]) eq "disjunction") &&
	((&samewff(&lhs($prems[1]), &lhs($prems[0]))) ||
	 (&samewff(&lhs($prems[1]), &lhs($prems[2])))) &&
	((&samewff(&rhs($prems[1]), &lhs($prems[0]))) ||
	 (&samewff(&rhs($prems[1]), &lhs($prems[2])))) &&
	((&samewff(&rhs($prems[0]), &lhs($conc))) ||
	 (&samewff(&rhs($prems[0]), &rhs($conc)))) &&
	((&samewff(&rhs($prems[2]), &lhs($conc))) ||
	 (&samewff(&rhs($prems[2]), &rhs($conc)))))
	 ||
	 ((&wff($prems[2]) eq "disjunction") &&
	((&samewff(&lhs($prems[2]), &lhs($prems[1]))) ||
	 (&samewff(&lhs($prems[2]), &lhs($prems[0])))) &&
	((&samewff(&rhs($prems[2]), &lhs($prems[1]))) ||
	 (&samewff(&rhs($prems[2]), &lhs($prems[0])))) &&
	((&samewff(&rhs($prems[1]), &lhs($conc))) ||
	 (&samewff(&rhs($prems[1]), &rhs($conc)))) &&
	((&samewff(&rhs($prems[0]), &lhs($conc))) ||
	 (&samewff(&rhs($prems[0]), &rhs($conc)))))) {
	    return ""; # ALL TESTS PASSED !!
	} else {
	    return($BADCD);
	}
}

1; # required by require






