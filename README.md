# NAME

Zabbix::Tiny - A small module to eliminate boilerplate overhead when using the Zabbix API

# SYNOPSIS

    use strict;
    use warnings;
    use Zabbix::Tiny;

    use Data::Dumper;

    my $username = 'zabbix_user';
    my $password = 'secretpassword';
    my $url = 'http://zabbix.domain.com/zabbix/api_jsonrpc.php';

    my $zabbix = Zabbix->new(
        server   => $url,
        password => $password,
        user     => $username
    );

    my $hosts = $zabbix->do(
        'host.get',  # First argument is the Zabbix API method
        output    => [qw(hostid name host)],  # Remaining paramters to 'do' are the params for the zabbix method.
        hostids   => [27,30]
        monitored => 1,
        limit     => 2,
        ## Any other params desired
    );

    print Dumper $hosts;


# DESCRIPTION

This module functions as a simple wrapper to eliminate boilerplate that might otherwise need to be
created when interfacing with the Zabbix API.  Login to the Zabbix server is handled with the 
constructor.  Beyond that, the primary method is the `do` method. The user.logout method is implemented 
in the object deconstructor as well, so there should be no need to explicity logout of Zabbix.

This module was developed against Zabbix 2.4, and is expected to work with Zabbix 2.2, and likely 2.0 
as well.  It is much less certain it will work with Zabbix 1.8.  Please refer to the API section 
of the Zabbix manual for details on its methods.

# METHOD

- my $zabbix = new( server => $url, password => $password, user => $username);

    The constructor requires server, user, and password.  It will create the zabbix object, and log in 
    to the server all at once.

- my $hosts = $zabbix->do('zabbix.method', %params);

    This will execute any defined zabbix method, with the corresponding params.  Refer to the Zabbix manual 
    for a list of available methods.  If the zabbix method is of a \*.get flavor, the return is an arrayref 
    data structure containing the response from the zabbix server.

- my $verbose = $zabbix->last\_response;

    Communication with the zabbix server is done via the `LWP` module.  The `do` method 
    contains a very succinct array ref that should contain only the data needed for interacting with the 
    zabbix server.  The `last_response` argument returns the LWP `HTTP::Response` object, 
    which may be useful for troubleshooting.

# BUGS and CAVEATS

Probaly bugs.

# See Also

Zabbix API Documentation: [https://www.zabbix.com/documentation/2.4/manual/api](https://www.zabbix.com/documentation/2.4/manual/api)

# COPYRIGHT

Zabbix::Tiny is Copyright (C) 2016, Ben Kaufman.

# License Information

This module is free software; you
can redistribute it and/or modify it under the same terms
as Perl 5.20.3.

This program is distributed in the hope that it will be
useful, but it is provided 'as is' and without any express
or implied warranties. 

# AUTHOR

Ben Kaufman
