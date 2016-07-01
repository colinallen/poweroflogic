#!/usr/bin/perl
# routines for sending grade info to PageOut

use IO::Socket;

## -----------------SERVER SPECIFICATION----------------- ##
$PAGEOUT_SERVER = 'www.pageout.net';       # pageout production
#$PAGEOUT_SERVER = 'www.pagebeta.net';     # pageout beta summer 2002
#$PAGEOUT_SERVER = 'ventoux.dnsalias.org'; # ventoux spoof
#$PAGEOUT_SERVER = '198.45.24.25';        # debugging may 2003

## ----------------- PARTNER ID MAGIC NUMBER ------------ ##
# now taken dynamically from pageout login, so this is a default
$PARTNER_ID = 115;
#$PARTNER_ID = 27; ## pageout beta summer 2002

## ----------------- SCRIPT LOCATION -------------------- ##
$GRADE_STORE_SCRIPT = '/page.dyn/student/course/vendor_assignment';
#$GRADE_STORE_SCRIPT = '/cgi-bin/pageout.cgi'; # ventoux spoof

## ----------------- OTHER CONSTANTS -------------------- ##
##              Should not need to change these           ##
$PAGEOUT_PORT = 80;
$PAGEOUT_KEY = 'layman';

sub send_to_pageout {
    $|=1; # force flush of output buffer to avoid duplicate output
  FORK:
    if ($forkpid = fork) { # parent
	return;
    } elsif (defined $forkpid) { # child
	&really_send_to_pageout(@_);
	exit; # get out of here!
    } elsif ($! =~ /No more process/i) {
	sleep 5;
	++$attempts;
	redo FORK unless $attempts > 10;
	&log_pageout_error('fork error',$!,@_);
	return;
    } else { # error
	&log_pageout_error('fork error',$!,@_);
	return;
    }
}

sub really_send_to_pageout { # child executes this
    ## hash the data that's passed in
    my %data = @_;
    
    #verify data
    for ( # required fields
	  'student_id',       # pageout specified
	  'course_id',        # pageout specified
	  'tool_id',          # pageout specified
	  'vendor_assign_id', # our exercise number, e.g. 1.1A
	  'assign_probs',     # array of probs attempted this time
	  'student_score',    # array of results on above
	  )
    {
	if (!defined $data{$_}) { # missing a required field
	    print STDERR "missing $_ in [ @_ ]\n";
	    &log_pageout_error("CALL ERROR: missing $_",
			       'PAGEOUT WAS NOT CONTACTED DUE TO DATA ERROR',
			       @_);
	    return;
	}
    }

    # grab chapter and section number from (e.g.) 8.1D - i.e. 8 and 1
    $data{'vendor_assign_id'} =~ /^(\d+)\.(\d+)(\w*)/;
    my ($chapter,$sec,$ex) = ($1,$2,$3);
    
    require "$EXHOME$chapter/contents.pl"; # now we can use %chapter data

    # we need to send a title: combine section title and exercise label
    my $title = $chapter{'sec'.$sec}{'title'};
    $title .= ": ".$chapter{'sec'.$sec}{'labels'}{$data{'vendor_assign_id'}};
    $chapter = " $chapter" if $chapter =~ /^\d$/;
    $title = "Ch. $chapter Ex. $sec$ex: $title";
    $data{'assign_title'} = $title;

    # we need to send max points available
    $data{'total_points'} = $chapter{'sec'.$sec}{'counts'}{$data{'vendor_assign_id'}};


    # start to build key=value pairs for sending to PageOut
    # first the secret stuff
    $data{'key'}=$PAGEOUT_KEY;

    # now we start to build query string for
    # everything except the actual scores and problems
    while (($key,$value) = each %data) {
	next unless $key; # skip if bogus
	$key = substr($key,1) if $key =~ /^-/;
	next if $key =~ /assign_probs|student_score/;
	push @cgiparams, "$key=$value";
    }

    # now the rest PageOut is picky about order of probs and scores
    my $scores = $data{'student_score'};
    my $probs  = $data{'assign_probs'};
    for ($i=0;$i<@$probs;++$i) {
	push @cgiparams, ('assign_probs='.$$probs[$i],
			  'student_score='.$$scores[$i]);
    }

    # make a query string
    my $cgiparams = join ("&", @cgiparams);
    $cgiparams =~ s/\s/%20/g; # spaces choke web browsers - use %20 instead

    # open socket
    my $socket;
    my $attempts = 0;
    my $limit = 10;
    while (!$socket) {
	++$attempts;

	if ($attempts > $limit) {
	    &log_pageout_error("Couldn't initialize socket after $limit attempts",
			       $@,%data);
	    exit;
	}

	$socket = IO::Socket::INET->new(PeerAddr => $PAGEOUT_SERVER, 
					PeerPort => $PAGEOUT_PORT, 
					Proto    => "tcp", 
					Type     => SOCK_STREAM,
					Timeout  => 10);

	sleep 1 unless $socket; # wait a second
    }
    
    # send and check request
    # conversion to POST method by CA on 5/31/03
    if (!defined($socket->send("POST $GRADE_STORE_SCRIPT HTTP/1.0\n"))) {
	## failed to get a socket
	close $socket;
	&log_pageout_error("Couldn't send data",$!,%data);
	exit;
    } else { # we got a live connection
	$socket->send("Content-type: application/x-www-form-urlencoded\n");
	$socket->send("Content-length: ".length($cgiparams)."\n");
	$socket->send("\n");
	$socket->send("$cgiparams");
    }

    # read response
    my $pageout_response;
    while (<$socket>) {
	$pageout_response .= $_;
    }
    close $socket;
    

    # check response
    if ($pageout_response =~ /have\s*been\s*successfully/i) {
	&log_pageout_success("\n\nRETURNED by $PAGEOUT_SERVER",$pageout_response,
			     'query_string',"$cgiparams\n",
			     %data);
    } elsif ($pageout_response) {
        &log_pageout_error("\n\nRETURNED by $PAGEOUT_SERVER",$pageout_response,
                           'query_string',"$cgiparams\n",
                           %data);
    } else {
        &log_pageout_error("\n\nNO RESPONSE from $PAGEOUT_SERVER","",
                           'query_string',"$cgiparams\n",
                           %data);
    }
}

sub log_pageout_error { # what we do when we can't talk to PageOut
    my $site = 'mayfieldlogic';
    $site = 'poweroflogic' if $program =~ /poweroflogic/;
    my $logfile="/home/www/sites/$site/docs/Logs/pageout_errors";
    $logfile = "/home/www/sites/$site/docs/Logs/pageout_resubmit_errors"
	if $program eq 'poweroflogic'; # in standalone mode
    &log_pageout_response($logfile,@_);
}

sub log_pageout_success { # what we do when we can't talk to PageOut
    my $site = 'mayfieldlogic';
    $site = 'poweroflogic' if $program =~ /poweroflogic/;
    my $logfile="/home/www/sites/$site/docs/Logs/pageout_success";
    &log_pageout_response($logfile,@_);
}

sub log_pageout_debug {
    my $site = 'mayfieldlogic';
    $site = 'poweroflogic' if $program =~ /poweroflogic/;
    my $logfile="/home/www/sites/$site/docs/Logs/pageout_debug";
    &log_pageout_response($logfile,@_);
}

sub log_pageout_response {
    my ($logfile,$result,$response,%stuff) = @_;
    open(LOG,">>$logfile");
    print LOG '====='."\n";
    print LOG scalar localtime(time);
    print LOG " ";
    print LOG $ENV{'REMOTE_ADDR'};
    print LOG "\n$program";
    print LOG "\n\nWE SENT TO\n";
    print LOG "http://$PAGEOUT_SERVER$GRADE_STORE_SCRIPT?$stuff{'query_string'}\n";
    for (sort myorder keys %stuff) {
	next if /query_string/;
	my @values = @{$stuff{$_}};
	if (defined $values[0]) {
	    print LOG "$_=".join(" ",@values)."\n";
	} else {
	    my $value = $stuff{$_};
	    $value=~ s/%20/ /g unless /query_string/;
	    print LOG "$_=$value\n";
	}
    }
    print LOG "$result\n$response\n";
#    print LOG "==== Our State ====\n".$cgi->Dump if $logfile =~ /error/;
    close LOG;
}

sub myorder {
    ## sort things for printing out in order
    ## that is easy for humans to read
    ($b =~ /query_string/ cmp $a =~ /query_string/
     or
     $a =~ /assign_probs/ cmp $b =~ /assign_probs/
     or
     $a =~ /student_score/ cmp $b =~ /student_score/
     or
     $a cmp $b)
}

sub create_pageout_cookie { # <student_id,course_id> : cookie
    my %pageoutid = ('student_id'=>$_[0],
		     'course_id'=>$_[1],
		     'tool_id'=>($_[2]||$PARTNER_ID));
    return cookie(-name=>'pageout',
		  -value=>\%pageoutid,
		  -path=>'/',
		  -expires=>'+2h')
}

sub null_pageout_cookie { # null cookie
    return cookie(-name=>'pageout',
		  -value=> '',
		  -path=>'/',
		  -expires=>'-1d');
}

1; #required by require



