#!/usr/bin/env perl
use strict;
use warnings;
use Zabbix::Tiny;
use Test::LWP::UserAgent;
use JSON;
use Data::Dumper;
use Data::Printer;

#use Test::More tests => 4;
#use Test::Exception;

my $url      = 'https://zabbix.atgncloud.com/api_jsonrpc.php';
my $username = 'username';
my $password = 'P@ssword4ever';

#my $useragent = Test::LWP::UserAgent->new;

# Create a new Zabbix::Tiny object
my $zabbix = Zabbix::Tiny->new(
    server   => $url,
    password => $password,
    user     => $username,
    #ua       => $useragent,
);


#print Dumper $zabbix;
my $auth = $zabbix->login;
print "\n\n";
#print Dumper $zabbix;
