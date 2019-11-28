# tt-subrs.pl

###
sub msg_wrapper {
    my ($msg,$correct) = @_;
    my $color = "red";
    $color = "green" if $correct;
    $msg = "<font color=\"$color\">$msg</font>\n<br />\n";
    return $msg;
}

### Compare the atoms constituting two strings
sub compare_atoms {
    my ($atoms,$user_atoms) = @_;
    @atoms = sort(split(//,$atoms));
    @user_atoms = sort(split(//,$user_atoms));
    $all_atoms_are_user_atoms = &subset(\@atoms,\@user_atoms);
    $all_user_atoms_are_atoms = &subset(\@user_atoms,\@atoms);

#      print "\@ATOMS: @atoms\n";
#      print "\@USER_ATOMS: @user_atoms\n";
#      print "ATOMS ARE USER ATOMS: $all_atoms_are_user_atoms\n";
#      print "USER ATOMS ARE ATOMS: $all_user_atoms_are_atoms\n";
    # no futzing
    return 'ok'
      if @atoms == @user_atoms
	and $all_atoms_are_user_atoms;
    # Got some duplicates
    return 'dups'
      if (@atoms < @user_atoms
	and $all_user_atoms_are_atoms);
    # Atoms missing
    return 'dels'
      if @atoms > @user_atoms
	  and $all_user_atoms_are_atoms;
    # Got some atoms that aren't in the argument
    return 'extras'
      if $all_atoms_are_user_atoms;
    return 'dels_and_extras'
      if !$all_atoms_are_user_atoms
	and !$all_user_atoms_are_atoms;
}

### Determines whether one list of strings is a subset of another
sub subset {
    my ($list1,$list2) = @_;

    foreach $member (@$list1) {
	next if grep {$member eq $_} @$list2;
	return 0
    }
    return 1;
}

###
sub count_TVs_and_slashes {
    my ($user_tvs) = @_;
    my $num;
    $num = $user_tvs =~ tr/TF\//TF\//;
return $num;
}

###
sub remove_string_duplicates {
  $_ = shift;
  while (/(.).*\1/) {
    s/(.)(.*)\1/$1$2/g while /(.).*\1/;
  }
  return $_;
}

###
sub conj {
    my ($lhs,$rhs) = @_;
    return "T" if $lhs.$rhs eq "TT";
    return "F";
}

###
sub disj {
    my ($lhs,$rhs) = @_;
    return "F" if $lhs.$rhs eq "FF";
    return "T";
}

###
sub cond {
    my ($lhs,$rhs) = @_;
    return "F" if $lhs.$rhs eq "TF";
    return "T";
}

###
sub bicond {
    my ($lhs,$rhs) = @_;
    return "T" if $lhs eq $rhs;
    return "F";
}

###
sub get_tv_for_wff {
    my ($wff,$tvs) = @_;
    return $tvs if &atomic($wff);
    return substr($tvs,0,1) if &wff($wff) =~ /neg/;
    return substr($tvs,&count_conns_and_atoms(&lhs($wff)),1);
}

###
sub count_conns_and_atoms {
    my $exp = shift;
    $exp =~ s/:\.|\.://;  # remove :. or .: if $exp is an argument
    my $num;
    $num = $exp =~ tr/A-Z~v\.\-/A-Z~v\.\-/;
    return $num;
}

###

sub get_atoms_and_connectives {
    my $seq = shift;
    $seq =~ s/[()\[\]]//g;
    $seq =~ s/<->/<=>/g;
    $seq =~ s/(\.|v|->|<=>)/ $1 /g;
    $seq =~ s/~/~ /g;
    $seq =~ s/<=>/<->/g;
    return split(/ /,$seq);
}

###
# This subroutine takes the displayed argument and forms a string 
# that is easier to process in the above routine that calls it

sub make_temp_arg_string {
    my $temp_arg = $pretty_arg;
    $temp_arg =~ s/(^[A-Z])  /$1\^  /;
    $temp_arg =~ s/(^[A-Z]) :\./$1\^ :\./;
    $temp_arg =~ s/  ([A-Z])  /  $1\^  /g;
    $temp_arg =~ s/  ([A-Z]) :\./  $1\^ :\./;
    $temp_arg =~ s/:\. ([A-Z])\s*$/:\. $1\^/;
    $temp_arg =~ s/([^:])(\.)/$1&/g;
    return $temp_arg;
}

###
sub cleanup {
    local $att = $_[0];
    $att =~ s/([TF])\s*(\n)/$1$2/g;
    return $att;
}


###
sub paren_eq {

    my ($wff1,$wff2) = @_;
    $wff1 =~ tr/][/)(/;
    $wff2 =~ tr/][/)(/;
    return 1 if $wff1 eq $wff2 or "($wff1)" eq $wff2 or $wff1 eq "($wff2)";
    return 0;
}

###

sub atomic {
    $_ = shift;
    return 1 if /^[A-Z]$/;
    return 0;
}

###
sub get_atoms {
    my $at = $att;
    $at =~ s/(.*?)\|.*/$1/s;  # strip off the atoms from the rest of the truth table
    $at =~ s/[ \t]//g;        # remove spaces (and tabs), if any
    return $at;
}

###

sub old_get_atoms {
    local $at = $att;
    $at =~ s/(.*?) \|.*/$1/s;
    return $at;
}

#############################################################################
### This subroutine constructs all the possible TVAs for sentence letters ###
### in the argument.  The rows that are *not* invalidating and on which   ###
### the conclusion is false will then be extracted & checked against the  ###
### noninvalidating rows that the user has found to make sure that she    ###
### has identified all such rows before declaring the argument valid.     ###
#############################################################################

sub get_tvas {
    my @tvas = ();
    local $tt_template = &make_tt_template($argument);
    local $num_rows_in_tt_template = 2**length($atoms);

    $tt_template =~ s/.*?\n(.*)/$1/; # strip off the argument

    for ($i=1;$i<=$num_rows_in_tt_template;$i++) {
	local $tva = "";
	local $tvs = $tt_template;
	local $ats = $atoms;
	$tvs =~ s/(.*?\n){$i}(.*?)\|.*/$2/s;       # get the tvs from the ith row (was "s" flag needed?) 
	  $tvs =~ s/[ \t]//g;	# remove spaces (and tabs), if any
	while ($ats) {
	    $tva = chop($ats) . chop($tvs) . " " . $tva; # $tva looks like this: "PT QF RF"
	}
	push @tvas, $tva;
    }
    return @tvas;
}

###
# Don't think this will be needed; I think it is from full TT checker

sub get_user_tvas_from_ATT {
    local @tvas = ();
    for ($i=1;$i<=$num_rows;$i++) {
	my $tva = "";
	my $tvs = $att_template;
	 $ats = $atoms;

	$tvs =~ s/.*?\n(.*)/$1/;	           # strip off the sequent
	$tvs =~ s/(.*?\n){$i}(.*?)\|.*/$2/s;       # get the tvs from the ith row (was "s" flag needed?)
	$tvs =~ s/[ \t]//g;                        # remove spaces (and tabs), if any
	while ($ats) {
	    $tva = chop($ats) . chop($tvs) . " " . $tva;

	}
	push @tvas, $tva;
    }
    return @tvas;
}

###

sub get_user_tvs {
    local @user_tvs;
    local $user_tvs = $att;
    $user_tvs =~ s/.*?\n.*?\n(.*)/$1/;          # strip off the argument and separator
    $user_tvs =~ s/.*?\|\s*([\/TF].*?)$/$1/mg;  # strip out tva's (/m allows $ to match at newlines...
                                                # ...; $ is used (rather than \n) in case no \n at end of $att
    $user_tvs =~ s/[ \t]//g;                    # remove tabs and spaces
    @user_tvs = split(/\n/,$user_tvs);

    return @user_tvs;
}	

#################################################################
### Subroutine to return the rows beneath the arg and dashes. ###
### Will be used to reconstruct any TVAs given in each row.   ###
### There should be at most one TVA given (for the first      ###
### invalidating row the user finds).                         ###
#################################################################

sub get_rows {
    local @rows;
    local $rows = $att;
    $rows =~ s/.*?\n.*?\n(.*)/$1/;        # strip off the argument and separator
    $rows =~ s/[ \t\r]//g;                # remove tabs and spaces and CR's (so only newlines left)
    @rows = split(/\n/,$rows);

    return @rows;
}	

###
sub count_connectives {
    $_ = $_[0];
    tr/>~\.v/>~\.v/;
}

###
# Note this is not the same as removing spaces in the argument
# Don't replace with s/\s*//g, as we need to retain spaces b/t
# premises so can split on whitespace to form @sequent. (Not
# currenty used in this code.)


###
#
sub prettify_argument {
  $_ = shift;
  s/,/, /g;
  s/([\.v]|->|<->|:\.|\.:)/ $1 /g;
  s/<->/&lt;-&gt;/g;  # "<" inside <pre> needs to be unicoded
  return $_;
}

### Removes assignments to statement letters not occurring in conclusion
### from TVAs in a TVA array
sub truncate_tvas {
    my @tvas = @_;
    my $conc_atoms = $atoms_in_conclusion;
    my @truncated_tvas;
      for (@tvas) {
	  $_ =~ s/[^$conc_atoms][TF]\s*//g;
	  push @truncated_tvas, $_;
      }
    return @truncated_tvas;
}
	
###
sub find_missing_tvas {
    my ($user,$system) = @_;
    my @missing_tvas = ();
    my @user = @$user;
    my @system = @$system;
    # Find the members of @system that are not in @user
    while (@system) {
	$system_tva = pop @system;
	push(@missing_tvas,$system_tva)
	  if not grep {$_ eq $system_tva} @user;
      }
    return @missing_tvas;
}

### Sort each TVA in a TVA array alphabetically
sub sort_tvas {
    my @tvas = @_;
    @tvas = map {join(' ',(sort(split(/\s+/,$_))))} @tvas;
    return @tvas;
}

### Sort each TVA in a TVA array alphabetically
sub canonize_tvas {
    my @tvas = @_;
    my @canonized_tvas = ();
    foreach $tva (@tvas) {
	$tva =~ s/(\w)([TF])/$1:$2/g;
	my @tva = split(/\s+/,$tva);
	@tva = sort @tva;
	$tva = join(' ',@tva);
	push @canonized_tvas, $tva;
    }
    return @canonized_tvas;
}

###
sub list_member {
    my ($object,@list) = @_;
    return grep {$_ eq $object} @list;
}

###
sub find_redundant_tvas {
    my @tvas = &truncate_tvas(@_);
    my @redundant_tvas = ();
    while (@tvas) {
	my $tva = pop(@tvas);
	push(@redundant_tvas,$tva)
	  if (&list_member($tva,@tvas)
	      and not &list_member($tva,@redundant_tvas));
      }
    return @redundant_tvas;
}

###
sub remove_redundant_tvas {
    my @tvas_false_conc = @_;
    my @nonredundant_tvas_false_conc = ();

  BAR:
    foreach $tva (@tvas_false_conc) {
      BAZ:
	foreach $tva1 (@nonredundant_tvas_false_conc) {
	    local $ats = $atoms_in_conclusion;
	    while ($ats) {
		my $at = chop($ats);
		my $foo = $tva;
		$foo =~ s/^.*($at[TF]).*$/$1/;
		next BAZ if $tva1 !~ /^.*$foo.*$/;
	    }
	    next BAR;
	}
		# I could just increment $num2 here...
	push(@nonredundant_tvas_false_conc,$tva);
    }
    return @nonredundant_tvas_false_conc;
}


###############################################################################
### Subroutine for calculating whether a wff is a taut.  Needed to check    ###
### in those cases where the conclusion is valid and the user has submitted ###
### a blank ATT.  Got to count this as a correct answer (in fact, the best  ###
### answer), since it contains no unneeded rows).                           ###
###############################################################################

sub tautology {
    my ($wff) = @_;
    my @tvas = &get_tvas;

    for (@tvas) {
	s/\s*$//;
	my $tva = $_;

	s/(\w)(\w)/$1 $2/g;
	%tva = split(/ /,$_);
	return 0 if &calculate_tv($wff,%tva) eq "F";
    }
    return 1;
}

###############################################################################
# Subroutine for calulating TV of a sentence on a given truth value assignment
# Taken from Quizmaster code; should put this into a separate module
# Question for later: why does a space get inserted after the conclusion in the
# sequent when TT is submitted from tt.cgi?

sub calculate_tv {

    # Strip off the formula
    $_ = shift @_;

    # Make a hash from the TVA that remains
    my %local_tva = @_;

    # Replace statement letters with truth values (very cool)
    s/([A-Z])/$local_tva{$1}/g;

    # Calculate til all connectives are gone
    while (/[.~\-v]/) {
	&doitnow($_);
    }

    # Prolly unnecessary
    $_ =~ s/\s//;

    return $_;
}

# the TV calculation engine
sub doitnow {

    ($_) = @_;

    # The algorithm assumes outer delimiters
    $_ = "\($_\)" if &iswff("($_)");

    s/(.*?)~~(.*)/$1$2/g;  
    s/~T/F/g;
    s/~F/T/g;
    s/[\[\(]T\.T[\]\)]/T/g;
    s/[\[\(]T\.F[\]\)]/F/g;
    s/[\[\(]F\.T[\]\)]/F/g;
    s/[\[\(]F\.F[\]\)]/F/g;
    s/[\[\(]TvT[\]\)]/T/g;
    s/[\[\(]TvF[\]\)]/T/g;
    s/[\[\(]FvT[\]\)]/T/g;
    s/[\[\(]FvF[\]\)]/F/g;
    s/[\[\(]T->T[\]\)]/T/g;
    s/[\[\(]T->F[\]\)]/F/g;
    s/[\[\(]F->T[\]\)]/T/g;
    s/[\[\(]F->F[\]\)]/T/g;
    s/[\[\(]T<->T[\]\)]/T/g;
    s/[\[\(]T<->F[\]\)]/F/g;
    s/[\[\(]F<->T[\]\)]/F/g;
    s/[\[\(]F<->F[\]\)]/T/g;
}


1;
