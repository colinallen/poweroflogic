# subroutines specific to truth table grading
$symbchecker = '../Trans/grader-check-symb.pl';
#$symbchecker = '../TT/grader-check-tt.pl';

sub check_symb_result {
    my ($question,$answer) = @_;

    my $result = 0;
    my $evalmsg;

    open2('RD','WR',$symbchecker) || die "cannot open pipe";
    print WR "$question\n";
    print WR "$answer\n"; 
    close(WR);

    while (<RD>) {
	$evalmsg .= $_;
    }
    close(RD);
    
    if ($evalmsg =~ /Correct/s) {
	$result = 1;
    }
    return($result,$evalmsg);

}

1; # required by require
