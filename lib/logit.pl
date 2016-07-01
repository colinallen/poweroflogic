#!/usr/bin/perl

# logit.pl
# Version 0.1 by Colin Allen 9/26/98
# - subroutine file to log cgi transactions with or without html

use Text::Wrap;

# Call logit with a text string to log, and optionally a second
# argument which, if true, will preserve html.
# Multiline strings ok (encouraged)
sub logit {
    my ($content,$html) = @_;
    $content = &dehtmlify($content) unless $html;

    my $sessionid = $ENV{'REMOTE_ADDR'};
    my $browser = $ENV{'HTTP_USER_AGENT'};
    my $caller = url();
    my $logfile="/var/log/pol/ClientLogs/$sessionid";

    if (open('LOG',">>$logfile") || open ('LOG', ">>/tmp/pol-errors")) {
	my $now = localtime;
	print LOG
	    "Script $caller\n",
	    "at $now from $sessionid\n",
	    "with $browser\n"
	    ;

	print LOG wrap("","",$content);
	print LOG "\===end of record===\n\n";
	close(LOG);
    }
}


sub mailit { # to, text
    my ($to,$text) = @_;
    my $caller = $ENV{'REMOTE_ADDR'};
    if ($to =~/random/i) {

	return;  # bypass random mailing; uncomment for notification

	my @principals = ('colin',
			  'cmenzel',
			  # the more nobodys, the less the chance we get it
			  'nobody','nobody','nobody','nobody','nobody',
			  'nobody','nobody','nobody','nobody','nobody',
			  'nobody','nobody','nobody','nobody','nobody',
			  'nobody','nobody','nobody','nobody','nobody',
			  'nobody','nobody','nobody','nobody','nobody',
			  'nobody','nobody','nobody','nobody','nobody',
			  'nobody','nobody','nobody','nobody','nobody',
			  'nobody','nobody','nobody','nobody','nobody',
			  'nobody','nobody','nobody','nobody','nobody',
			  'nobody','nobody','nobody','nobody','nobody',
			  'nobody','nobody','nobody','nobody','nobody',
			  'nobody','nobody','nobody','nobody','nobody',
			  'nobody','nobody','nobody','nobody','nobody',
			  'nobody','nobody','nobody','nobody','nobody',
			  'nobody','nobody','nobody','nobody','nobody',
			  'nobody','nobody','nobody','nobody','nobody',
			  'nobody','nobody','nobody','nobody','nobody',
			  'nobody','nobody','nobody','nobody','nobody',
			  'nobody','nobody','nobody','nobody','nobody',
			  'nobody','nobody','nobody','nobody','nobody',
			  'nobody','nobody','nobody','nobody','nobody',
			  );
	$to = $principals[int(rand @principals)];
    }
    if ($to ne 'nobody') {
	open('MAIL',"|$mailprog");
	print MAIL
	    "To: $to\n",
	    "Subject: ",
	    $cgi->url,
	    "\n",
	    "X-Caller: $caller\n",
	    "\n", # blank line between header and body
	    &dehtmlify($text),
	    "\n\n",
	    "<html>\n",
	    $cgi->Dump,
	    "\n</html>",
	    ;
	
	close MAIL;
    }
}

# subroutine to strip out html tags and replace special characters.
# By no means complete.
sub dehtmlify {
    for ($_[0]) {
	s/\<\-\>/dblarrow/g;
	s/<[^>]*>//g;
	s/&amp;/&/g;
	s/&gt;/>/g;
	s/&lt;/</g;
	s/&nbsp;/ /g;
	s/&copy;/\(c\)/g;
	s/&forall;/\@/g;
	s/&exist;/\$/g;
	s/\n+/\n/g;
	s/dblarrow/\<\-\>/g;
	return wrap("","",$_);
    }
}

1; # required by require

