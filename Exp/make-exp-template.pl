#!/usr/bin/perl -w
# make-exp-template.pl
# Chris Menzel 17 Dec 98
# Builds an abbreviated truth table template (from an expansion)

sub make_exp_template {

    local ($pred_arg,$atomic_wffs) = @_;
    my $pred_arg = &local_prettify_arg($pred_arg);

    local $spaces = &get_spaces($pred_arg);
    local $dashes;
    for ($i=1;$i<=length($atomic_wffs);$i++) {
	$dashes .= "-";
    }
    $dashes .= "|";  # that's a vertical bar
    for ($i=1;$i<=length($pred_arg)+1;$i++) {
	$dashes .= "-";
    }
    local $spaces_with_vertbar = &get_spaces($pred_arg);
#    $spaces_with_vertbar = &get_spaces($atomic_wffs) . "|" . $spaces;
    $spaces_with_vertbar = &get_spaces($atomic_wffs) . "| ";
    local $spaces = $spaces_with_vertbar;
    $spaces =~ tr/|/ /;

    local $exp_template = "$atomic_wffs\| $pred_arg\n$dashes\n$spaces_with_vertbar\n$spaces\n$spaces\n$spaces\n";
    return $exp_template;
}

### returns a string of spaces the length of pseq

sub get_spaces {
    local $spaces;
    $_ = $_[0];
    while ($_) {
	$spaces .= " ";
	chop;
    }
    return $spaces;
}

### extract the atoms from the sequent (eliminating duplicates)

sub extract_atoms {

    local $atoms = $_[0];
    $atoms =~ s/[^A-Z]//g;
    $atoms =~ s/([A-Z])/$1 /g;
    local @atoms = split(/ /,$atoms);
    $atoms = "";
    foreach $atom (@atoms) {
	$_ = $atoms;
	next if eval("tr/$atom/$atom/");
	$atoms .= "$atom ";
    }
    return $atoms;
}

### return prettified string of formulas in the sequent

sub local_prettify_arg {
    my ($arg) = @_;
    $arg =~ s/([^: ])\. /$1  /g;                      # remove delimiter dots
    $arg =~ s/([^:])([\.v]|->|<->)([^:])/$1 $2 $3/g;  # add spaces b/w binary connectives
    return $arg;
}

1;
