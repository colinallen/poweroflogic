#!/usr/bin/perl -w

my $standalone = 0;

if ($standalone) {

  require "../lib/wff-subrs.pl";

#  local $wff="~(FvG)<->(~F.~G)";
#  local $n = 3;

  local $wff = "~E -> (G . H)";
  local $n=1;

#  local $wff = "AvB";
#  local $n=1;

#  local $wff = "(~[(A.C)vB].~[A.B])";
#  local $n = 1;

#  local $wff="(A->(B<->C))v(B->C)";
#  local $n = 3;

  $foo = &extract_nth_subwff($wff,$n);
  print "$foo\n";
}

##############################
# This is the main subroutine.  It is a function that returns the subwff containing ...
# ...the nth connective (counting left to right) of the original wff as its main connective

sub extract_nth_subwff {

    my ($wff,$n) = @_;
#    ($wff,$n) = @_;

    my $num_connectives = $wff =~ tr/\>~v./\>~v./;

    return $wff if !$num_connectives;
    return $wff if ($num_connectives == 1);

    if ($n==0 or $n>$num_connectives) {
#	print "Bad 2nd argument";
	exit;
    }

    $wff = &simplify($wff);

    local $nth_connective = $wff;
    $nth_connective =~ s/(((.*?)(\.|v|<=>|->|~)){$n}).*/$4/;

#    print "nth_connective: $nth_connective\n";

    if ($nth_connective ne "~") {
	$nth_left = $wff;
	$nth_left =~ s/(((.*?)(~|\.|v|<=>|->)){$n}).*/$1/;
	$nth_left =~ s/(.*)(\.|v|->|<=>).{0}/$1/;
	$left_arg = $nth_left;
	while (not &wfff($left_arg)) {
	    $left_arg = substr($left_arg,1);
	}
    }

    $nth_right = $wff;
    $nth_right =~ s/((.*?)(~|\.|v|->|<=>)){$n}(.*)/$4/;  # everything to the right of $nth_connective

#    print "nth_right: $nth_right\n";

    if ($nth_connective eq "~" and $nth_right =~ /^[A-Z]/) {  # if $nth_right starts with an atom...
	$nth_right =~ s/^(.).*/$1/;                           # grab it (it's the arg to the ~)
    }

    while (not &wfff($nth_right)) {
	chop($nth_right);
    }
    $right_arg = $nth_right;
    if ($nth_connective eq "~") {
	$nth_subwff = "~$right_arg";
    } else {
	$nth_subwff = "($left_arg$nth_connective$right_arg)"; 
    }

#    if ($nth_subwff =~ /[v.>]/ and ($nth_subwff !~ /\(.*\)/)) {
#      CASE: {
#	    $nth_subwff = "[$nth_subwff]", last CASE if $square_bracket;
#	    $nth_subwff = "($nth_subwff)", last CASE if !$square_bracket;
#	}
#    }

#    $nth_subwff = "($nth_subwff)" if ($nth_subwff =~ /[v.>]/ and ($nth_subwff !~ /\(.*\)/));
    $nth_subwff = &unsimplify($nth_subwff);

    return $nth_subwff;
}
    
###################
# MINOR SUBROUTINES

sub wfff {
    my $fla = &iswff(&unsimplify($_[0]));  # use of &iswff forces use of outer parens
    return $fla;
    }

sub simplify {
    local $fla = $_[0];
    $fla =~ s/<->/<=>/g;         # change <-> to <=> (kludgy but makes coding *much* easier
    return $fla;
}

sub unsimplify {
    local $fla = $_[0];
    $fla =~ s/<=>/<->/g;
    return $fla;
}

1;  # required by require
