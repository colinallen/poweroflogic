while (<>) { print &rot($_); }

sub rot {
    $string = shift;
    $string =~ tr/ -NP-~/P-~ -N/;
    return $string;
}

