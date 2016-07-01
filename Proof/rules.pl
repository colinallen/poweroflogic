#!/usr/bin/perl -T

# rules.pl
# Subroutines to support proofcheck.pl

# renamed by CA Sep 24, 1998
# original rules.pl became impl-rules.pl

# this file is for general loading of items required for all
# for all rule types to work

#require "../lib/header.pl";
require "../Proof/errors";
require "../Proof/impl-rules.pl";
require "../Proof/equiv-rules.pl";
require "../Proof/ql-rules.pl";

# ONLY RULES RETURNING A TRUE VALUE FROM THIS HASH WILL BE EVALUATED
# we'll also use this to canonize the form
%implemented = ('ASSUME'=>'Assume',
		# Implicational Rules
		'MP'=>'MP',
		'MT'=>'MT',
		'HS'=>'HS',
		'DS'=>'DS',
		'CD'=>'CD',
		'SIMP'=>'Simp',
		'CONJ'=>'Conj',
		'ADD'=>'Add',
		# Equivalence Rules
		'DN'=>'DN',
		'COM'=>'Com',
		'AS'=>'As',
		'DEM'=>'DeM',
		'CONT'=>'Cont',
		'DIST'=>'Dist',
		'EX'=>'EX',
		'RE'=>'Re',
		'ME'=>'ME',
		'MI'=>'MI',
		'CP'=>'CP',
		'RAA'=>'RAA',
		# Predicate Rules
		'UI'=>'UI',
		'UG'=>'UG',
		'EI'=>'EI',
		'EG'=>'EG',
		'QN'=>'QN',
		# Identity Rules
		'LL'=>'LL',
		'SM'=>'SM',
		'ID'=>'ID',
		# Modal Rules
		# 'NE'=>0,
		# 'EP'=>0,
		# 'TN'=>0,
		# 'MN'=>0,
		);

%rule_aliases = (
		 'MPP'=>'MP',
		 'MTT'=>'MT',
		 'COMM'=>'COM',
		 'DM'=>'DEM',
		 'TRANS'=>'CONT',
		 'DIL'=>'CD',
		 'EXP'=>'EX',
		 );

############################################################
# Rule support subroutines - should perhaps be in subr file?
############################################################

# CONVERTS A PREMISE STRING SUCH AS "5-7,4,1-3"
# TO A COMMA SEPARATED STRING "5,6,7,4,1,2,3"
sub conv_prem_ranges {
    my ($in) = @_;
    while ($in =~ /(\d\d?)-(\d\d?)/) {
	if ($2-$1<=1) {
	    $in =~ s/-/,/;
	} else {
	    my $x = $1;
	    my $y = $x+1;
	    $in =~ s/\d\d?-/$x,$y-/;
	}
    }
    return $in;
}

# EXPECTS A STRING OF COMMA-DELIMITED PREMISE NUMBERS, E.G. "1,2,3"
# RETURNS A LIST OF SENTENCES REPRESENTING THE PREMISES AT THOSE LINES
sub get_prems {
    my($pnums)=@_;
    my @prems;
    while($pnums){
	($curr,$pnums) = split(/,/,$pnums,2);
	push @prems,&add_outer_parens(&get_linesent($proof[$curr-1]));
    }
    return @prems;
}

1; # required by require



