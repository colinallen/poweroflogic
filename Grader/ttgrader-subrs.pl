# subroutines specific to truth table grading
$ttformchecker = '../TT/grader-check-tt-form.pl';
$ttchecker = '../TT/grader-check-tt.pl';
$attchecker = '../TT/grader-check-att.pl';

sub check_tt_result {
    my ($probtype,$input) = @_;

    my $result = 0;
    my $evalmsg;

    open2('RD','WR',$ttformchecker) || die "cannot open pipe"
      if $probtype eq 'TT_form';

    open2('RD','WR',$ttchecker) || die "cannot open pipe"
      if $probtype eq 'TT_full';

    open2('RD','WR',$attchecker) || die "cannot open pipe"
      if $probtype eq 'TT_abbr';

    print WR $input;
    close(WR);

    while (<RD>) {
	$evalmsg .= $_;
    }
    close(RD);

    if ($evalmsg =~ /Correct/s) {
	$result = 1;
    }
    return($result,$evalmsg);

    #}
}

1; # required by require
