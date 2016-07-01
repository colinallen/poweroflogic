# wff-subrs.pl
#  subroutines in this file can be included in applications that need them

# Sentential and Predicate wff checker
#   Version 1.1: CA 12/09/10
#       - addition for 4e ch9 convention to allow conjunctions and
#         disjunctions to drop parentheses at top level
#   Version 1.0: CA 02/16/03
#       - made lhs and rhs subroutines gatekeepers to
#         get_lhs and get_rhs and now cache subformulas of
#         binary formulas during wff subroutine
#   Version 0.9: Colin Allen 10/03/98
#       - added debracket and samewff routines to handle
#         equivalent but different parenthesis patterns
#       - explicitly remove spaces in wff, lhs, and rhs
#         to handle bad input
#       - added identity type
#   Version 0.6: Colin Allen 07/15/98
#       - added support for [] and <>
#   Version 0.5: Colin Allen 07/10/98
#       - moved main function to &iswff and wrote new wrapper
#       - &wff now tests both forms with and without outer parens
#   Version 0.4: Colin Allen 07/03/98
#       - split off command line oriented code leaving subroutines only
#   Version 0.3: Colin Allen 07/03/98
#       - &add_outer_parens will add dropped parens if needed
#       - allow dropped outer parens, but outside wff subroutine
#         is this the best approach?
#       - reinstated vacuous quantification
#   Version 0.2: Colin Allen 07/03/98
#       - eliminated vacuous quantification
#       - added support for square brackets
#   Version 0.1: Colin Allen 07/03/98
use utf8;
%WFFCACHE = ();
$wffdebug = 0;

# ch9 relaxation on conjunctions and disjunctions
# only turn this on for testing
# otherwise let header.pl do it automagically
$longjunctions = 0; 

sub wff {
    my ($form,$ch9) = @_;
    ++$longjunctions if $ch9; # another way to activate the relaxation
    return (&iswff($form) || &iswff("($form)"));
}

# PRIMARY WFF-CHECKER SUBROUTINE
# You should not need to call this routine directly
# But if you do, it assumes outside parens in place
sub iswff {
    my ($form) = @_;
    $form = &canonize($form);
    print "Checking $form $ch9\n" if $wffdebug;
    
    if (defined $WFFCACHE{$form}{'type'}) {
	return $WFFCACHE{$form}{'type'};
    }
    
    # NULL STRING
    if ($form eq "")
    { print "no $form\n" if $wffdebug;
      return 0; }

    # UNCOMMENT if SENTENCE LETTER (V IS EXCLUDED)
#    elsif ($form =~ /^[A-UW-Z]$/)
    elsif ($form =~ /^[A-Z]$/)
    { $WFFCACHE{$form}{'type'} = 'atomic';
      return "atomic"; }

    # PRED-ATOMIC - free variables allowed
    elsif ($form =~
#	   /^[A-UW-Z][a-uw-z]+$/)           # Faz etc.
	   /^[A-Z][a-z]+$/)           # Faz etc.
    { $WFFCACHE{$form}{'type'} = 'predicate atomic';
      return "predicate atomic"; }

    # IDENTITY - free vars allowed (a=z) etc
    elsif ($form =~
#	   /^\([a-z]=[a-z]\)$|^\[[a-z]=[a-z]\]$/)
	   # parens dropped for second edition
	   /^[a-z]=[a-z]$/)
    { $WFFCACHE{$form}{'type'} = 'identity';
      print "identity $form\n" if $wffdebug;
      return "identity"; }

    # NEGATION
#    elsif ($form =~ /^[-~](.+)/              # negation of
    elsif ($form =~ /^[~](.+)/                # negation of
	   && &iswff($1))                # well formed thing
    { $WFFCACHE{$form}{'type'} = 'negation';
      return "negation"; }

    # UNIVERSAL
#    elsif ($form =~ /^\(([v-z])\)(.*\1.*)$/ # use this if no vacuous quantification allowed
    elsif ($form =~ /^\(([v-z])\)(.+)$/      # use this if vacuous quantification allowed
	   && &iswff($2)
	   )
    { $WFFCACHE{$form}{'type'} = 'universal';
      return "universal"; }

    # EXISTENTIAL
#    elsif ($form =~ /^\(\$([v-z])\)(.*\1.*)$/ # use this if no vacuous quantification allowed
    elsif ($form =~ /^\(\$([v-z])\)(.+)$/      # use this if vacuous quantification allowed

	   && &iswff($2))
    { $WFFCACHE{$form}{'type'} = 'existential';
      return "existential"; }

    # BINARY
    elsif ($form =~ /^\((.+)\)$|^\[(.+)\]$/
	   && &iswff(my $lhs = &get_lhs($form))
	   && &iswff(my $rhs = &get_rhs($form)))
    { $WFFCACHE{$form}{'type'} = &connective($form);
      $WFFCACHE{$form}{'lhs'} = $lhs;
      $WFFCACHE{$form}{'rhs'} = $rhs;
      return $WFFCACHE{$form}{'type'}; }

    # MODAL
    elsif ($form =~ /^(\[\]|\<\>)(.+)$/
	   && &iswff($2)) {
	if ($1 =~ /\[\]/) {
	    $WFFCACHE{$form}{'type'} = 'necessity';
	    return "necessity";
	} else {
	    $WFFCACHE{$form}{'type'} = 'possibility';
	    return "possibility";
	}
    }

    #EXTENDED DIS-/CON-JUNCTIONS (Ch9) 
    elsif ($longjunctions
	   && &longjunction($form))
    {
	# cache is filled in by longjunction subroutine
	return $WFFCACHE{$form}{'type'};
    }
    
    # FAILURE
    else
    { $WFFCACHE{$form}{'type'} = 0;
      print "unknown $form\n" if $wffdebug;
      return 0; }
}

sub longjunction {
    my ($form) = @_;
    return 0 unless  # must be at least two -junction connectives of the same type
	($form =~ /\.[^\.]+\./
	 || $form =~ /v[^\.]+v/);
	
    for ($i=0;$i<length($form);++$i) {
	$char = substr($form,$i,1);
	++$parendepth && next if $char eq '(';
	--$parendepth && next if $char eq ')';

	++$bracketdepth && next if $char eq '[';
	--$bracketdepth && next if $char eq ']';
	
	if ($parendepth+$bracketdepth == 0) { 
	    if (($char eq 'v') || ($char eq ".")) {
		# found a top level -junction connective that needs outer parens
		$form = "($form)";
		last;
	    }
	}
    }

    my $lhs = &get_lhs($form);
    my $rhs = &get_rhs($form);
    my $type = &connective($form);
    my $rtype = &iswff("($rhs)");

    print ">>>>longjunctionville with $form : $type lhs $lhs rhs $rhs rtype $rtype\n" if $wffdebug;
    
    if ($type =~ /junction/
	&& $type eq $rtype) { # only disjunctions and conjunctions can stretch
	$WFFCACHE{$form}{'type'} = $type;
	$WFFCACHE{$form}{'lhs'} = $lhs;
	$WFFCACHE{$form}{'rhs'} = $rhs;
	return $type;
    } else {
	return 0;
    }
    
}

# SUBROUTINE TO PULL OUT LEFT HAND SIDE OF BINARY FORMULA
sub lhs {
    my ($form) = @_;
    $form = &canonize($form);
    $form = &add_outer_parens($form);
    return &get_lhs($form);
}

sub get_lhs {
    my ($form) = @_;

    if (defined $WFFCACHE{$form}{'lhs'}) {
	return $WFFCACHE{$form}{'lhs'};
    }
    print "finding lhs of $form\n" if $wffdebug;

    # IDENTITY
    if ($form =~ /^([a-z])=[a-z]$/) {
	$WFFCACHE{$form}{'lhs'} = $1;
	return $WFFCACHE{$form}{'lhs'};
    }
    
    my $parendepth = 0;
    my $i;
    my $bracketdepth = 0;

    for ($i=0;$i<length($form);++$i) {
	$char = substr($form,$i,1);
	++$parendepth && next if $char =~ /\(/;
	--$parendepth && next if $char =~ /\)/;
	
	++$bracketdepth && next if $char =~ /\[/;
	--$bracketdepth && next if $char =~ /\]/;
	
	if ($parendepth+$bracketdepth == 1) { # no need to check deeper
	    # DISJUNCTION
	    if ($char eq 'v') {
		print "could be disjunction\n" if $wffdebug;
		print substr($form,$i+1,3) . " what's this?\n" if $wffdebug;
		if (substr($form,$i+1,1) =~ /[A-Z\(\)\[\]~=]/
		    or substr($form,$i+1,3) =~ /[a-z]=[a-z]/) {
		    $WFFCACHE{$form}{'lhs'}=substr($form,1,$i-1);
		    return $WFFCACHE{$form}{'lhs'};
		}
	    }
		
		
	    # CONJUNCTION
	    if ($char eq ".") {
		$WFFCACHE{$form}{'lhs'}=substr($form,1,$i-1);
		return $WFFCACHE{$form}{'lhs'};
	    }
	    
	    # BICONDITIONAL
	    elsif (substr($form,$i,3) eq "<->") {
		$WFFCACHE{$form}{'lhs'} = substr($form,1,$i-1);
		return $WFFCACHE{$form}{'lhs'};
	    }
	    
	    # CONDITIONAL
	    elsif (substr($form,$i,2) eq "->") {
		$WFFCACHE{$form}{'lhs'} = substr($form,1,$i-1);
		return $WFFCACHE{$form}{'lhs'};
	    }
	}
    }
    print "here $form no lhs\n" if $wffdebug;
    return 0; # NO LHS
}

# SUBROUTINE TO PULL OUT RIGHT HAND SIDE OF BINARY FORMULA
sub rhs {
    my ($form) = @_;
    $form = &canonize($form);
    $form = &add_outer_parens($form);
    return &get_rhs($form);
}

sub get_rhs {
    my ($form) = @_;

    print "finding rhs of $form\n" if $wffdebug;

    if (defined $WFFCACHE{$form}{'rhs'}) {
	return $WFFCACHE{$form}{'rhs'};
    }

    # IDENTITY
    if ($form =~ /^[a-z]=([a-z])$/) {
	$WFFCACHE{$form}{'rhs'} = $1;
	return  $WFFCACHE{$form}{'rhs'};
    }

    my $parendepth = 0;
    my $i;
    my $bracketdepth = 0;

    for ($i=0;$i<length($form);++$i) {
	$char = substr($form,$i,1);
	++$parendepth && next if $char =~ /\(/;
	--$parendepth && next if $char =~ /\)/;

	++$bracketdepth && next if $char =~ /\[/;
	--$bracketdepth && next if $char =~ /\]/;
	
	if ($parendepth+$bracketdepth == 1) { # no need to check deeper
	    # DISJUNCTION
	    # print "could be disjunction\n" if $wffdebug;
	    print substr($form,$i+1,3) . " what's this?\n" if $wffdebug;
	    if ($char eq 'v') {
		if (substr($form,$i+1,1) =~ /[A-Z\(\)\[\]~=]/
		    or substr($form,$i+1,3) =~ /[a-z]=[a-z]/) {
		    $WFFCACHE{$form}{'rhs'} =
			substr($form,$i+1,length($form)-($i+2));
		    return  $WFFCACHE{$form}{'rhs'};
		}
	    }
	    
	    # CONJUNCTION
	    if ($char eq '.') {
		$WFFCACHE{$form}{'rhs'}= substr($form,$i+1,length($form)-($i+2));
		return  $WFFCACHE{$form}{'rhs'};
	    }
	    
	    # BICONDITIONAL
	    elsif (substr($form,$i,3) eq "<->") {
		$WFFCACHE{$form}{'rhs'} = substr($form,$i+3,length($form)-($i+4));
		return  $WFFCACHE{$form}{'rhs'};
	    }
	    
	    # CONDITIONAL
	    elsif (substr($form,$i,2) eq "->") {
		 $WFFCACHE{$form}{'rhs'}=substr($form,$i+2,length($form)-($i+3));
		 return  $WFFCACHE{$form}{'rhs'};
	     }
	}
    }
    print "here $form no rhs\n" if $wffdebug;
    return 0; # NO RHS
}

# SUBROUTINE TO DETERMINE TYPE OF BINARY FORMULA
# EXPECTS TO BE PASSED A BINARY FORMULA
# RETURNS STRING WITH NAME OF CONNECTIVE    
# Note - this routine assumes that you have
#        outer parentheses in place
sub connective {
    my ($form) = @_;
    $form = &canonize($form);

    my $i;
    my $parendepth = 0;
    my $bracketdepth = 0;

    for ($i=0;$i<length($form);++$i) {
	$char = substr($form,$i,1);
	++$parendepth && next if $char =~ /\(/;
	--$parendepth && next if $char =~ /\)/;

	++$bracketdepth && next if $char =~ /\[/;
	--$bracketdepth && next if $char =~ /\]/;
	
	if ($parendepth+$bracketdepth == 1) { # no need to check deeper
	    print "check if $char is connective in $form\n" if $wffdebug;
	    # DISJUNCTION
	    if ($char eq 'v' # we need to make sure it's not a term
		and (substr($form,$i+1,1) =~ /[A-Z\(\)\[\]~]/ 
		     or substr($form,$i+1,3) =~ /[a-z]=[a-z]/))
	    { return "disjunction"; }

	    # CONJUNCTION
	    if ($char eq '.')
	    { return "conjunction"; }

	    # BICONDITIONAL
	    elsif (substr($form,$i,3) eq "<->")
	    { return "biconditional"; }

	    # CONDITIONAL
	    elsif (substr($form,$i,2) eq "->")
	    { return "conditional"; }
	}
    }
    print "$form not binary\n" if $wffdebug;
    return 0; # not a binary wff
}

# ADDS OUTER PARENS IF DROPPED
sub add_outer_parens {
    my ($form) = @_;
    return $form if &iswff($form);
    return "($form)" if &iswff("($form)");
    return $form; # don't modify non wffs
}

# STRIPS OUTER PARENS OR BRACKETS IF PRESENT
sub strip_outer_parens {
    my ($wff) = @_;
    return $wff if &wff($wff) !~ /disj|conj|cond/;

    my $tmpwff = $wff;
    $tmpwff =~ s/^\[/\(/;
    $tmpwff =~ s/\]$/\)/;
    $tmpwff =~ s/^\((.*)\)$/$1/;
    $wff = $tmpwff if &wff($tmpwff);
    return $wff;
}


sub debracket {
    my ($form) = @_;
    $form =~ s/\[/\(/g;
    $form =~ s/\]/\)/g;
    return $form;
}

sub samewff {
    my ($wf1,$wf2) = @_;
    
    return (&debracket(&add_outer_parens($wf1)) eq
	    &debracket(&add_outer_parens($wf2)));
}

sub samearg {
    my ($arg1,$arg2) = @_;
    $arg1 =~ s/\s//g;
    $arg2 =~ s/\s//g;

    my ($prems1,$conc1) = split(/:\.|\.:/,$arg1);
    my ($prems2,$conc2) = split(/:\.|\.:/,$arg2);
    return 0 unless &samewff($conc1,$conc2);

    # remove any extraneous commas at end of premises
    $prems1 =~ s/,\s*$//; 
    $prems2 =~ s/,\s*$//;
    my @prems1 = sort split(/,/,$prems1);
    my @prems2 = sort split(/,/,$prems2);
    return 0 unless $#prems1 == $#prems2;

    my $i;
    for ($i=0;$i<@prems1;++$i) {
	return 0 unless &samewff($prems1[$i],$prems2[$i]);
    }
    return 1;
}

sub canonize {
    my ($form) = @_;
    $form =~ s/[^!-~]+//g; # get rid of any non-typable or high bit characters
    # print STDERR "checking '$form'\n";
# place to deal with alternative connectives but requires more work
#    $form =~ s/-([^>])/~$1/g;
#    $form =~ s/&/\./g;
    return $form;
}

sub utf2ascii {
    my ($string) = @_;
    # $string =~ s///g;  # template for character conversion
    $string =~ s/\x{2192}/->/g;
    $string =~ s/\x{2194}/<>/g;
    $string =~ s/\x{2228}/v/g;
    $string =~ s/\x{2203}/\$/g;
    $string =~ s/\x{2219}/\./g;
    $string =~ s/\x{2234}/\.:/g;
    return $string;
}

use HTML::Entities;

sub ascii2utf_html {
    my ($string) = @_;
	$string =~ s/&nbsp;/ /g; #otherwise &nbsp; will turn into &amp;nbsp;
    return encode_entities(ascii2utf($string));
}

sub ascii2utf {
    my ($string) = @_;
    # $string =~ s///g;  # template for character conversion
    $string =~ s/<>|<->|</\x{2194}/g;
    $string =~ s/->|>/\x{2192}/g;
    $string =~ s/v/\x{2228}/g;
    $string =~ s/\$/\x{2203}/g;
    $string =~ s/\.:|:\./\1\x{2234}/g;
    $string =~ s/([^\d])\./\1\x{2219}/g;

    
    return $string;
}

1;          # required by require
