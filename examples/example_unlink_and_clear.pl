#!/usr/bin/env perl
use strict;
use warnings;
use Zabbix::Tiny;

## Unlinking and clearing a template in Zabbix can fail when PHP runs out of memory.
## This example has a hardcoded template ID. It finds all hosts, linked to that
## template, then unlinks and clears them one by one.
## To find the $templateid to be used, open the template in the zabbix front end
## and get the value from the 'templateid=xxxxx' portion of the URL.

my $username   = 'user';
my $password   = 'password';
my $url        = 'http://host/zabbix/api_jsonrpc.php';
my $templateid = '13';

my $zabbix = Zabbix::Tiny->new(
    server   => $url,
    password => $password,
    user     => $username,
);

print "Getting hosts linked to templateid $templateid...\n";
my $result = $zabbix->do(
    'host.get',
    output      => [ 'hostid', 'name' ],
    templateids => $templateid,
);

for my $host (@$result) {
    print "\n$host->{name}\n";
    my $result_unlink = $zabbix->do(
        'host.update',
        hostid          => $host->{hostid},
        templates_clear => $templateid,
    );
    print "Request: - " . $zabbix->json_request . "\n";
    print "Response: - " . $zabbix->json_response . "\n";
}
