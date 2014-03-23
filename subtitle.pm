package subtitle;

use strict;
use Encode;
use LWP::UserAgent;
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
	$videoFileName =~ s/([0-9])([0-9]{2})/S0$1E$2/;
	return "http://www.addic7ed.com/search.php?search=".$videoFileName."&Submit=Search";
	
}

sub get_subtitle
{
	my ($videoFileName,$subtitleFileName)=@_;
	my $url=get_subtitle_page($videoFileName);
 	#print($url."\n");
	my $req=HTTP::Request->new(GET=>$url);
	my $res=$ua->request($req);
	my $page=$res->content;
	my $sub="";
	my $rightVersionSub="";
	my $max=0;
	my $maxRightVersion=0;
	while($page=~/Version (.+?), [0-9]+.00 MBs.+?<td width="21%" class="language">English<a href="javascript:saveFavorite.+?">.+?<a class="buttonDownload" href="(.+?)"><strong>(?:original|Download)<\/strong><\/a>(?:\s+<a class="buttonDownload" href="(.+?)"><strong>most updated<\/strong><\/a><\/td>)?.+?· ([0-9]+) Downloads/gs)
	{
		if($4>$max)
		{
			if($3 ne "") {$sub=$3;}
			else {$sub=$2;}
			$max=$4;
		}
		if($4>$maxRightVersion && $1 =~ /$videoFileName/i) {$rightVersionSub=$sub;$maxRightVersion=$4;}
	}
	$sub=$rightVersionSub eq "" ? $sub : $rightVersionSub;
	if($sub eq "") {bug("get subtitle");}
	my $subtitle="http://www.addic7ed.com".$sub;
# 	print($subtitle."\n");
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