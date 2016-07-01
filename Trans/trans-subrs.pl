#!/usr/bin/perl -w
# trans-subrs.pl
# Subroutines for checking symbolizations before they are actually tested
# for logical equivalence with the canned symbolization and for
# translating PoL wff into Prover9 wffs to be tested for logical truth

require "../lib/wff-subrs.pl";
require "../lib/qlwff-subrs.pl";
require "../lib/header.pl";

######################### STANDALONE TESTING AREA #########################

my $standalone = 0;

# Test PoL WFFs
#
# my $wff = 'Dk.Gkk';
my $wff = '(x)~(Qab.~Pab)->Sabc';
# my $wff = '($x)($y)(~x=y.(z)(~~z=xv~~z=y))';
# my $wff = '(($x)~(Qab.~Pxy)->(Rabzw<->~(Rzwba v ~Qwz)))';
# my $wff = '(((x)($y)Cyx.(x)(y)(Pxy->~Cyx))<->(x)Px)';
# my $wff = 'C->((B.~A)v(C.(B->(AvC))))';
# my $wff = '($x)[(y)~(Ab.~Pxy)->(w)(($z)Rbzw<->~($z)(Rzwba v ~Qwz))].Ac';
# my $wff = '~(Qab.~Pxy)->(Rabcd<->~(Rdcba v ~Qba))';
my $trans = '~(Qab.~Pab)->Sabc';
my $utrans = '~Pab->(Qab.(x)~Pab)';
# my $wff ='(x)(Mx -> ($y)(y=b.Ay))';
# my $wff = '~(Qab.~Pxy)->(Rabcd<->~(Rdcba v ~Qba))';
# my $wff = '(x)[(Lxv(w)(y)(z)~(Awyz.~Awyz))->~(y)(z)((Py.Sz)->Axzy)]';
# my $wff = '(($x)~(Qab.~Pxy)->(Rabzw<->~(Rzwba v ~Qwz)))';
# my $wff = '($x)[(y)~(Qab.~Pxy)->(w)(($z)Rabzw<->~($z)(Rzwba v ~Qwz))]';
# my $wff = '(((x)($y)Cyx.(x)(y)(Pxy->~Cyx))<->(x)Px)';
# my $wff = '(($x)~(Qab.~Pxy)->(Rabzw<->~(Rzwba v ~Qwz)))';
# my $wff = '(((x)($y)Cyx.(x)(y)(Pxy->~Cyx))<->(x)Px)';
# my $wff = 'C->((B.~A)v(C.(B->(AvC))))';
# my $wff = '($x)[(y)~(Ab.~Pxy)->(w)(($z)Rbzw<->~($z)(Rzwba v ~Qwz))].Ac';
# my $wff = '~(Qab.~Pxy)->(Rabcd<->~(Rdcba v ~Qba))';
# my $trans = '~(Qab.~Pab)->Sabc';
# my $utrans = '~Pab->(Qab.~Pab)';
# my $trans = '($x)((Wxse.(y)(Wyse->x=y)).Ox)';
# my $utrans = '($x)((Wxse.(y)(Wyse->x=y)).Ox)';
# my $wff ='(x)(Mx -> ($y)(y=b.Ay))';
# my $wff = '[(Em.Ec)->(x)(y)((Ex.Ey)->x=y)]<->[(Em.Ec)->~~(x)(y)~((Ex.Ey).~x=y)]';
# my $wff = '[[(z)~Cz v (z)(Dzz->~Ez)] . [($x)Fx->(y)(Gy->Ey)]] -> [~(x)(Gx->~Dxx)->(x)(Cw->~Fw)]';

# print &overloaded_pred($wff),"\n"
# print &preds_in_wff($trans),"\n"
# print &extraORmissing_pred($trans,$utrans),"\n"
# print &atomic_subwffs($trans),"\n"
# print &extraORmissing_cons($trans,$utrans),"\n"
# print &constants_in_wff($wff),"\n"
# print &vacuous_quant($trans,$utrans),"\n"
# print &pol2p9($wff),"\n"
#    if ($standalone);

####################### END STANDALONE TESTING AREA #######################

# Checks to make sure the user's symbolization (i) does not contain any extraneous
# predicates and (ii) contains all the predicates in the scheme of abbreviation 
sub extraORmissing_pred {
  my ($trans,$utrans) = @_;
  my $trans_preds = &preds_in_wff($trans);
  my $utrans_preds = &preds_in_wff($utrans);

  return 0 if $trans_preds eq $utrans_preds;
  @trans_preds = split(//,$trans_preds);
  @utrans_preds = split(//,$utrans_preds);
  foreach $pred (@utrans_preds) {
    return "$pred is extra"
      if !grep(/$pred/,@trans_preds);
    }
  foreach $pred (@trans_preds) {
    return "$pred is missing"
      if !grep(/$pred/,@utrans_preds);
    }
  return 0;
}      

# Checks to make sure the user's symbolization (i) does not contain any extraneous
# constants and (ii) contains all the constants in the scheme of abbreviation 
sub extraORmissing_cons {
  my ($trans,$utrans) = @_;
  my $trans_constants = &constants_in_wff($trans);
  my $utrans_constants = &constants_in_wff($utrans);

  return 0 if $trans_constants eq $utrans_constants;
  @trans_constants = split(//,$trans_constants);
  @utrans_constants = split(//,$utrans_constants);
  foreach $cons (@utrans_constants) {
    return "$cons is extra"
      if !grep(/$cons/,@trans_constants)
    }
  foreach $cons (@trans_constants) {
    return "$cons is missing"
      if !grep(/$cons/,@utrans_constants)
    }
  return 0;
}      

# Checks to make sure $wff contains no "overloaded" predicates, i.e.,
# no predicates serving as both m- and n-place predicates, for m != n
sub overloaded_pred {
  my $wff = shift;
  my $atwffs = &atomic_subwffs($wff);

  chop $atwffs;                         # chop that trailing space
  @atwffs = split(' ',$atwffs);
  while (@atwffs) {
    my $wf1 = pop @atwffs;
    next if &wff($wf1) =~ /identity/;   # Might wanna remove identities from value of &atomic_subwffs
    my $wf1_pred = substr($wf1,0,1);
    foreach $wf2 (@atwffs) {
      next if &wff($wf2) =~ /identity/; # Might wanna remove identities from value of &atomic_subwffs
      my $wf2_pred = substr($wf2,0,1);
      next if $wf1_pred ne $wf2_pred;
      return "$wf1_pred"                # return the first overloaded pred found
	if length($wf1) != length($wf2);
    }
  }
  return 0;
}

# Checks to make sure the user's symbolization does not contain any 
# vacuous quantifiers in symbolizations that are naturally translated
# without them. (Does not do a general check for vacuous quantifiers;
# such a check is probably impossible.)
sub vacuous_quant {
  my ($trans,$utrans) = @_;
  return 0
    if $trans =~ /\(\$*[u-z]\)/;
  return 0
    unless $utrans =~ /\(\$*[u-z]\)/;
  my $quant = "$utrans";
  $quant =~ s/.*(\(\$*[u-z]\)).*/\1/;
  return "$quant is vacuous"
    if $quant;
  return 0;
}
  
# Returns a nonredundant string of the preds that occur in a wff in
# alphabetical order
sub preds_in_wff {
  my $wff = shift;
  my $preds = &atomic_subwffs($wff);

  $preds =~ s/[a-z=\s]//g;   # remove constants, variables, = (hence identities) and white space
  $preds = join('',sort(split(//,$preds)));
  $preds =~ s/(\w)\1+/$1/g;  # remove duplicates
  return $preds;
}  

# Returns a nonredundant string of the constants that occur in a wff in
# alphabetical order
sub constants_in_wff {
  my $wff = shift;
  my $constants = &atomic_subwffs($wff);

  $constants =~ s/[v-zA-Z=\s]//g;   # remove variables, predicates, =, and white space
  $constants = join('',sort(split(//,$constants)));
  $constants =~ s/(\w)\1+/$1/g;  # remove duplicates
  return $constants;
}

# Returns a space-delimited string of the atomic subwffs in $wff
# (Trailing space might well need to be chopped if you use this)
sub atomic_subwffs {
    my $wff = shift;
    my $type = &wff($wff);

#     if ($type =~ /identity/) {
# 	return "";
#     }

    if ($type =~ /atomic|identity/) {
	return "$wff ";
    }

    if ($type =~ /negation/) {
	return &atomic_subwffs(substr($wff,1));
    }

    if ($type =~ /conj|disj|cond/) {
	return &atomic_subwffs(&lhs($wff)) . &atomic_subwffs(&rhs($wff));
    }

    if ($type =~ /univ|exist/) {
	my $body = &getscope($wff);
	return &atomic_subwffs($body);
    }
}

sub pol2p9 {
    my $polwff = shift;

    my $p9wff = '';
    my $type = &wff($polwff);
#    print "TYPE: $type\n";

    if ($type =~ /atomic/) {
	my @polwff = split(//,$polwff);
	my $pred = shift @polwff;
	my $args = join(',',@polwff);
	return $pred if !$args;   # Don't wanna add parens if $polwff is a statement letter
	return $pred . "($args)";
    }

    if ($type =~ /identity/) {
      return "$polwff";
    }

    if ($type =~ /negation/) {
      my $subwff = &pol2p9(substr($polwff,1));
#      return "(-" . $subwff . ")"
      return "-" . $subwff
	unless &wff($subwff) =~ /identity/;
      $subwff =~ s/(.*)/-($1)/;
      return $subwff;
    }

    if ($type =~ /conjunction/) {
	return "(" . &pol2p9(&lhs($polwff)) . ' & ' . &pol2p9(&rhs($polwff)) . ")";
    }

    if ($type =~ /disjunction/) {
	return "(" . &pol2p9(&lhs($polwff)) . ' | ' . &pol2p9(&rhs($polwff)) . ")";
    }

    if ($type =~ /biconditional/) {
	return "(" . &pol2p9(&lhs($polwff)) . ' <-> ' . &pol2p9(&rhs($polwff)) . ")";
    }

    if ($type =~ /conditional/) {
	return "(" . &pol2p9(&lhs($polwff)) . ' -> ' . &pol2p9(&rhs($polwff)) . ")";
    }

    if ($type =~ /universal/) {
	my $var = &getvar($polwff);
	my $body = &getscope($polwff);
	return "(all $var " .  &pol2p9($body) .  ")";
    }

    if ($type =~ /existential/) {
	my $var = &getvar($polwff);
	my $body = &getscope($polwff);
	return "(exists $var " .  &pol2p9($body) .  ")";
    }
}

1;
