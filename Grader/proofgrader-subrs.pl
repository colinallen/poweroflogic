# subroutines specific to proof grading
$checker = '../Proof/proof.pl';

sub check_proof_result {
    my ($argument,$answer) = @_;

    my $result = 0;
    my $evalmsg;
    open2('RD','WR',$checker) || die "cannot open pipe";
    print WR $answer;
    close(WR);
    
    while (<RD>) {
	$evalmsg.=$_;
    }
    close(RD);
    
    if (!&check_prob_in_proof($argument,$answer)) {
	$evalmsg =~ s/Congratulations://;
	$evalmsg = "<font color=\"red\"><strong>Assumptions or conclusion of submitted proof changed from question.</strong>\n<br />\nEvaluation of <strong>altered</strong> proof follows:</font><br />\n$evalmsg";
	$result = 0; # just to be sure
    } elsif ($evalmsg =~ /congrat/si) {
	$result = 1;
    }
    return($result,"<br />$evalmsg\n<br />\n");
}

# subroutine to check that student hasn't changed the problem
sub check_prob_in_proof {
    my ($question, $answerproof) = @_;
    my $proofarg;
    for (split(/\n/,$answerproof)) {
	chomp;
	/\d+\.?(.*)/;
	my $stuff = $1;
	$proofarg .= $stuff;
	last if $stuff =~ /$LSO|$RSO/;
	$proofarg .= ","; # to separate premises
    }

    return &samearg($question,$proofarg);

}

1; # required by require
