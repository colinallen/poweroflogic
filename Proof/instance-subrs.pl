# instance-subrs.pl

chop ($arg1 = <>);
chop ($arg2 = <>);

print "yes\n" and exit if &isInstance($arg1,$arg2);
print "no\n" and exit;

# x is purported instance of y
# y is assumed to be a wf universal or existential
sub isInstance {
    my ($x,$y) = @_;
    $y =~ /^\(\$?([t-z])\)(.*)$/;
    my $var = $1;
    my $form = $2;

    print "Comparing $x to $form\n";
    
    return 1 if $x eq $form;
    #now check all the substitutions for $var
}

