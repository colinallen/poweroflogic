#!/usr/bin/perl -w

$argument = "(Aa->Ba). ~(AavBa) :. ~Fb";

print &translator($argument),"\n";

sub translator { # generate a translation scheme from expanded argument
    my ($argument) = @_;
    my @atoms;
    my @scheme;
    while ($argument =~ /([A-Z][a-u])/) {
	push @atoms, $1;
	$argument =~ s/$1//g;
    }
    my $nextletter = 'A';
    for (sort @atoms) {
	push @scheme, $nextletter, $_;
	++$nextletter;
    }
    return @scheme;
}

