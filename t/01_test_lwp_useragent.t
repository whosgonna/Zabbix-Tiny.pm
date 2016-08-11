#!/usr/bin/env perl
use strict;
use warnings;
use Zabbix::Tiny;
use Test::LWP::UserAgent;
use JSON;

use Test::More tests => 2;
use Test::Exception;

my $url      = 'http://zabbix.domain.com/zabbix/api_jsonrpc.php';
my $username = 'username';
my $password = 'P@ssword4ever';

my $useragent = Test::LWP::UserAgent->new;

# Create a new Zabbix::Tiny object
my $zabbix = Zabbix::Tiny->new(
    server   => $url,
    password => $password,
    user     => $username,
    ua       => $useragent,
);
my $authID = '0424bd59b807674191e7d77572075f33';
my $id;

$useragent->map_response(sub { 
        my $req = shift;
        my $content = decode_json($req->{_content});
        $id = $content->{id};
        if ($content->{method} eq 'user.login' and $content->{params}->{password} eq $password) {
            return 1;
        }
    },
    sub{
        my $req = shift;
        my $res = HTTP::Response->new( '200', 'OK',
            HTTP::Headers->new('content-type' => 'application/json'),
            qq({"jsonrpc":"2.0","result":"$authID","id":"$id"}),
        );
        return $res; #HTTP::Response->new(200);
    }
);

$useragent->map_response(sub {
        my $req = shift;
        my $content = decode_json($req->{_content});
        $id = $content->{id};
        if ($content->{method} eq 'user.login' and $content->{params}->{password} ne $password) {
            return 1;
        }
    },
    sub{
        my $req = shift;
        my $res = HTTP::Response->new( '200', 'OK',
            HTTP::Headers->new('content-type' => 'application/json'),
            qq({"jsonrpc":"2.0","error":{"code":-32602,"message":"Invalid params.","data":"Login name or password is incorrect."},"id":"$id"}),
        );
        return $res; #HTTP::Response->new(200);
    }
);



my $auth = $zabbix->login;

is($authID, $auth, 'AuthID extracted correctly.');
throws_ok( 
    sub{badpass( $url, $password, $username, $useragent )},
    qr/Error.*-32602.* Login name or password is incorrect/,
    'Correct handling of a bad user password.'
);






sub badpass {
    my $url = shift;
    my $user = shift;
    my $pass = shift;
    $pass    = substr( $pass, 0, -1 );

    my $zabbix_bad_pass = Zabbix::Tiny->new(
        server   => $url,
        user     => $user,
        password => $pass,
        ua       => $useragent,
    );
    $zabbix_bad_pass->login;
}
