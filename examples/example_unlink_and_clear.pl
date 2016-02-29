use strict;
use warnings;

# Unlinking and clearing a template in Zabbix can fail when PHP runs out of memory.
# This example has a hardcoded template ID. It finds all hosts, linked to that template, then unlinks and clears them
#  one by one.

use Zabbix::Tiny;
use Data::Dumper;

my $username = 'user';
my $password = 'password';
my $url = 'http://host/zabbix/api_jsonrpc.php';

my @hostids;
my $templateid = "13";

my $zabbix = Zabbix::Tiny->new(
    server   => $url,
    password => $password,
    user     => $username,
);

print "getting host IDs\n";
my $result = $zabbix->do(
    'host.get',
    output => "hostid",
    templateids => $templateid,
);

foreach my $host (@$result) {
    my $result_unlink = $zabbix->do(
        'host.update',
        hostid => $host->{hostid},
        templates_clear => $templateid,
    );
    print $zabbix->json_request;
    print Dumper($result_unlink);
}
