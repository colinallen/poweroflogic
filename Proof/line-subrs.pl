# line-subrs.pl
# line manipulation subroutines

# line-subrs.pl
# Version 0.3 Colin Allen 07/06/98
#   - added routines get_rule and get_ann_nums to split annotation
# Version 0.2 Colin Allen 07/04/98
#   - allow lines with no . after line number
# Version 0.1 Colin Allen 07/03/98
#   - subroutines to extract the four parts of a line of proof
#   - use with "require line-subrs.pl"

# Uncomment these lines to run from the command line
#chop ($input = <STDIN>);
#print get_indent($input),"\n";
#print get_linenum($input),"\n";
#print get_linesent($input),"\n";
#print get_annotation($input),"\n";

sub get_indent { # from line of proof
    my ($in) = @_;
    return $1 if $in =~ /^(\|+)/;
    return "";
}

sub get_linenum { # from line of proof
    my ($in) = @_;
    return $1 if $in =~ /^\|*(\d\d?|\([^\)]*\)|\[[^\]]*\])/;
    return "";
}

sub get_linesent { # from line of proof
    my ($in) = @_;
    $in =~ s/assume.*//i if $in =~ /assume/i;
    $in =~ s/id$//i # to deal with "1.Id" vs "1.(x=x)Id"
	if $in =~ /[^\d.]id$/i; 
    return $1 if $in =~ /^\|*\d\d?[.:,;]*([^1-9]*).*$/i;
    return "";
}

sub get_annotation { # from line of proof
    my ($in) = @_;
#    print "\nlooking for annotation in $in\n";
#    return $1 if $in =~ /((\.:|:\.).*)/;
    return $1 if $in =~ /[^\d.](assume|id$)/i;
    return $1 if $in =~ /^\|*\d\d?[.:,;]*[^1-9]*(.*)$/;
    return "";
}

sub get_rule { # from annotation
    my ($in) = @_;
#    print "\n$in\n";
    return $2 if $in =~ /([-.,\d]*)([A-Z]+)/i;
    return "";
}

sub get_ann_nums { # from annotation
    my ($in) = @_;
    my $result = "";
    $result = $1 if $in =~ /(\d[-.,\d]*)\w*([A-Z]+)/i;
    $result =~ s/[-.]/,/g;
    $result =~ s/,,/,/g;
    chop $result if $result =~ /,$/;
    return $result;
}

# THIS SUB SHOULD NOT BE NEEDED - JUST USE ARRAY REF DIRECTLY
sub get_line {
    my (@prf,$linenum) = @_;
    return $prf[$linenum];
}

1; # required by require
