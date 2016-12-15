#!/usr/bin/env perl
use strict;
use warnings;
use lib "lib/";
use Zabbix::Tiny;
use Test::LWP::UserAgent;
use JSON;

#use Test::More tests => 1;
#use Test::Exception;

use Data::Printer;

my $url      = 'http://zabbix.domain.com/zabbix/api_jsonrpc.php';
my $username = 'username';
my $password = 'P@ssword4ever';

my $useragent = Test::LWP::UserAgent->new;

# Create a new Zabbix::Tiny object
my $zabbix = Zabbix::Tiny->new(
    server   => $url,
    password => $password,
    user     => $username,
    ## Use of ua here allows for the Test::LWP::UserAgent, rather than the 
    ## real LWP::UserAgent.  This should only be done in tests.
    ua       => $useragent,
);

## An auth ID that can be retuned by the Test::LWP::UserAgent
my $authID = '0424bd59b807674191e7d77572075f33';
my $id;
my $response = $zabbix->do('apiinfo.version');
p $zabbix->post_response;
exit;

my $expected = $zabbix->json_response;

$useragent->map_response(
    sub {
        my $req = shift;
        my $content = decode_json($req->{_content});
        $id = $content->{id};
        if ($content->{method} ne 'apiinfo.version') {
            return 0;
        }
        if ($content->{auth}) {
            return 1;
        }
    },
    sub {
        print "apiinfo.version without auth string (wrong!)\n";
        my $req = shift;
        my $message = qq({"jsonrpc":"2.0","error":{"code":-32602,"message":"Invalid params.","data":"The \\"apiinfo.version\\" method must be called without the \\"auth\\" parameter."},"id":"$id"});
        my $res = HTTP::Response->new( '200', 'OK',
            HTTP::Headers->new('content-type' => 'application/json'),
            $message,
        );
        return $res;
    }
);

$useragent->map_response(
    sub {
        my $req = shift;
        my $content = decode_json($req->{_content});
        $id = $content->{id};
        if ($content->{method} ne 'apiinfo.version') {
            return 0;
        }
        if (!$content->{auth}) {
            return 1;
        }
    },
    sub {
        print "apiinfo.version without auth string (correct)\n";
        my $req = shift;
        my $message = qq({"jsonrpc":"2.0","result":"3.2.1","id":$id});
        my $res = HTTP::Response->new( '200', 'OK',
            HTTP::Headers->new('content-type' => 'application/json'),
            $message,
        );
        return $res;
    }
);



my $resp_ok =  qq({"jsonrpc":"2.0","result":"3.2.1","id":$id});
#my $version = $zabbix->do('apiinfo.version');



#is($expected, $resp_ok, 'AuthID extracted correctly.');
#throws_ok( 
#    sub{badpass( $url, $password, $username, $useragent )},
#    qr/Error.*-32602.* Login name or password is incorrect/,
#    'Correct handling of a bad user password.'
#);






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

sub apiinfo_version {
    my $url = shift;
    my $user = shift;
    my $pass = shift;
    my $zabbix_apiinfo_version = Zabbix::Tiny->new(
        server   => $url,
        user     => $user,
        password => $pass,
        ua       => $useragent,
    );
    $zabbix_apiinfo_version->do('apiinfo_version');
    $zabbix_apiinfo_version->json_response;
}


