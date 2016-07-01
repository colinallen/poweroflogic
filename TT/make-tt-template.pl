#!/usr/bin/perl -w
# make-tt-template.pl
# Chris Menzel 30 Sept 98
# Builds a truth table template from a sequent

### Uncomment to use as standalone

my $standalone = 0;

if ($standalone) {
    $type = 'tt';

    $seq = "A->C,B->D,~C.~D:.~Av~B";        # test sequents
    #$seq = "(A->C).(B->D).(~C.~D):.(~Av~B)";        # test sequents
    #$seq = "(A -> C). (B -> D). (~C . ~D) :. (~A v ~B)";        # test sequents
    #$seq = "(D<->(EvC)). (~D.G). ~((AvF)<->G) :. ~C";  
    #$seq = ":. (AvB)";
    #$seq = ":. (P->Q)";
    $seq = "(B -> [~(A . B) -> A])";
    print &make_tt_template($seq) and exit if $type eq 'tt';
    print &make_att_template($seq);
}

### construct the TT template

sub make_tt_template {

    local ($arg) = @_;
    $arg =~ s/\s+([\.v]|->|<->)\s+/$1/g;   # puts argument into probfile format if user has rolled her own
    $arg =~ s/\s*$//;  # remove extraneous EOL spaces from probfile (should be unnecessary)

    local $atoms = &extract_atoms($arg);
#    local @atoms = sort(split(/ /,$atoms));
    local @atoms = split(/ /,$atoms);
    local $num_atoms = scalar(@atoms);
    local $num_rows = 2**$num_atoms;
    local $pseq = &prettify_seq($arg);
    local $spaces = &get_spaces($pseq);

    local $dashes;
    for ($i=1;$i<=length($atoms);$i++) {
	$dashes .= "-";
    }
    $dashes .= "|";  # that's a vertical bar in case you are looking at this in xemacs and see it italicized
    for ($i=1;$i<=length($pseq)+1;$i++) {
	$dashes .= "-";
    }
    local $template = "@atoms \| $pseq\n$dashes";    # build the first two lines
    $template .= "\n";

    for ($i=1;$i<=$num_rows;$i++) {        # build the tva's ...
	local @tva;
	for ($j=0;$j<$num_atoms;$j++) {    # build the ith tva ...
	    local $toggle;
	    for ($k=0;$k<2**$j;$k++) {
		if ( 2**($num_atoms - $j) * $k < $i &&
		     $i <= 2**($num_atoms - $j - 1) + (2**($num_atoms - $j) * $k) ) {
		    $tva[$i] .= "T ";
		    $toggle = 1;
		    last;
		}
	    }
	    if (!$toggle) {
		$tva[$i] .= "F ";
	    }
	}
	$template .= "$tva[$i]\| \n";          # add on the ith tva; no spaces in this version...
    }
    chop $template;
    return "$template";
}

sub make_att_template {

    local ($arg) = @_;
    $arg =~ s/\s+([\.v]|->|<->)\s+/$1/g;   # puts argument into probfile format if user has rolled her own
    local $pseq = &prettify_seq($arg);

    # Need to remove spaces beneath the argument; causing problems under Windows -- cm, Feb 2013
    #   local $spaces = &get_spaces($pseq);  

    local $spaces = " ";
    local $atoms = &extract_atoms($arg);
    local $atom_spaces = $atoms;
    $atom_spaces =~ tr/[A-Z]/                          /;
    local $dashes;
    for ($i=1;$i<=length($atoms);$i++) {
	$dashes .= "-";
    }
    $dashes .= "|";  # that's a vertical bar in case you are looking at this in xemacs and see it italicized
    for ($i=1;$i<=length($pseq)+1;$i++) {
	$dashes .= "-";
    }
    local $spaces_with_vertbar = &get_spaces($pseq);
    $spaces_with_vertbar = &get_spaces($atoms) . "|" . $spaces;
    local $spaces = $spaces_with_vertbar;
    $spaces =~ tr/|/ /;

#    local $att_template = "$atoms\| $pseq\n$dashes\n$spaces_with_vertbar\n$spaces\n$spaces\n$spaces\n";
    local $att_template = "$atoms\| $pseq\n$dashes\n$spaces_with_vertbar\n";
    return $att_template;
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

sub prettify_seq {
    $_ = shift;
    s/,\s*/, /g;                              # make sure a single space follows comma delimiters
    s/([^:])([\.v]|->|<->)([^:])/$1 $2 $3/g;  # add spaces b/w binary connectives
    s/\s*(:.)\s*/ $1 /g;                      # one space either side of :.
    return $_;
}

### This is the old subroutine for 1st edition when periods served as delimiters

sub old_prettify_seq {  
    $_ = shift;
    s/([^: ])\. /$1  /g;                      # remove delimiter dots
    s/,\s*/  /g;                              # remove delimiter commas; 2 spaces b/t wffs
    s/([^:])([\.v]|->|<->)([^:])/$1 $2 $3/g;  # add spaces b/w binary connectives
    s/\s*(:.)\s*/ $1 /g;                      # one space either side of :.
    return $_;
}

1;
