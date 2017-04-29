#!/usr/bin/env perl
use strict;
use warnings;
use Zabbix::Tiny;
use Test::LWP::UserAgent;
use JSON;

use Test::More;
use Test::Exception;

use Data::Printer;

my $url      = 'http://zabbix.domain.com/zabbix/api_jsonrpc.php';
my $username = 'username';
my $badpass  = 'badpass';
my $goodpass = 'goodpass';

my $useragent = Test::LWP::UserAgent->new;

# Create a new Zabbix::Tiny object
my $zabbix = Zabbix::Tiny->new(
    server   => $url,
    password => $badpass,
    user     => $username,
    ua       => $useragent,
);
my $authID = '0424bd59b807674191e7d77572075f33';
my $id;
p $zabbix;


## valid user.login:
$useragent->map_response(sub {
        my $req = shift;
        my $content = decode_json($req->{_content});
        $id = $content->{id};
        return 1 if (
            $content->{method} eq 'user.login'
            and $content->{params}->{password} eq $goodpass
        );
    },
    sub{
        my $req = shift;
        my $res = HTTP::Response->new( '200', 'OK',
            HTTP::Headers->new('content-type' => 'application/json'),
            encode_json({
                jsonrpc => '2.0',
                result  => $authID,
                id      => $id,
            }),
            #qq({"jsonrpc":"2.0","result":"$authID","id":"$id"}),
        );
        return $res; #HTTP::Response->new(200);
    }
);

## invalid user.login:
$useragent->map_response(sub {
        my $req = shift;
        my $content = decode_json($req->{_content});
        $id = $content->{id};
        return 1 if (
            $content->{method} eq 'user.login'
            and $content->{params}->{password} ne $goodpass
        );
    },
    sub{
        my $req = shift;
        my $res = HTTP::Response->new( '200', 'OK',
            HTTP::Headers->new('content-type' => 'application/json'),
            encode_json({
                jsonrpc => '2.0',
                id      => $id,
                error   => {
                    code    => -32602,
                    message => 'Invalid params.',
                    data    => 'Login name or password is incorrect.'
                },
            }),
            #qq({"jsonrpc":"2.0","error":{"code":-32602,"message":"Invalid params.","data":"Login name or password is incorrect."},"id":"$id"}),
        );
        return $res; #HTTP::Response->new(200);
    }
);



my $auth = $zabbix->login;

is($authID, $auth, 'AuthID extracted correctly.');
throws_ok(
    sub{badpass( $url, $badpass, $username, $useragent )},
    qr/Error.*-32602.* Login name or password is incorrect/,
    'Correct handling of a bad user password.'
);



done_testing();


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
