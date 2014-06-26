use strict;
use warnings;
use URI;
use HTTP::Request;
use LWP::UserAgent;
use JSON::XS;
use Encode qw{encode_utf8 decode_utf8};
use utf8;
use Path::Class qw/dir file/;
use Digest::MD5 qw/md5_hex/;
use Term::ANSIColor;

#BASIC 認証の ID とパスをスカラーに入れる
my $id = 'e145713@ie.u-ryukyu.ac.jp';
my $key = 'rKvTrPhgr8xfVyk8HQVZFqacDc19570cYBsiQ14Wk/g';
my $uri = URI->new('https://api.datamarket.azure.com/Bing/Search/v1/Image');
my $dir = dir('./data');

mkdir "./data" unless -f $dir;

my $pagecnt = 0;
my $dlcnt = 0;

while(1){
my $skip = $pagecnt * 50;
$uri->query_form(
    Query => "'おっぱい'",
    Market => "'ja-JP'",
    Adult => "'off'",
    '$top'    => 50, 
    '$skip'   => $skip,
    '$format' => "JSON",
    );

my $ua = LWP::UserAgent->new;

my $req = HTTP::Request->new('GET' => $uri);
 
$req->authorization_basic($id, $key);

my $res = $ua->request($req);
die $res->status_line if $res->is_error;

my $json_text = $res->content;
my $ref = decode_json($json_text);

for(@{$ref->{d}{results}}){
	my $imageurl = $_->{MediaUrl};
	next unless $imageurl =~ /\.jpg$/; #リクエストされたimgがjpgじゃない場合 nextでスキップ
	$dlcnt++;
	my $filename = md5_hex(encode_utf8($imageurl)) . '.jpg';
    my $filepath = $dir->file($filename);
    print color("cyan"),"$dlcnt : download... ",color("reset"), encode_utf8("$imageurl\n");
        $res = $ua->get(
            $imageurl,
            ':content_file' => $filepath->stringify
        );
        unless ($res->content_type =~ m/^image/) {
            unlink $filepath;
        }
   }
$pagecnt++;
}

