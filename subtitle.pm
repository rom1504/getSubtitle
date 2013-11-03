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
	my $url="http://www.addic7ed.com/search.php?search=".$videoFileName."&Submit=Search";
	my $req=HTTP::Request->new(GET=>$url);
	my $res=$ua->request($req);
	my $page=$res->content;
	if(!($page=~/<tr><td><img src="images\/television.png" \/><\/td><td><a href="(.+?)" debug="[0-9]+">.+?<\/a><\/td><\/tr>/)) {bug("get subtitle page");}
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
	if(!($page=~/<td width="21%" class="language">English<a href="javascript:saveFavorite.+?">.+?<a class="buttonDownload" href="(.+?)"><strong>/s)) {bug("get subtitle");}
	my $subtitle="http://www.addic7ed.com".$1;
# 	print($subtitle."\n");
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