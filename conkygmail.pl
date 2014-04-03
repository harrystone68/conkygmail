#!/usr/bin/perl -w
# gmailcheck.pl - check gmail unread feed 
# and format for display in root X window
#========================================
# config
#========================================
$URL = 'https://mail.google.com/mail/feed/atom';
$user = '<username>';
$pass = '<password>';
$ding = "/home/user/.ding"; # a file containing IDs of unread mail
$dingaudio = "/home/harry/bin/gmail.oga"; # audio file to play on new mail
$play = "/usr/bin/play -q"; # your command to play that audio file
#========================================
use LWP::UserAgent;
use XML::LibXML;
use Date::Manip;
no warnings 'experimental::smartmatch';
#========================================


open(DING, "<", $ding);
while (<DING>) {
    push(@ding, $_);
}
close(DING);

$ua = LWP::UserAgent->new();
$request =  HTTP::Request->new( GET => "$URL");
$request->authorization_basic("$user", "$pass");
$response = $ua->request($request);

$content = $response->content;
$parser = new XML::LibXML;
$xml = $parser->parse_string($content);
$xpc = XML::LibXML::XPathContext->new($xml);
$xpc->registerNs('ns', 'http://purl.org/atom/ns#');
$fullcount = $xpc->find('//ns:fullcount'); chomp($fullcount);
@entry = $xpc->findnodes('//ns:entry');

if ($fullcount ne "0") {
    while (@entry) {
        $entryelement = shift(@entry);
        $entryparser = new XML::LibXML;
        $entryxml = $entryparser->parse_string($entryelement);
        $title = $entryxml->find('//title');
        print "\nReceived mail:\n";
        print "----------------------------------------\n";
        $summary = $entryxml->find('//summary');
        #$modified = $entryxml->find('//modified');
        $issued = $entryxml->find('//issued');
        $id = $entryxml->find('//id');
        $authorname = $entryxml->find('//author/name');
        $authoremail = $entryxml->find('//author/email');
        $from = "$authorname "."("."$authoremail".")";
        $localdate = ParseDate("$issued");
        $printdate = UnixDate("$localdate", '%F %r');
        &CheckDing($id);
        push(@ids, $id);
        print "From: $from"." "."$printdate\n";
        print "Subject: $title\n";
        print "$summary\n";
        print "----------------------------------------\n";
    }
    open(DINGDONE, ">", $ding);
    while (@ids) {
        $idelement = pop(@ids);
        print DINGDONE "$idelement\n";
    }
    close(DINGDONE);

} else {
    open(DINGCLEAR, ">", $ding);
    print DINGCLEAR "";
    close(DINGCLEAR);
    print " - No new mail - \n";
}


#subs
#========================================
sub CheckDing {
    $idin = shift;
    if (/$idin/i ~~ @ding) {
        # fall
    } else {
        system("$play $dingaudio");
    }
}

