#!/usr/bin/perl -w

# This code takes an uglified TT as input
# and yield a nicely formatted one as output.

my $user_tt = "";
my $rows = "";
my @rows = ();
my @tvas = ();

while (<>) {
    next if /^\s*$/;
    $user_tt .= $_;
}

chomp $user_tt;
@user_tt = split(/\n/,$user_tt);

my $row1;
for (@user_tt) {
    next if /^\s*$|--/;
    s/\s*//g;
    $row1 = $_ and next if /[~\.v>:]/;
#    $dashes = $_ and next if /--/;
    push @rows, $_;
    /^(.*)\|(.*)$/;
    push @tvas, $1;
    push @tvs, $2;
}

my $argument = $row1;
$argument =~ s/^(.*)?\|(.*)$/$2/;
my $atoms = $1;
$rows = join("\n",@rows);
$tt = "$row1\n$rows";
print "TT:\n$tt\n";
my @argument = split(/,|:\.|\.:/,$argument);
my $prepared_arg = &prepare_arg(@argument);

print "PREP_ARG: $prepared_arg\n";

$pretty_atoms = $atoms;
$pretty_atoms =~ s/([A-Z])/$1 /g;
$pretty_arg = &prettify_arg(@argument);
$pretty_row1 = "$pretty_atoms\|$pretty_arg";
$dashes = "-" x length($pretty_atoms);
$dashes .= "\|-" . ("-" x length($pretty_arg));
$pretty_tt = "$pretty_row1\n$dashes\n";

#print "PRETTY_TT:\n$pretty_tt\n";
#exit;

# Code is missing here for actually putting the TTs where they belong
# in each row.


### AUXILIARY SUBROUTINES ###

# creates an arg template using process wff

sub prepare_arg {

    my @prepared_arg = @_;
    @prepared_arg = map &process_wff($_), @prepared_arg;
    $conclusion = pop @prepared_arg;
    $premises = join(', ',@prepared_arg);
    return "$premises :. $conclusion";
}

# This routine takes a wff and replaces all locations underneath
# which a TV should occur with a ^ (viz., lone statements letters
# and connectives

sub process_wff {
    shift;

    # Replace sentence letter standing alone with ^
    s/[A-Z]/\^/ and return $_
      if $_ =~ /^[A-Z]$/;

    # prettify wff and replace connectives with ^
    $_ = &prettify_wff($_);
    s/[-~\.v]/\^/g;
    return $_;
}

sub prettify_wff {
    print "\@_1: @_\n";
    my $pretty_wff = shift;
    $pretty_wff =~ s/([\.v]|[^<]->|<->)/ $1 /g;
    print "PRETTY_WFF: $pretty_wff\n";
    return $pretty_wff;
}

sub prettify_arg {
    print "\@_: @_\n";
    my $conclusion = pop;
    my $pretty_conclusion = &prettify_wff($conclusion);
    my @pretty_prems = @_;
    print "\@PREMS1: @pretty_prems\n";
    @pretty_prems = map &prettify_wff($_), @pretty_prems;
    my $pretty_premises = join(', ',@pretty_prems);
    print "\$PRETTY_PREMS: $pretty_premises\n";
    my $pretty_arg = "$pretty_premises :. $pretty_conclusion";
    print "PRETTY_ARG: $pretty_arg\n";
    return $pretty_arg;
}
