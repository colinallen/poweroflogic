#prf-subrs.pl

# this file is for routines that involve display of proofs.
# it is not intended for standalone use

# Version 0.1 by Colin Allen 09/11/98

sub prftoproof { # <string,integer> : if integer, then truncate the line of proof
    my ($prf,$truncate) = @_;
    $prf =~ s/\r|\n//g;

    my $prob = "";
    my $ans = "";
    my $conc = 0;
    while ($prf) {
	# first deal with special theorem case
	# temporarily assign line number 0
	$prf = "0.$prf" if ($prf =~ /^(\.:|:\.)/);

	# a nasty old regexp to pull out lines one at a time (we hope!)
	$prf =~ /^(\|*\d\d?\.([^\d\|]|\d[^\d\.])*)(\|*\d\d?\..*)?$/;
	
	my $rawline=$1;
	$prf=$3;
	chomp $rawline;

	my $indent = &get_indent($rawline);
	$indent =~ s!\|!\| !g;
	
	my $linenum = &get_linenum($rawline);

	my $linesent = &get_linesent($rawline);

	if ($truncate && length($linesent) > $truncate) {
	    # not worrying about double wraps (yet)

	    # use this for wrap
	    my $part1 = substr($linesent,0,$truncate);
	    my ($part2,$part3) = split(/\)/,substr($linesent,$truncate),2);

	    if ($part3=~/[a-zA-Z]/) { # use this for significant content to wrap
		# we have to replace the ")" that was sucked up by the split and
		# indicate the continuation point in the line with ',,,' as
		# ellipsis marker -- replaced later when displayed
		$linesent = $part1.$part2."),,,\n\t".$part3;
	    } 

	}
	
	my $sentcol = length($linesent)+4;
	$sentcol = 20 if $sentcol < 20;

	$packedsent = pack "A$sentcol", $linesent;

	my $line = $indent;
	
	if ($linenum==0) {
	    $line = ":.";
	} else {
	    $line .= pack "A4", "$linenum." if $linenum!=0;
	}
	$line .= $packedsent;
	$line .= &get_annotation($rawline);

	($conc and $ans .= "$line\n")
	    or $prob .= "$line\n";
	
	$conc=1 if $rawline=~/\.:|:\./;

    }
    return ($prob,$ans);
}

1; # required by require
