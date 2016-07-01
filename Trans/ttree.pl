#!/usr/bin/perl -w
# ttree.pl
# Chris Menzel, 13-14 Jan 99

# ttree tests a list of wffs (a singleton, in particular) for
# consistency by implementing the truth tree method -- in general, a
# far more efficient way of testing logical properties than truth
# tables.  It returns a 0 if the list is consistent, and 1 if not.
# (The reason for this is that this code is currently being used only
# to test for the validity of negated biconditionals ~(A<->B) formed
# from a user's symbolization A and a canned answer B.  If the user's
# answer A is equivalent to B, then &ttree(~(A<->B)) will return 1,
# which makes more logical sense in the context of the calling
# program.)  The routine takes three scalars as arguments: (1) a
# reference to an array of formulas representing a branch in a truth
# tree, (2) a reference to an array (always initially empty)
# representing instances of universal wffs that have appeared in the
# branch (necessary because wffs that have been decomposed on a branch
# are removed from the branch -- but we have to remember when a
# decomposed wff was also an instance of a universally quantified
# formula on the branch), and (3) a string of the constants that
# appear in the branch.  The latter must always initially consist of
# exactly the constants occurring in the formulas in the initial
# branch array.

#$str_o_wffs = '(y)(z)(Aazy<->(x)(Byx->Bzx)) (v)(Bbv<->(x)(y)(z)((Avxy.Avyz)->Avxz)) ~Bba';
#$str_o_wffs = '(y)(z)(Aszy<->(x)(Byx->Bzx)) (v)(Btv<->(x)(y)(z)((Avxy.Avyz)->Avxz)) ~Bts';
#$str_o_wffs = '~[(~(z)~(y)~Pzy->($z)(y)~Qzy)->($x)(y)(~Pxy->~Qxy)]';
#$str_o_wffs = '~[(~(z)~(y)~Fzy->($z)(y)~Gzy)->($x)(y)(~Fxy->~Gxy)]';
#$str_o_wffs = '~[($x)(y)(~Fxy->~Qxy)->(~(z)~(y)~Fzy->($z)(y)~Qzy)]';
#$str_o_wffs = '~[~(z)~(y)~Fzy->($z)(y)~Qzy]';
#$str_o_wffs = '(x)($y)(Gx.Fy) (x)(~Hx<->(y)(Fy.Gx)) ~~(x)Hx';
#$str_o_wffs = '($x)(y)Fxy ~($x)(y)Gxy';
#$str_o_wffs = '(y)($x)Fxy ~($x)Fxx';
#$str_o_wffs = '(x)(Fx->($y)Gxy) ~(x)(y)(Fxv~Gxy)';
#$str_o_wffs = '(x)~(y)Txy ~(x)~($y)Txy';
#$str_o_wffs = '(x)($y)Fxy ~($x)(y)Fxy';
#$str_o_wffs = '~($x)(y)Fxy';
#$str_o_wffs = '($x)(Fx->Gx) ~(x)Fx->(x)Gx';
#$str_o_wffs = '($x)($y)($z)((Fxy.Fyz).~(FxzvFyx)) ~(x)($y)Fyx->(x)~Fxx';
#$str_o_wffs = '(F.G)->~(Hv~(T<->U)) [~~(F->~G)v(~H.~~(~U<->~T))]';             # This should eval to 0
#$str_o_wffs = '~~(F.~~~~G)->~(Hv~(T<->~~~~U)) ~[~~(F->~G)v~~(~H.~~(~U<->~T))]'; # This should eval to 1
#str_o_wffs = '($x)(~Gx.Fx) (x)(Hx->~Gx) ~($x)(Fx.~Hx)';
#$str_o_wffs = '~A<->B ~(A<->~B)';
#$str_o_wffs = '~(Hv<->((H.W)v(~M.~A)))';
#$str_o_wffs = '((RvH)->~T) (~(Sv~M)->(L.H)) ~(T->~(M.~S))';
#$str_o_wffs = '~[(($x)Gxa->($y)($x)(Gxy.Cy))<->(($x)Gxa->($x)($y)(Gxy.Cy))]';
#$str_o_wffs = '[(x)($y)Cxy.(x)(y)(Pxy->~Cyx)]<->[(x)(y)(Pxy->~Cyx).(x)($y)Cxy]';
#$str_o_wffs = '~[(x)($y)Cxy.(x)(y)(Pxy->~Cyx)<->(x)($y)Cxy.(x)(y)(Pxy->~Cyx)]';
#$str_o_wffs = '~[Ga<->Ga]';
#$str_o_wffs = '(x)(y)(x=y<->(z)(Pzx<->Pzy)) a=b ~m=n';

local $standalone = 0; ## note - if left as 1 this will break cgi script
local $completed_open_branch = 0;

if ($standalone) {
    require "../lib/wff-subrs.pl";
    require "../lib/qlwff-subrs.pl";
    require "../lib/header.pl";

#    my $cns = $str_o_wffs;
#    $cns =~ s/[^a-u]//g;                     # extract the constants from the wffs
#    $cns = &remove_string_dups($cns);        # remove duplicates
#    my $insts = "";

    my @foo = split(/ /,$str_o_wffs);
    print &ttree_wrapper([@foo],"","","",""),"\n";
}

###################################################################
# This wrapper interrupts &ttree if it cranks for 10 seconds
# without returning an answer.  Compliments of the Perl Cookbook...

sub ttree_wrapper {
    my $evaluation = '';    
    $SIG{ALRM} = sub {die "timeout"};
    eval {
	alarm(7);
#	alarm(100000);
	$evaluation = &ttree(@_);
	alarm(0);
    };

    if ($@ =~ /timeout/) {
	return 2;
    } else {
	return $evaluation;
    }
}


###
sub ttree {
    my $branch_ref = shift;
    my $instances_ref = shift;
    local $constants = shift;
    my $literals_ref = shift;
    my $ids_ref = shift;
    local @literals = @$literals_ref;
    local @identities = @$ids_ref;
    local $closed = 0;
    my @newbranch = ();
    my @branchers = ();
    my @nonbranchers = ();

    return 1 if &closed($branch_ref) eq "closed";
    return 0 if $completed_open_branch;

    local @branch = &sort_branch($branch_ref);
    print "branch: @branch\n" if $standalone;

    my @branchcopy = @branch;
    for $foo (@branchcopy) {                             # extract the constants from the wffs
	$foo =~ s/[^a-u]//g;
	$constants .= $foo;
    }
    $constants = &remove_string_dups($constants);        # remove duplicates

    local @instances = @$instances_ref;
    @branchcopy = @branch;
    my $wff;

    foreach $wff (@branchcopy) {

#	print "WFF: $wff\n";
	my $type = &wff($wff);
	local $added_wff = 0;
	
      CASE: 
	{
	    if ($type =~ /atomic/) {
		foreach $id (@identities) {
		    my $added_wff = &do_LeibnizLaw($wff,$id);
		}
		&ttree([@branch],[@instances],$constants,[@literals],[@identities]) and return if $added_wff;
		next CASE;
	    }
	    if ($type eq "identity") {
		push(@identities,$wff) if $wff !~ /([a-z])=\1/;
		foreach $literal (@literals) {
		    my $added_wff = &do_LeibnizLaw($literal,$wff);
		}
		&ttree([@branch],[@instances],$constants,[@literals],[@identities]) and return if $added_wff;
		next CASE;
	    }
	    if ($type eq "conjunction") {
		@branch = &remove_wff($wff,@branch);
		&ttree([@branch,&lhs($wff),&rhs($wff)],[@instances],$constants,[@literals],[@identities]);
		if (!$completed_open_branch) {return 1} else {return 0};
	    }
	    if ($type eq "disjunction") {
		@branch = &remove_wff($wff,@branch);
		&ttree([@branch,&lhs($wff)],[@instances],$constants,[@literals],[@identities]);
		&ttree([@branch,&rhs($wff)],[@instances],$constants,[@literals],[@identities]);
		if (!$completed_open_branch) {return 1} else {return 0};
	    }
	    if ($type eq "conditional") {
		@branch = &remove_wff($wff,@branch);
		&ttree([@branch,"~".&lhs($wff)],[@instances],$constants,[@literals],[@identities]);
		&ttree([@branch,&rhs($wff)],[@instances],$constants,[@literals],[@identities]);
		if (!$completed_open_branch) {return 1} else {return 0};
	    }
	    if ($type eq "biconditional") {
		@branch = &remove_wff($wff,@branch);
		&ttree([@branch,&lhs($wff),&rhs($wff)],[@instances],$constants,[@literals],[@identities]);
		&ttree([@branch,"~".&lhs($wff),"~".&rhs($wff)],[@instances],$constants,[@literals],[@identities]);
		if (!$completed_open_branch) {return 1} else {return 0};
	    }
	    if ($type eq "existential") {

		my $bar = &univ_instances_missing;
#		print "BAR: $bar\n";
		next CASE if $bar;
#		next CASE if &univ_instances_missing;
		@branch = &remove_wff($wff,@branch);
		my $newconst = &find_new_constant($constants);
		die 'timeout' if $newconst eq 'v';
		$constants .= $newconst;
		my $inst = &make_instance($wff,$newconst);
		&ttree([@branch,$inst],[@instances],$constants,[@literals],[@identities]);
		if (!$completed_open_branch) {return 1} else {return 0};
	    }
	    if ($type eq "universal") {
		if (!$constants) {
		    my $newconst = 'a';
		    $constants .= $newconst;
		    my $inst = &make_instance($wff,$newconst);
		    push @instances, $inst;
		    &ttree([@branch,$inst],[@instances],$constants,[@literals],[@identities]);
		    if (!$completed_open_branch) {return 1} else {return 0};
		}
		my $temp_constants = $constants;
		my @uni_insts = ();             # the new instances for this particular universal $wff
		while ($temp_constants) {
		    my $const = chop($temp_constants);
		    my $inst = &make_instance($wff,$const);
		    if (not &in_list($inst,@instances)) {
			push @instances, $inst;
			push @uni_insts, $inst;
		    }
		}
		if (@uni_insts) {
		    &ttree([@branch,@uni_insts],[@instances],$constants,[@literals],[@identities]);
		    if (!$completed_open_branch) {return 1} else {return 0};
		} else {next CASE;}             # skip to next formula on branch if no new instances for $wff
	    }
	    if ($type eq "negation") {
	      NEG: {
		    my $compwff = $wff;
		    $compwff =~ s/^~//;
		    my $comptype = &wff($compwff);

		    if ($comptype =~ /atomic|ident/) {
			next CASE;
		    };
		    if ($comptype eq "negation") {
			@branch = &remove_wff($wff,@branch);
			$compwff =~ s/^~//;
			push(@identities,$compwff) if &wff($compwff) =~ /ident/ and not &in_list($compwff,@identities);
			&ttree([@branch,$compwff],[@instances],$constants,[@literals],[@identities]);
			if (!$completed_open_branch) {return 1} else {return 0};
		    }
		    if ($comptype eq "conjunction") {
			@branch = &remove_wff($wff,@branch);
			&ttree([@branch,"~".&lhs($compwff)],[@instances],$constants,[@literals],[@identities]);
			&ttree([@branch,"~".&rhs($compwff)],[@instances],$constants,[@literals],[@identities]);
			if (!$completed_open_branch) {return 1} else {return 0};
		    }
		    if ($comptype eq "disjunction") {
			@branch = &remove_wff($wff,@branch);
			&ttree([@branch,"~".&lhs($compwff),"~".&rhs($compwff)],
			       [@instances],
			       $constants,
			       [@literals],[@identities]);
			if (!$completed_open_branch) {return 1} else {return 0};
		    }
		    if ($comptype eq "conditional") {
			@branch = &remove_wff($wff,@branch);
			&ttree([@branch,&lhs($compwff),"~".&rhs($compwff)],
			       [@instances],
			       $constants,
			       [@literals],[@identities]);
			if (!$completed_open_branch) {return 1} else {return 0};
		    }
		    if ($comptype eq "biconditional") {
			@branch = &remove_wff($wff,@branch);
			&ttree([@branch,&lhs($compwff),"~".&rhs($compwff)],
			       [@instances],
			       $constants,
			       [@literals],[@identities]);
			&ttree([@branch,"~".&lhs($compwff),&rhs($compwff)],
			       [@instances],
			       $constants,
			       [@literals],[@identities]);
			if (!$completed_open_branch) {return 1} else {return 0};
		    }
		    if ($comptype eq "existential") {
			@branch = &remove_wff($wff,@branch);
			&ttree([@branch,"(".&getvar($compwff).")~".&getscope($compwff)],
			       [@instances],
			       $constants,
			       [@literals],[@identities]);
			if (!$completed_open_branch) {return 1} else {return 0};
		    }
		    if ($comptype eq "universal") {
			@branch = &remove_wff($wff,@branch);
			&ttree([@branch,"(\$".&getvar($compwff).")~".&getscope($compwff)],
			       [@instances],
			       $constants,
			       [@literals],[@identities]);
			if (!$completed_open_branch) {return 1} else {return 0};
		    }
		}
	    }
	}
    }
    print "open: @branch\n" if $standalone and &closed(\@branch) ne "closed";
    if (&complete(\@branch,\@instances,$constants) and &closed(\@branch) ne "closed") {
	$completed_open_branch = 1;
	return 0;
	}
}

###
# This routine sorts a branch to put (identities and) nonbranching formulas 
# first.  This keeps branching to a minimum.  Putting literals
# last also seems to speed up the processing.

sub sort_branch {
    my $branch_ref = shift;
    my @branch = @$branch_ref;
    my @newbranch = ();
    @literals = ();                             # declared above as global
    my @nonbranchers = ();
    my @idents = ();
    my @univs = ();
    my @existentials = ();
    my @temp = ();
    local @specials = ();
    my @branchcopy = @branch;
    foreach $wff (@branchcopy) {
	my $type = &wff($wff);
      TYPES:
	{
	    if ($type =~ /univ/) {
		unshift @univs, $wff; 
		@branch = &remove_wff($wff,@branch);
	    }
	    if ($type =~ /exist/) {
		unshift @existentials, $wff; 
		@branch = &remove_wff($wff,@branch);
	    }
#	    if ($type =~ /^cond/) {
#		if (&branch_closer($wff,$type)) {
#		    push(@specials,$wff)}
#		else {
#		    push @nonbranchers, $wff;
#		}
#		@branch = &remove_wff($wff,@branch);
#	    }
	    if ($type =~ /conj/) {
		push @nonbranchers, $wff; 
		@branch = &remove_wff($wff,@branch);
	    }
	    if ($type =~ /atom|ident/) {
		push @literals, $wff; 
		@branch = &remove_wff($wff,@branch);
	    }
	    if ($type =~ /neg/) {
		my $compwff = $wff;
		$compwff =~ s/^~//;
		$type_compwff = &wff($compwff);
		if ($type_compwff =~ /neg|disj|^cond|exist|univ/) {
		    @branch = &remove_wff($wff,@branch);
		    push @nonbranchers, $wff; 
		}
		if ($type_compwff =~ /atom|ident/) {
		    push @literals, $wff; 
		    @branch = &remove_wff($wff,@branch);
		}
	    }
	    next TYPES;
	}
    }
#    push @newbranch, @specials;
    push @newbranch, @existentials;
    push @newbranch, @nonbranchers;
    push @newbranch, @branch;
    push @newbranch, @literals;
    push @newbranch, @univs;

    return @newbranch;
}

###
sub branch_closer {
    my $testwff = shift;
    my $type = shift;

    if ($type =~ /^cond/) {
	for $wff (@branch) {
	    push (@specials,$wff) if ("~$wff" eq &lhs($testwff) or $wff eq &rhs($testwff))
	    }
    }
}
    

###
sub univ_instances_missing {

#    print "BRANCH: @branch\nCONSTANTS: $constants\nINST: @instances\n";
    my $has_instance = 0;
    my $got_one = 0;

    foreach $wff1 (@branch) {
#	print "WFF1: $wff1\n";
	next if &wff($wff1) !~ /univ/;
	$got_one = 1;                    # flag to indicate there are universals in the branch
	my $temp_cons = $constants;
      CON:
	while ($temp_cons) {
	    my $const = chop($temp_cons);
#	    print "CONST: $const\n";
	    $has_instance = 0;
	    foreach $wff2 (@instances) {
#		print "WFF2: $wff2\n";
#		print "FOO: ",&isinstance($wff2,$wff1),"\n";
		if (&isinstance($wff2,$wff1) eq $const)	{$has_instance = 1; next CON};
	    }
	    return 1 if $has_instance == 0;
	}
    }
    return 0 if $has_instance == 1 or $got_one == 0;
}

###
sub in_list {
    my $wff = shift;
    my @list = @_;
    for (@list) {
	return 1 if $wff eq $_;
    }
    return 0;
}

###
sub find_new_constant {
    my $constants = shift;
    return 'a' if !$constants;
    my $con = 'a';
    while ($constants =~ /$con/) {
	++$con;
    }
    return $con;
}

###
# Simplified version -- assumes you don't nest an x-quant
# inside another x-quant, just to get functionality right...

sub make_instance {
    my ($wff,$const) = @_;
    my $var = &getvar($wff);
    $wff = &getscope($wff);
    $wff =~ s/$var/$const/g;
    return $wff;
}

###
sub remove_wff {
    my $wff = shift;
    my @branch = ();
    for (@_) {
	push @branch, $_
	    unless $_ eq $wff;
    }
    return @branch;
}

###
sub closed {
    my $branch_ref = shift;
    my @branch = @$branch_ref;
    my ($i,$j);
    my $bound = scalar(@branch);

    for ($i=0;$i<$bound;$i++) {
	
#	print "branch_i_$i: $branch[$i]\n";

	if ($branch[$i] =~ /^~\(*([a-z])=\1\)*$/) {      # close the branch if we find the form ~a=a or ~(a=a)
	    print "closed: @branch\n" if $standalone;
	    $closed = 1;
	    return "closed";
	}
	for ($j=$i+1;$j<$bound;$j++) {                  # close the branch if we find A and ~A
#	    print "branch_j_$j: $branch[$j]\n";	    
	    if ($branch[$i] eq "~".$branch[$j] or $branch[$j] eq "~".$branch[$i]) {
		print "closed: @branch\n" if $standalone;
		$closed = 1;
		return "closed"; 
	    }
	}
    }	
}


###
# Checks to see whether a branch is complete, i.e.,
# whether all boolean non-literals and all existentials
# have been decomposed and whether there is an 
# instance of every universal for every constant.

sub complete {

    my ($branch_ref,$instances_ref,$constants) = @_;
    my @branch = @$branch_ref;

    my $wff;
    my @instances = @$instances_ref;

    foreach $wff (@branch) {
	my $type = &wff($wff);
	if ($type ne "universal" and $type ne "existential") {
#	    return 0 if $wff =~ /[\.v-]|~~/
	    return 0 if ($type =~ /conj|disj|cond/ or $wff =~ /~~/);
	}
	if ($type eq "existential") {
	    my $has_instance = 0;
	    for (@branch) {
		if (&isinstance($_,$wff)) {$has_instance = 1; last} 
	    }
	    return 0 if !$has_instance;
	}
	if ($type eq "universal") {
	    my $temp_constants = $constants;
	    while ($temp_constants) {
		my $con = chop($temp_constants);
		my $has_instance = 0;
		my $inst = &make_instance($wff,$con);
		for (@instances) {
		    if ($inst eq $_) {$has_instance = 1; last}
		}
		return 0 if !$has_instance;
	    }
	}
    }
    return 1;
}

###
# This subroutine is called when an identity or atom is encountered.
# Given a wff (literal, as it happens) and an identity statement, it 
# generates all possible equivalent wffs that you get from Leibniz' Law.
# Currently this is a hack that works for wffs with no more than 2-place 
# predicates -- which is all that we need for the exercises in 9.6A.  
# Need to do something recursive if we ever need to deal with n-place
# predicates generally.

sub do_LeibnizLaw {
    my $wff = shift;
    my $id = shift;

    my $first = $id;
    my $second = $id;
    $first =~ s/^\(*(.)=.*/$1/;
    $second =~ s/^.*=(.)\)*/$1/;

    $_ = $wff;
    my $num_first = eval "tr/$first/$first/";
    my $num_second = eval "tr/$second/$second/";

    my $wff1 = $wff;
    my $wff2 = $wff;
    my $wff3 = $wff;
    my $wff4 = $wff;

    if ($num_first) {
	$wff1 =~ s/$first/$second/;
	push(@branch,$wff1) and $added_wff = 1 if not &in_list($wff1,@branch);
	if ($num_first == 2) {
	    $wff3 =~ s/($first.*)$first/$1$second/;
	    push(@branch,$wff3) and $added_wff = 1 if not &in_list($wff3,@branch);
	    $wff3 =~ s/$first/$second/;
	    push(@branch,$wff3) and $added_wff = 1 if not &in_list($wff3,@branch);
	}
    }
    if ($num_second) {
	$wff2 =~ s/$second/$first/;
	push(@branch,$wff2) and $added_wff = 1 if not &in_list($wff2,@branch);
	if ($num_second == 2) {
	    $wff4 =~ s/($second.*)$second/$1$first/;
	    push(@branch,$wff4) and $added_wff = 1 if not &in_list($wff4,@branch);
	    $wff4 =~ s/$second/$first/;
	    push(@branch,$wff4) and $added_wff = 1 if not &in_list($wff4,@branch);
	}
    }
    return $added_wff;
}

1;
