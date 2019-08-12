# qlwff-subrs.pl
#  subroutines in this file can be included in applications that need them

# This file requires "wff-subrs.pl" but it is assumed that you require it
# in the calling script

$debug=0;

%CONNECTIVES = ('negation'=>'~',
		'disjunction'=>'v',
		'conjunction'=>'.',
		'conditional'=>'->',
		'biconditional'=>'<->');

sub isinstance {
    my ($partic,$gen) = @_;
    $partic =~ s/\s//g;  ## the purported instance
    $gen =~ s/\s//g;     ## the purported generalization

    my $gtype  = &wff($gen);
    my $ptype  = &wff($partic);

    if ($gtype =~ /universal|existential/) {
	$var = &getvar($gen);   # the var in the quantifier

	$gen = &getscope($gen); # formula in the scope of the quantifier
	return 'VAC'
	    if (!&isfree($var,$gen)   ## vacuous when the var isn't free the scope
		and &samewff($gen,$partic)   ## and nothing else has changed
	    );
	$gen =~ /^([^$var]+)($var+)/;
	return 0 if length($1) >= length($partic);
	$const = substr($partic,length($1),1);
	return $const if isinst_recursive($partic,$gen,$var,$const);

    } else {
	return 0;
    }
}

sub isinst_recursive { # note this will loop forever if wfs have spaces
    my($wf1,$wf2,$var,$const) = @_;
    my $type = &wff($wf1);
    my $typ2 = &wff($wf2);

    print "check $wf1 instance $wf2 $var $const;<br>\n" if $debug;
    return 0 if $type ne $typ2;
    
    if ($type eq 'atomic') {
	return &samewff($wf1,$wf2);
    } elsif ($type =~ /predicate atomic|identity/) {
	print "here\n" if $debug;
	$wf2 =~ s/$var/$const/g;
	return &samewff($wf1,$wf2);
    } elsif ($type eq 'negation') {
	return &isinst_recursive(substr($wf1,1,length($wf1)),
				 substr($wf2,1,length($wf1)),
				 $var,$const);
    } elsif ($type =~ /universal|existential/) {
	my $newvar = &getvar($wf1);
	print "compare $newvar $const<br>\n" if $debug;
	if ($newvar eq $const or $newvar eq $var) {
	    # no substitutions allowed in this branch
	    return &samewff($wf1,$wf2);
	} else {
	    print "here" if $debug;
	    return &isinst_recursive(&getscope($wf1),
				     &getscope($wf2),
				     $var,$const);
	}
    } else { # binary formulas, check separately
	return (&isinst_recursive(&lhs($wf1),&lhs($wf2),$var,$const)
		&&
		&isinst_recursive(&rhs($wf1),&rhs($wf2),$var,$const));
    }
}    

sub getvar { # assumes existential or universal input
    my ($wf) = @_;
    $wf =~ s/\s//g;
    $wf =~ /^\(\$?([t-z])\)/;
    return $1;
}

sub getscope { # assumes existential or universal input
    my ($wf) = @_;
    $wf =~ s/\s//g;
    $wf =~ /^\(\$?[t-z]\)(.*)$/;
    my $result = $1;
#    print "&getscope($wf) returns $result<br>";
    return $result;
}

sub isfree {
    my ($var, $wf) = @_;
    $wf = &add_outer_parens($wf);
    my $type = &wff($wf);

    if ($type =~ /atomic|identity/) {
	return 1 if $wf =~ /$var/;
	return 0;
    } elsif ($type eq "negation"){
	return &isfree($var,substr($wf,1,length($wf)-1));
    } elsif ($type =~ /junction|conditional/){
	return (&isfree($var,&lhs($wf)) or &isfree($var,&rhs($wf)));
    } elsif ($type =~ /existential|universal/){
	return 0 if &getvar($wf) eq $var;
	return &isfree($var,&getscope($wf));
    }
    print "\n\nERROR in isfree: Non wff $wf\n\n";
}

## code for expansions -- added by CA 5/11/2001

sub expand_qwff {
    my ($wff,@universe) = @_;
    my $result = $wff;
    while (!&qfree($result)) {
        $result = &semi_expand_qwff($result,@universe);
    }
    return $result;
}

sub is_expansion { # <wff,exp,@universe>
    my ($wff,$exp,@universe) = @_;
    $wff=~ s/\s//g;    $exp=~ s/\s//g;
    my ($wfftype,$wfflhs,$wffrhs) = (&wff($wff),
				     &lhs($wff),
				     &rhs($wff));
    my ($exptype,$explhs,$exprhs) = (&wff($exp),
				     &lhs($exp),
				     &rhs($exp));

    return 0 unless $wfftype and $exptype; # must be wffs
    return 0 unless &qfree($exp); # no quantifiers in answer

    if (&qfree($wff)) {
        return &expanded_equiv($wff,$exp);
    } elsif ($wfftype eq 'negation') {
        return 0 unless $exptype eq 'negation';
        return &is_expansion(substr($wff,1),substr($exp,1),@universe);
    } elsif ($wfftype eq 'conditional') {
        return 0 unless $exptype eq 'conditional';
        return (&is_expansion($wfflhs,$explhs,@universe)
                and
                &is_expansion($wffrhs,$exprhs,@universe));
    } elsif ($wfftype =~ /junction|biconditional/) {
        return 0 unless $exptype eq $wfftype;
        return ((&is_expansion($wfflhs,$explhs,@universe)
                 and
                 &is_expansion($wffrhs,$exprhs,@universe))
                or
                (&is_expansion($wfflhs,$exprhs,@universe)
                 and
                 &is_expansion($wffrhs,$explhs,@universe)));
    } else {
        return 0 unless
            ($wfftype eq 'universal' and $exptype eq 'conjunction'
             or
             $wfftype eq 'existential' and $exptype eq 'disjunction'
             or
             $#universe == 0);

        for (&permutate(@universe)) {
            return 1
                if &is_expansion(&semi_expand_qwff($wff,@$_),
                                 $exp,@universe);
        }
        return 0; # no permutations worked

    }
}

sub semi_expand_qwff {
    my ($wff,@universe) = @_;
    my ($type,$lhs,$rhs) = (&wff($wff),
			    &lhs($wff),
			    &rhs($wff));

    if (&qfree($wff)) {
        return $wff;
    } elsif ($type eq 'negation') {
        return $CONNECTIVES{$type}.&semi_expand_qwff(substr($wff,1),@universe);
    } elsif ($type =~ /junction|conditional/) {
        return
            "(".&semi_expand_qwff($lhs,@universe).
                $CONNECTIVES{$type}.
                    &semi_expand_qwff($rhs,@universe).")";
    } else {

        my @result;
        my $newtype = "conjunction";
        $newtype = "disjunction" if $type eq 'existential';
	my $scope = &getscope($wff); # do this outside loop for efficiency
        foreach $constant (@universe) {
            my $clause = $scope;
            my $var = &getvar($wff);
            $clause = &replace_var($var,$constant,$clause);
            push @result, $clause;
        }
        return &makewff($CONNECTIVES{$newtype},@result);
    }
}

sub replace_var {
    my ($var,$constant,$clause) = @_;
    if ($clause !~ /\(\$?$var\)/) { # no conflicting quantifiers
	$clause =~ s/$var/$constant/g;
	return $clause;
    } else { # messy case
	my $parencount = 0;
	my $insubscope = 0;
	my $result;
	$clause =~ s/\($var\)/(\@$var)/g; # add marker for universal - makes things easier
	my @chars = split(//,$clause);
	for (my $i=0;$i<$#chars;++$i) {
	    if ($chars[$i] eq $var) {
		if (!$insubscope) { # change it
		    $result.=$constant;
		} else { # leave it alone
		    $result.=$chars[$i];
		}
	    } else {
		my $next4 = join "", @chars[$i..$i+3];

		if ($next4 =~ /\((\$|\@)$var\)/) {
		    ## we have a screening quantifier (same $var)
		    my $quantifier = "(".$1.$var.")";
		    $quantifier =~ s/\@//;
		    $result .= $quantifier;
		    $inscope = 1;
		    $i += 3;
		    while ($inscope) {
			++$i;
			last if $i > $#chars;
			$result .= $chars[$i];
			if (!$parencount) {
			    ++$parencount if $chars[$i] eq '(';
			    --$parencount if $chars[$i] eq ')';
			    $inscope = 0
				if (!$parencount and
				    ($chars[$i] eq ')'
				     or
				     $chars[$i] !~ /[A-Za-z]/));
			}
		    }
		} else {
		    $result.=$chars[$i];
		}
	    }
	}
	return $result;
    }
}

sub makewff {
    my ($connective,@clauses) = @_;
    if ($#clauses <= 0) {
        return $clauses[0];
    } elsif ($#clauses == 1) {
        return "(".join($connective,@clauses).")";
    } else {
        my $first = shift @clauses;
        return "(".join($connective,$first,&makewff($connective,@clauses)).")";
    }
}

sub qfree { # <formula>: boolean - contains quantifiers?
    return $_[0] !~ /\(\w\)|\$/;
}

sub expanded_equiv {
    my ($wff,$exp) = @_;
    my $result;

    my $wfftype = &wff($wff);
    my $exptype = &wff($exp);

    return 0 unless $wfftype eq $exptype;

    $wff = join "", sort &get_clauses($wff,$wfftype);
    $exp = join "", sort &get_clauses($exp,$exptype);
    return $wff eq $exp;
}

sub get_clauses {
    my($wff,$type) = @_;
    return () unless $wff;

    my ($wfftype,$wfflhs,$wffrhs) = (&wff($wff),
				     &lhs($wff),
				     &rhs($wff));

    if ($type ne $wfftype or $type !~ /junction/) {
        return $wff;
    } else {
        return (&get_clauses($wfflhs,$type),
		&get_clauses($wffrhs,$type));
    }
}

sub permutate {
    return () unless @_;
    my $first = shift;
    return ([$first]) unless @_;

    map {my $row = $_;
         map {my $tmp = [@$row];
              splice @$tmp, $_, 0, $first; $tmp;} (0 .. @$row);} permutate(@_);
}

sub list_constants {
    my ($form) = @_;
    $form =~ s/[^a-u]//g;
    return split(//,$form);
}

1;          # required by require
