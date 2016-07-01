#!/usr/bin/perl
use CGI;
use IPC::Open2;
require '../lib/header.pl';
require "../Grader/grader-subrs.pl";

$LSO = quotemeta(':.');
$RSO = quotemeta('.:');

@ts = (time); # tag stack
$errors = "";
$linecount=0;
$element_content = "";
$problem_id = 0;

$cgi = new CGI;
$cgi->import_names("GR");

unless ($GR::grader_submission) {
    ## for debugging take our input locally
    print STDERR "Offline mode--taking input from demo.in\n";

    open(FILE,'demo.in');
    while (<FILE>) {
	next if s/<\?[^>]*\?>//g;
	next if /^\s*$/;
	
	$GR::grader_submission.=$_;
    }
    close FILE;
    print STDERR $GR::grader_submission;
}

$GRADERLOG = "../../../docs/Logs/grader_log";
$SUBMITLOG = "../../../docs/Logs/GraderXML/".time.".xml";
open (LOG,">$SUBMITLOG") || print STDERR "grader.cgi: Can't open $SUBMITLOG\n";
print LOG $GR::grader_submission;
close LOG;

%HASH = &parse_xml(split(/\n/,$GR::grader_submission));
$HASH{'type'} = 'response'; # change its type
&grade_hash(\%HASH);

print $cgi->header(-type=>'text/xml');
#print &htmlify($GR::grader_submission);
print &xmlify(\%HASH);

&log_grader_event;

sub htmlify {
    my ($string) = @_;
    $string =~ s/>/&gt;/g;
    $string =~ s/</&lt;/g;
    return "<pre>$string</pre>";
}

sub log_grader_event {
    open (LOG, ">>$GRADERLOG");
    my $time = scalar localtime time;
    print LOG "=== $time === ($ENV{'REMOTE_ADDR'}) ===\n";
    print LOG &xmlify(\%HASH);
    close LOG;
}
