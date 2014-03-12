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
	my $url="http://www.addic7ed.com/search.php?search=".$videoFileName."&Submit=Search";
	my $req=HTTP::Request->new(GET=>$url);
	my $res=$ua->request($req);
	my $page=$res->content;
	if(!($page=~/<tr><td><img src="http:\/\/cdn\.addic7ed\.com\/images\/television\.png" \/><\/td><td><a href="(.+?)" debug="[0-9]+">.+?<\/a><\/td><\/tr>/)) {bug("get subtitle page");}
	my $subtitlePage=$1;
	return "http://www.addic7ed.com/".$subtitlePage;
	
}

sub get_subtitle
{
	my ($videoFileName)=@_;
	my $url=get_subtitle_page($videoFileName);
# 	print($url."\n");
	my $req=HTTP::Request->new(GET=>$url);
	my $res=$ua->request($req);
	my $page=$res->content;
	#print($page);
	my $sub="";
	while($page=~/<td width="21%" class="language">English<a href="javascript:saveFavorite.+?">.+?<a class="buttonDownload" href="(.+?)"><strong>(?:original|Download)<\/strong><\/a>(?:\s+<a class="buttonDownload" href="(.+?)"><strong>most updated<\/strong><\/a><\/td>)?/gs)
	{
		if($2 ne "") {$sub=$2;last;}
		$sub=$1;
	}
	if($sub eq "") {bug("get subtitle");}
	my $subtitle="http://www.addic7ed.com".$sub;
 	#print($subtitle."\n");
	my @a=split('\.',$videoFileName);
	pop(@a);
	my $subtitleFileName=join('.',@a).".en.srt";
	my $req=HTTP::Request->new(GET=>$subtitle);
	$req->header("Referer"=> $url);
	my $res=$ua->request($req);
	my $page=$res->content;
	open(my $subtitleFile,">".$subtitleFileName);
	print($subtitleFile $page);
}

1;