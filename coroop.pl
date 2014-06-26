use strict;
use warnings;
use utf8;
use URI;
use HTTP::Request;
use Coro;
use Coro::LWP;
use LWP::UserAgent;
use JSON::XS;
use Encode qw/encode_utf8/;
use Path::Class qw/dir file/;
use Digest::MD5 qw/md5_hex/;
use Term::ANSIColor;

#BASIC 認証の ID とパスをスカラーに入れる
my $id = 'e145713@ie.u-ryukyu.ac.jp'; #メールアドレス
my $key = 'rKvTrPhgr8xfVyk8HQVZFqacDc19570cYBsiQ14Wk/g'; #AppId
my $uri = URI->new('https://api.datamarket.azure.com/Bing/Search/v1/Image');
my $dir = dir('./data');

mkdir $dir unless -f $dir;

my $query = @ARGV ? $ARGV[0] : 'おっぱい';
#if($ARGV[0] =~ m/h|-h/){
    #print color('on_red'),"-",color('reset') for 1..70;
    #print "\n\n";
    #print color('magenta'),"Image download script (Perl) ver 0.2\n";
    #print "I affected in http://yusukebe.com/archives/20120229/072808.html\n\n";
    #print colored("HOW TO USE?\n\n",'cyan');
    #print " ";
    #print colored("-",'green') for 1..25;
    #print "\n";
    #print colored("|  % coroimgdl.#pl \"query\" |\n",'green');
    #print " ";
    #print colored("-",'green') for 1..25;
    #print "\n\n";    
    #print color('on_blue'),"Downloaded items are send to data folder.",color('reset');
    #print "\n\n";
    #print color('on_red'),"-",color('reset') for 1..70;
    #print "\n\n";
    #exit;
#} 

my $pagecnt = 0;
my $dlcnt = 0;

while(1){
my $skip = $pagecnt * 50; #50はダウンロードの間隔
$uri->query_form(
    Query => "'$query'",
    Market => "'ja-JP'",
    Adult => "'off'",
    '$top'    => 50, 
    '$skip'   => $skip,
    '$format' => "JSON",
    );

my $ua = LWP::UserAgent->new;

my $req = HTTP::Request->new('GET' => $uri);
 
$req->authorization_basic($id, $key); #basic認証

my $res = $ua->request($req);
die $res->status_line if $res->is_error;

my $json_text = $res->content;
my $ref = decode_json($json_text);

my @coros; #Coro追加
for(@{$ref->{d}{results}}){
	my $imageurl = $_->{MediaUrl};
	next unless $imageurl =~ /\.jpg$|\.png$/; #リクエストされたimgがjpgかpngじゃない場合 nextでスキップ
	$dlcnt++;
	my $filename = md5_hex(encode_utf8($imageurl)) . '.png'; #png出力
    my $filepath = $dir->file($filename);
    print "$dlcnt : download... ",encode_utf8("$imageurl\n");
    #Coro追加
     push @coros, async {
        $res = $ua->get(
            $imageurl,
            ':content_file' => $filepath->stringify
        );

        unlink $filepath unless $res->content_type =~ m/^image/;
    };
 }
   $_->join for @coros; #coro追加
   $pagecnt++;
}
