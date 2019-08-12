#!/usr/bin/perl 

# ql-rules.pl
# Subroutines to support proofcheck.pl
# quantificational rules from chapter 9

# Version 0.9 Colin Allen Oct 4, 1998
# - all rules roughed out, includes QN, LL, Sm, Id
# - known bug in LL - will fail if target var is bound in conclusion
# Version 0.5 Colin Allen Oct 2, 1998
# - all basic QL rules: UI, UG, EI, EG, DN
# Version 0.1 Colin Allen Sep 24, 1998
# - first stab at equiv rules - DN and COM

#require "../lib/header.pl";
require "../Proof/errors";
require "../lib/qlwff-subrs.pl";

# RULE SUBROUTINES EXPECT TO RECEIVE AN ARRAY
# WHOSE LAST ELEMENT IS A LINE NUMBER (THE LINE TO CHECK)
# AND THE OTHER ELEMENTS ARE THE LINES OF PROOF
# THEY RETURN A NULL STRING IF THE RULE IS CORRECTLY APPLIED
# OTHERWISE THEY RETURN A DIAGNOSTIC STRING

## UI rewritten for 4e
sub UI { # UNIVERSAL INSTANTIATION
    my $lnum = pop(@_);               # actual line number
    my $i = $lnum-1;                  # proof array index
    my $conc = &add_outer_parens(&get_linesent($_[$i])); # conclusion at current line
    my $premnums = &get_ann_nums(&get_annotation($_[$i]));
    my $foo;

    
    # CHECK NUMBER OF PREMNUMS (E.G. MP = 2)
    $foo = $premnums =~ tr/,/,/ + 1; # count the commas
    return($WRONGNUM . "UI: exactly 1") if $foo != 1;

    @prems = &get_prems($premnums);

    # CHECK RULE PATTERN
    # UI IS (x)PHIx => PHIc
    # No special conditions

    # premise is universal
    return($UNIVREQD . &wff($prems[0]))
	if &wff($prems[0]) ne "universal";

    # conclusion is instance
    my $instname = &isinstance($conc,$prems[0]);

    return($NOTINST)
	if !$instname;
    return($NOTNAME)
	unless $instname eq "VAC" or $instname =~ /^[a-u]$/;

    return "";
}


## EI rewritten for 4e
sub EI { # EXISTENTIAL INSTANTIATION
    my $lnum = pop(@_);               # actual line number
    my $i = $lnum-1;                  # proof array index
    my $conc = &add_outer_parens(&get_linesent($_[$i])); # conclusion at current line
    my $premnums = &get_ann_nums(&get_annotation($_[$i]));
    my $foo;
    
    # CHECK NUMBER OF PREMNUMS (E.G. MP = 2)
    $foo = $premnums =~ tr/,/,/ + 1; # count the commas
    return($WRONGNUM . "EI: exactly 1") if $foo != 1;
    
    @prems = &get_prems($premnums);
    
    # CHECK RULE PATTERN
    # EI IS ($x)PHIx => PHIc

    # premise is existential
    return($EXISREQD)
	if &wff($prems[0]) ne "existential";

    # conclusion is instance
    my $instname = &isinstance($conc,$prems[0]);

    return($NOTINST)
	if !$instname;
    
    return($NOTNAME)
	unless $instname eq "VAC" or $instname=~ /[a-u]/;

    my @constants_in_conc = &list_constants($conc);

    # name must not appear in earlier lines, even if VACuous
    for($j=0;$j<$i;$j++){
	return($EINAMEFOUND.++$j.'.')
	    if &get_linesent($_[$j]) =~ /$instname/;
	foreach (@constants_in_conc) {
	    return($VACNAMEFOUND.++$j.'.')
		if ($instname eq "VAC" and
		    $j != $premnums[0] and
		    &get_linesent($_[$j]) =~ /$_/)
	}
    }
    
    # name must not appear in the conclusion of the proof
    return($EINAMEINCONC) if $conclusion =~ /$instname/;
    
    return "";
}


## the old way
sub EI_pre4e { # EXISTENTIAL INSTANTIATION
    my $lnum = pop(@_);               # actual line number
    my $i = $lnum-1;                  # proof array index
    my $conc = &add_outer_parens(&get_linesent($_[$i])); # conclusion at current line
    my $premnums = &get_ann_nums(&get_annotation($_[$i]));
    my $foo;

    
    # CHECK NUMBER OF PREMNUMS (E.G. MP = 2)
    $foo = $premnums =~ tr/,/,/ + 1; # count the commas
    return($WRONGNUM . "EI: exactly 1") if $foo != 1;

    @prems = &get_prems($premnums);

    # CHECK RULE PATTERN
    # EI IS ($x)PHIx => PHIx
    # Has special conditions - x not free earlier

    # premise is existential
    return($EXISREQD)
	if &wff($prems[0]) ne "existential";

    # conclusion is instance
    my $instvar = &isinstance($conc,$prems[0]);
    return($NOTINST)
	if !$instvar;
    return($NOTVAR)
	unless $instvar =~ /[v-z]/;

    # var is free in earlier line
    for($j=0;$j<$i;$j++){
	return($EIVARFREE.++$j) if &isfree($instvar,&get_linesent($_[$j]));
    }

    return($EREBOUND) unless &isfree($instvar,$conc);

    return "";
}


## rewritten for 4e
sub UG { # UNIVERSAL GENERALIZATION
    my $lnum = pop(@_);               # actual line number
    my $i = $lnum-1;                  # proof array index
    my $conc = &add_outer_parens(&get_linesent($_[$i])); # conclusion at current line
    my $premnums = &get_ann_nums(&get_annotation($_[$i]));
    my $foo;

    
    # CHECK NUMBER OF PREMNUMS (E.G. MP = 2)
    $foo = $premnums =~ tr/,/,/ + 1; # count the commas
    return($WRONGNUM . "UG: exactly 1") if $foo != 1;

    @rprems = &get_prems($premnums);

    # CHECK RULE PATTERN
    # UG IS  PHIc => (x)PHIx
    # Has special conditions - c not appear in premise, or line from EI, or (x)P

    # conclusion must be universal
    return($UNIVCREQD)
	if &wff($conc) ne "universal";

    # premise is instance
    my $instname = &isinstance($rprems[0],$conc);


    return($NOTINSTNAME)
	unless $instname eq "VAC" or $instname =~ /[a-u]/;

    # Added by CM, 3 May 09
    # name occurs in generalized WFF
    return($UGCONSTINCONC)
	if $conc =~ /$instname/;

    # check whether name occurs in premise, universal, or was derived by EI
    return $UGCONSTINPREMS if $premises =~ /$instname/;

    for($j=0;$j<$i;$j++){  # for every previous line j
	my $sentence = &get_linesent($_[$j]);
	next unless $sentence =~ /$instname/;

	# first check for prior universal contamination
	# Commented out by CM, 3 May 09
#	return $UGUNIV.++$j if &wff($sentence) eq "universal";

	# check this isn't EI produced
	return $UGNOEI.++$j
	    if &get_rule(&get_annotation($_[$j])) =~ /EI/i;
	
    }

    foreach $assumption (@assumption_stack) {
	return($UGVARFREEASS.$assumption)
	    if &isfree($instname,&get_linesent($_[$assumption-1]));
    }

    return ""; # ALL TESTS PASSED!
}

sub EG { # EXISTENTIAL GENERALIZATION
    my $lnum = pop(@_);               # actual line number
    my $i = $lnum-1;                  # proof array index
    my $conc = &add_outer_parens(&get_linesent($_[$i])); # conclusion at current line
    my $premnums = &get_ann_nums(&get_annotation($_[$i]));
    my $foo;

    
    # CHECK NUMBER OF PREMNUMS (E.G. MP = 2)
    $foo = $premnums =~ tr/,/,/ + 1; # count the commas
    return($WRONGNUM . "EG: exactly 1") if $foo != 1;

    @rprems = &get_prems($premnums);

    # CHECK RULE PATTERN
    # EG IS  PHIa/x => ($x)PHIa/x
    # Has special conditions - x not free earlier in line obtained by EI

    # premise must be universal
    return($EXISCREQD)
	if &wff($conc) ne "existential";

    # premise must be properly related
    my $instvar = &isinstance($rprems[0],$conc);
    return($NOTINSTC)
	if !$instvar;

    return($EGNOTFREEVAR)
	if $instvar =~ /[w-z]/ and !&isfree($instvar,$rprems[0]);
    
    return ""; # ALL TESTS PASSED!
}

sub QN { # QUANTIFIER NEGATION
    my $lnum = pop(@_);               # actual line number
    my $i = $lnum-1;                  # proof array index
    my $conc = &add_outer_parens(&get_linesent($_[$i])); # conclusion at current line
    my $premnums = &get_ann_nums(&get_annotation($_[$i]));
    my $foo;

    
    # CHECK NUMBER OF PREMNUMS (E.G. MP = 2)
    $foo = $premnums =~ tr/,/,/ + 1; # count the commas
    return($WRONGNUM . "QN: exactly 1") if $foo != 1;

    @rprems = &get_prems($premnums);

    # CHECK RULE PATTERN
    # QN IS (...~()X...) <=> (...()~X...)
    if (&QN_recursive($rprems[0],$conc)) {
	return ""; # CORRECT
    } else {
	return("$BADQN");
    }
}

sub QN_recursive {
    my ($wf1,$wf2) = @_;

    my $type1 = &iswff($wf1);
    my $type2 = &iswff($wf2);

    if ($type1 eq $type2) {
	if ($type1 =~ /atomic|identity/) {
	    return 0;
	} elsif ($type1 eq "negation") {
	    return &QN_recursive(substr($wf1,1),
				 substr($wf2,1));
	} elsif ($type1 =~ /universal|existential/) {
	    return &QN_recursive(&getscope($wf1),&getscope($wf2));
	} else {
	    return ((&QN_recursive(&lhs($wf1),&lhs($wf2)) 
		     && &samewff(&rhs($wf1),&rhs($wf2)))
		    ||
		    (&QN_recursive(&rhs($wf1),&rhs($wf2))
		     && &samewff(&lhs($wf1),&lhs($wf2))));
	}


    } else { # they are different types
	# there are eight (as of 4e) acceptable patterns for QN:
	# Right to Left and Left to Right on each of these...
	# ~(x) <=> ($x)~
	# ~($x) <=> (x)~
	# ~(x)~ <=> ($x)
	# ~($x)~ <=> (x)
	
	if (($type1 =~ /universal|existential/)  # Right to Left cases above
	    && ($type2 eq 'negation')) {
	    my $wf2 = substr($wf2,1);
	    my $wftype = &wff($wf2);
	    my $var1 = &getvar($wf1);
	    my $var2 = &getvar($wf2);
	    return "" unless $var1 eq $var2;
	    return (($wftype =~ /universal|existential/)
		    && ($wftype ne $type1)
		    && (# cases where tilde is pushed through quantifier
			&samewff(substr(&getscope($wf1),1),
				 &getscope($wf2))
			||
			# cases where tildes cancel either side of quantifier
			&samewff(substr(&getscope($wf2),1),
				 &getscope($wf1)))
		    );
	} elsif (($type2 =~ /universal|existential/)   # Left to Right cases above
		 && ($type1 eq 'negation')) {
	    my $wf1 = substr($wf1,1);
	    my $wftype = &wff($wf1);

	    my $var1 = &getvar($wf1);
	    my $var2 = &getvar($wf2);
	    return "" unless $var1 eq $var2;

	    return (($wftype =~ /universal|existential/)
		    and ($wftype ne $type2)
		    and (# cases where tilde is pushed through quantifier
			 &samewff(substr(&getscope($wf2),1),
				  &getscope($wf1))
			 ||
			 # cases where tildes cancel either side of quantifier
			 &samewff(substr(&getscope($wf1),1),
				  &getscope($wf2)))
		    );
	} else {
	    return 0;
	}
    }
}

sub LL { # LEIBNIZ' LAW, SORT OF
    my $lnum = pop(@_);               # actual line number
    my $i = $lnum-1;                  # proof array index
    my $conc = &add_outer_parens(&get_linesent($_[$i])); # conclusion at current line
    my $premnums = &get_ann_nums(&get_annotation($_[$i]));
    my $foo;
    
    # CHECK NUMBER OF PREMNUMS (E.G. MP = 2)
    $foo = $premnums =~ tr/,/,/ + 1; # count the commas
    return($WRONGNUM . "LL: exactly 2") if $foo != 2;
    
    @prems = &get_prems($premnums);
    
    # CHECK RULE PATTERN
    # LL IS a=b, PHIa => PHIb
    # vars must be free in PHI one or more occurrences
    
    my ($t1,$t2,$model);

    return $LLNOID
	if (&wff($prems[0]) ne 'identity' and
	    &wff($prems[1]) ne 'identity');

    if (&wff($prems[0]) eq 'identity') {
	$t1 = &lhs($prems[0]);
	$t2 = &rhs($prems[0]);
	$model = $prems[1];

	return "" # ok
	    if (&LL_recursive($t1,$t2,$model,$conc)
		or
		&LL_recursive($t2,$t1,$model,$conc));
    }

    if (&wff($prems[1]) eq 'identity') { # fires if prems[1] is 1st or 2nd identity premise
	$t1 = &lhs($prems[1]);
	$t2 = &rhs($prems[1]);
	$model = $prems[0];
	return "" # ok
	    if (&LL_recursive($t1,$t2,$model,$conc)
		or
		&LL_recursive($t2,$t1,$model,$conc));
    }

    # failed test; try to diagnose what's bad about ti

    return $LLNOMATCH if &wff($model) ne &wff($conc);

    # does LL actually require a change?
    return $LLNOCHANGE if &samewff($model,$conc);
    
    return $LLBADSUB; # only other explanation
}

sub LL_recursive { # returns 1 if acceptable substitution of t1 in wf1 for t2 in wf2
    my($t1,$t2,$wf1,$wf2) = @_;

    $type = &wff($wf1);
    
    return 0 if $type ne &wff($wf2);
    if ($type =~ /atomic|identity/) {
	return &LL_comp($t1,$t2,$wf1,$wf2);
    } elsif ($type =~ /negation/) {
	return &LL_recursive($t1,$t2,substr($wf1,1),substr($wf2,1));
    } elsif ($type =~ /junction|conditional/) {
	my ($l1,$l2,$r1,$r2) = (&lhs($wf1),&lhs($wf2),&rhs($wf1),&rhs($wf2));
	if ($l1 eq $l2) {
	    return &LL_recursive($t1,$t2,&rhs($wf1),&rhs($wf2));
	} elsif ($r1 eq $r2) {
	    return &LL_recursive($t1,$t2,&lhs($wf1),&lhs($wf2));
	} else {
	    return (&LL_recursive($t1,$t2,&lhs($wf1),&lhs($wf2))
		    and &LL_recursive($t1,$t2,&rhs($wf1),&rhs($wf2)));
	}
    } elsif ($type =~ /universal|existential/) {
	my $var1 = &getvar($wf1);
	my $var2 = &getvar($wf2);
	return 0 # can't go into bound contexts
	    if (($var1 ne $var2) or
		($var1 eq $t1) or
		($var2 eq $t2));
	return &LL_recursive($t1,$t2,&getscope($wf1),&getscope($wf2));
    }
}

sub LL_comp {
    my($t1,$t2,$wf1,$wf2) = @_;

    return 0 if $wf1 eq $wf2;

    my @parts1 = split(//,$wf1);
    my @parts2 = split(//,$wf2);

    my $i = 0;
    
    for (@parts1) {
	return 0 unless
	    ($parts1[$i] eq $parts2[$i]
	     or ($parts1[$i] eq $t1 and $parts2[$i] eq $t2));
	++$i;
    }

    return 1;
}
    
sub LL_comp_orig {
    my($t1,$t2,$wf1,$wf2) = @_;
    
    $wf1 =~ s/$t1/$t2/g; # substitute
    $wf2 =~ s/$t1/$t2/g; # added to fix bug on 5/2/07
    ## this is too lenient if a=b, Mab :. Mba is not allowed as a single LL
    
    #print "LL_comp $wf1,$wf2<br />"; # debug
    return &samewff($wf1,$wf2);
}
    
sub SM { # Symmetry
    my $lnum = pop(@_);               # actual line number
    my $i = $lnum-1;                  # proof array index
    my $conc = &add_outer_parens(&get_linesent($_[$i])); # conclusion at current line
    my $premnums = &get_ann_nums(&get_annotation($_[$i]));
    my $foo;

    # CHECK NUMBER OF PREMNUMS (E.G. MP = 2)
    $foo = $premnums =~ tr/,/,/ + 1; # count the commas
    return($WRONGNUM . "SM: exactly 1") if $foo != 1;

    @prems = &get_prems($premnums);

    # CHECK RULE PATTERN
    # SM IS (x=y) => (y=x)
    ## OR ~(x=y) => ~(y=x) !!! revised Nov 14 2000
    # No special conditions

    my $concform = &wff($conc);
    my $premform = &wff($prems[0]);
    
    return "$SMPREMCONC"
	unless $concform eq $premform;
    return "$SMPREMCONC"
	unless $concform eq 'negation'
	    or $concform eq 'identity';

    if ($concform eq 'identity') {
	return "$SMBADMATCH"
	    if (&lhs($conc) ne &rhs($prems[0])
		|| &rhs($conc) ne &lhs($prems[0]));	
    } elsif ($concform eq 'negation') {
	my $conc_identity = substr($conc,1);
	my $prem_identity = substr($prems[0],1);
	return "$SMBADMATCH"
            if (&lhs($conc_identity) ne &rhs($prem_identity)
                || &rhs($conc_identity) ne &lhs($prem_identity));
    }

    return ""; # ALL TESTS PASSED!
}

sub ID { # Identity
    my $lnum = pop(@_);               # actual line number
    my $i = $lnum-1;                  # proof array index
    my $conc = &add_outer_parens(&get_linesent($_[$i])); # conclusion at current line
    my $foo;
    
    # CHECK NUMBER OF PREMNUMS (E.G. MP = 2)
    $foo = $premnums =~ tr/,/,/; # count the commas
    print $premnums;
    return($WRONGNUM . "ID: exactly 0") if $foo != 0;

    # CHECK RULE PATTERN
    # ID IS => (x=x)
    # No special conditions
    
    return ""
	if (&wff($conc) eq 'identity'
	    && &lhs($conc) eq &rhs($conc));

    return "$BADID";
}

1; # required by require
