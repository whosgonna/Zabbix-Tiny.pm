#!/usr/bin/env perl
use strict;
use warnings;
use Test::More skip_all => "Jenkins abording when no tests exist.";
use Test::LWP::UserAgent;
use JSON;

use Test::Most;
use Test::Exception;

use_ok('Zabbix::Tiny');

my $url      = 'http://zabbix.domain.com/zabbix/bad_jsonrpc.php';

## It should be sufficent to set the header, then examine the process.
