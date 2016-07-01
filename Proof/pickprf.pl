print &pickprf("/www/poweroflogic/docs/ProbSets/Ch8/8.1A",'rand');


sub pickprf {
    my ($prffile,$method) = @_;
    my @questions = ();

    srand if $method =~ /rand/i;

    open(FILE,$prffile) || die "Can't open $prffile)";
    while (<FILE>) {
	next if /^\#/;
        next if $_ =~ /^\s*$/;
	
        push @questions, $_;

    } #end while FILE

    close QUIZFILE;

    my $numqs=@questions;

    if (($method =~ /\d+/)
	and
	($method <=$numqs)) {
	return @questions[$method-1];
    }

    if ($method =~ /rand/i) {
	my $i =int(rand @questions);
	return @questions[$i];
    } 

    die "Can't apply the method $method";
    
}
