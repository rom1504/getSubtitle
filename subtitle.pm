package subtitle;

use strict;
use Encode;
use LWP::UserAgent;
use Text::Levenshtein qw(distance);
my $ua=LWP::UserAgent->new;
$ua->agent("MyApp/0.1 ");
$ua->timeout(30);

my $fake=0;

sub bug
{
	my ($msg)=@_;
	print(STDERR "bug $msg\n");
	exit 1;
}

sub get_subtitle_page
{
	my ($videoFileName)=@_;
	if(!($videoFileName =~ /s[0-9]+e[0-9]+/i)) {$videoFileName =~ s/([0-9])([0-9]{2})/S0$1E$2/;}
	return "http://www.addic7ed.com/search.php?search=".$videoFileName."&Submit=Search";
}

sub get_subtitle
{
	my ($videoFileName,$subtitleFileName,$verbose)=@_;
	if(!(defined $verbose)) {$verbose=0;}
	my $videoVersion=$videoFileName;
	if($videoFileName =~ /s[0-9]+e[0-9]+(.+)$/i) {$videoVersion=$1;}
	$videoVersion =~ s/\[.+$//;
	$videoVersion =~ s/HDTV//;
	$videoVersion =~ s/^\s+//;
	$videoVersion =~ s/\s+$//;
	my $url=get_subtitle_page($videoFileName);
	my $req=HTTP::Request->new(GET=>$url);
	my $res=$ua->request($req);
	my $page=$res->content;
	my $sub="";
	my $rightVersionSub="";
	my $max=0;
	my $maxRightVersion=0;
	while($page=~/Version (.+?), [0-9]+\.[0-9]+ MBs.+?<td width="21%" class="language">English<a href="javascript:saveFavorite.+?">.+?<a class="buttonDownload" href="(.+?)"><strong>(?:original|Download)<\/strong><\/a>(?:\s+<a class="buttonDownload" href="(.+?)"><strong>most updated<\/strong><\/a><\/td>)?.+?· ([0-9]+) Downloads/gs)
	{
		my $version=$1;
		my $originalDownloadLink=$2;
		my $mostUpdatedDownloadLink=$3;
		my $updatedDownloadLink=$mostUpdatedDownloadLink ne "" ? $mostUpdatedDownloadLink : $originalDownloadLink;
		my $numberOfDownload=$4;
		if($numberOfDownload>$max)
		{
			$sub=$updatedDownloadLink;
			$max=$numberOfDownload;
		}
		if($verbose) {print("sub title version : ".$version." | ".$updatedDownloadLink." | ".distance($videoVersion,$version)."\n");}
		if($numberOfDownload>$maxRightVersion && ($videoVersion =~ /$version/i || $version =~ /$videoVersion/i))
		{
			$rightVersionSub=$updatedDownloadLink;$maxRightVersion=$numberOfDownload;
			if($verbose) {print("sub title right version : ".$version." | ".$updatedDownloadLink."\n");}
		}
	}
	if($verbose) {print("Video version : ".$videoVersion."\n");}
	if($verbose) {print("Video file name : ".$videoFileName."\n");}
	if($verbose) {print("Right file : ".$rightVersionSub."\n");}
	$sub=$rightVersionSub eq "" ? $sub : $rightVersionSub;
	if($sub eq "") {bug("get subtitle");}
	my $subtitle="http://www.addic7ed.com".$sub;
	if($verbose) {print("Final file : ".$subtitle."\n");}
	if($subtitleFileName eq "")
	{
		my @a=split('\.',$videoFileName);
		pop(@a);
		$subtitleFileName=join('.',@a).".en.srt";
	}
	my $req=HTTP::Request->new(GET=>$subtitle);
	$req->header("Referer"=> $url);
	my $res=$ua->request($req);
	my $page=$res->content;
	open(my $subtitleFile,">".$subtitleFileName);
	print($subtitleFile $page);
}

1;