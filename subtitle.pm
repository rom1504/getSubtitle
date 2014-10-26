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

sub get_actual_subtitle_page
{
	my ($seriesListPageContent,$verbose)=@_;
	if(!($seriesListPageContent =~ /<a href="(\S+)" debug="[0-9]+">.+<\/a><\/td>/)) {bug("can't find the actual subtitle page url");}
	my $pageUrl="http://www.addic7ed.com/".$1;
	if($verbose) {print("actual subtitle page : ".$pageUrl."\n");}
	my $req=HTTP::Request->new(GET=>$pageUrl);
	my $res=$ua->request($req);
	my $page=$res->content;
	return $page;
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
	if($page =~ /results found/) {$page=get_actual_subtitle_page($page,$verbose);}
	my $maxDownloadSub="";
	my $rightVersionSub="";
	my $max=0;
	my $maxRightVersion=0;
	my $levVersionSub="";
	my $minLevDistance=99999;
	my $maxMinLev=0;
	while($page=~/Version (.+?), [0-9]+\.[0-9]+ MBs.+?<td width="21%" class="language">English<a href="javascript:saveFavorite.+?">.+?<a class="buttonDownload" href="(.+?)"><strong>(?:original|Download)<\/strong><\/a>(?:\s+<a class="buttonDownload" href="(.+?)"><strong>most updated<\/strong><\/a><\/td>)?.+?· ([0-9]+) Downloads/gs)
	{
		my $version=$1;
		my $originalDownloadLink=$2;
		my $mostUpdatedDownloadLink=$3;
		my $updatedDownloadLink=$mostUpdatedDownloadLink ne "" ? $mostUpdatedDownloadLink : $originalDownloadLink;
		my $numberOfDownload=$4;
		my $levDistance=distance($videoVersion,$version);
		if($numberOfDownload>$max)
		{
			$maxDownloadSub=$updatedDownloadLink;
			$max=$numberOfDownload;
		}
		if($verbose) {print("sub title version : ".$version." | ".$updatedDownloadLink." | ".$numberOfDownload." | ".$levDistance."\n");}
		if($numberOfDownload>$maxRightVersion && ($videoVersion =~ /$version/i || $version =~ /$videoVersion/i))
		{
			$rightVersionSub=$updatedDownloadLink;
			$maxRightVersion=$numberOfDownload;
			if($verbose) {print("sub title right version"."\n");}
		}
		if($levDistance<$minLevDistance || ($levDistance==$minLevDistance && $numberOfDownload>$maxMinLev))
		{
			$levVersionSub=$updatedDownloadLink;
			$minLevDistance=$levDistance;
			$maxMinLev=$numberOfDownload;
			if($verbose) {print("sub title lev version"."\n");}
		}
	}
	if($verbose) {print("Video version : ".$videoVersion."\n");}
	if($verbose) {print("Video file name : ".$videoFileName."\n");}
	if($verbose) {print("Max download file : ".$maxDownloadSub."\n");}
	if($verbose) {print("Right version file : ".$rightVersionSub."\n");}
	if($verbose) {print("Lev version file : ".$levVersionSub."\n");}
	my $sub=$rightVersionSub eq "" ? $levVersionSub : $rightVersionSub;
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
