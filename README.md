# NAME

Zabbix::Tiny - A small module to eliminate boilerplate overhead when using the Zabbix API

# SYNOPSIS

    use strict;
    use warnings;
    use Zabbix::Tiny;

    use Data::Dumper;

    my $username = 'zabbix_user';
    my $password = 'secretpassword';
    my $url = 'https://zabbix.domain.com/zabbix/api_jsonrpc.php';

    my $zabbix = Zabbix::Tiny->new(
        server   => $url,
        password => $password,
        user     => $username
    );

    my $hosts = $zabbix->do(
        'host.get',  # First argument is the Zabbix API method
        output    => [qw(hostid name host)],  # Remaining paramters to 'do' are the params for the zabbix method.
        monitored => 1,
        limit     => 2,
        ## Any other params desired
    );

    # Print some of the retreived information.
    for my $host (@$hosts) {
        print "Host ID: $host->{hostid} - Display Name: $host->{name}\n";
    }
    
    # Debugging methods:
    print "JSON request:\n" . $zabbix->json_request . "\n\n";   # Print the json data sent in the last request.
    print "JSON response:\n" . $zabbix->json_response . "\n\n"; # Print the json data received in the last response.
    print "Auth is: ". $zabbix->auth . "\n";

    print "\$zabbix->last_response:\n";
    print Dumper $zabbix->last_response;
    
    print "\$zabbix->post_response:\n";
    print Dumper $zabbix->post_response; # Very verbose.  Probably unnecessary.  
    
    

# DESCRIPTION

This module functions as a simple wrapper to eliminate boilerplate that might otherwise need to be created when interfacing with the Zabbix API.  Login to the Zabbix server is handled with the constructor. Beyond that, the primary method is the `do` method. The user.logout method is implemented  in the object deconstructor as well, so there should be no need to explicity logout of Zabbix.

This module was developed against Zabbix 2.4, and is expected to work with Zabbix 2.2, and likely 2.0 as well.  It is much less certain it will work with Zabbix 1.8.  Please refer to the API section of the Zabbix manual for details on its methods.

# METHODS

## PRIMARY METHODS

- my $zabbix = new( server => $url, password => $password, user => $username, \[verify\_hostname => 0\]);

    The constructor requires server, user, and password.  It will create the zabbix object, and log in to the server all at once.  The `verify_hostname` argument can be set to 0 to skip validating the certificate when connecting to https with a self-signed or otherwise un-trusted certificate.

- my $hosts = $zabbix->do('zabbix.method', %params);

    This will execute any defined zabbix method, with the corresponding params.  Refer to the Zabbix manual for a list of available methods.  If the zabbix method is of a \*.get flavor, the return is an arrayref data structure containing the response from the zabbix server.

## DEBUGGING METHODS

The Zabbix::Tiny `do` method contains a very succinct array ref that should contain only the data needed for interacting with the zabbix server, so there should be little need to worry about serializing json, managing the Zabbix auth token, etc., however these methods are provided for convenience.

- my $auth = $zabbix->auth;

    The main purpose of this module is to hide away the need to track the authentication token in the script.  With that in mind, the token used can be retrieved with this method if needed.

- my $json\_request = $zabbix->json\_request;

    used to retrieve the last raw json message sent to the Zabbix server, including the "jsonrpc", "id", and "auth".

- my $json\_response = $zabbix->json\_response;

    Used to retrieve the last raw json message from the zabbix server,  including the "jsonrpc", "id", and "auth".

- my $verbose = $zabbix->last\_response;

    Similar to json\_response, but the last response message as a perl data structure (hashref).

- my $post\_response = $zabbix->post\_response;

    The [HTTP::Response](https://metacpan.org/pod/HTTP::Response) from the Zabbix server for the most recent request.

# BUGS and CAVEATS

Probaly bugs.

# See Also

Zabbix API Documentation: [https://www.zabbix.com/documentation/2.4/manual/api](https://www.zabbix.com/documentation/2.4/manual/api)

# COPYRIGHT

Zabbix::Tiny is Copyright (C) 2016, Ben Kaufman.

# License Information

This module is free software; you can redistribute it and/or modify it under the same terms as Perl 5.20.3.

This program is distributed in the hope that it will be useful, but it is provided 'as is' and without any express or implied warranties. 

# AUTHOR

Ben Kaufman
