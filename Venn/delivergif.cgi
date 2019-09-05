#!/usr/bin/perl

use CGI;
$cgi = new CGI;

require "../lib/header.pl";

$image = $cgi->param('image');
$image = '00000000.gif' if !$image;
$venndiaghome = "$DOCDIR/Images/Venn3";
$venndiaghome = "$DOCDIR/Images/Venn2" if $image =~ /^\d{4}\.gif/;
&delivervenngif($image);

sub delivervenngif {
    my ($file) = @_;
    
    $program = $cgi->url;
    
    my $fullpath = "$venndiaghome/$image";
    
    print $cgi->header(-type=>'image/gif');
    
    $fullpath =~ s/\||\.\.//g; # close pipeline exploit; CA 9-17-2004
    open(FILE,$fullpath);
    while (<FILE>) {
	print;
    }
    close(FILE);
}


