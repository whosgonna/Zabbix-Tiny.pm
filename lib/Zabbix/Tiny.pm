package Zabbix::Tiny;
use strict;
use warnings;
use Moo;
use Carp;
use LWP;
use JSON;
use String::Random;

our $VERSION = "1.04";

has 'server' => (
    is       => 'rw',
    required => 1,
);
has 'user' => (
    is       => 'rw',
    required => 1,
);
has 'password' => (
    is       => 'rw',
    required => 1,
);
has 'auth'				=> ( is => 'ro', );
has 'ua'				=> ( is => 'ro', );
has 'post_response'		=> ( is => 'ro');
has 'last_response'		=> ( is => 'ro', );
has 'json_request'		=> ( is => 'ro');
has 'json_response'		=> ( is => 'ro');
has 'verify_hostname'	=> ( is => 'rw', default => sub {1} );
has 'ssl_opts'			=> ( is => 'rw');

my @content_type = ( 'content-type', 'application/json', );

sub BUILD {
    my $self = shift;
    $self->{ua} = LWP::UserAgent->new;
    my $ua        = $self->ua;
    my $url       = $self->server;
    my $id        = new String::Random;
    my $json_data = {
        jsonrpc => '2.0',
        id      => $id->randpattern("nnnnnnnnnn"),
        method  => 'user.login',
        params  => {
            user     => $self->user,
            password => $self->password,
        },
    };
	if ($self->verify_hostname == 0) {
		$ua->ssl_opts(verify_hostname => 0);
	}
	
	if ($self->ssl_opts) {
		$ua->ssl_opts(%{ $self->{ssl_opts} });
	}

    my $json = encode_json($json_data);
    $self->{post_response} = $ua->post( $url, @content_type, Content => $json );
	if ($self->{post_response}->{_rc} !~ /2\d\d/) {
		die("$self->{post_response}->{_msg}");
	}
	$self->{json_request} = $self->{post_response}->{'_request'}->{_content};
	$self->{json_response} = $self->{post_response}->{_content};
    $self->{last_response} =
      decode_json( $self->{post_response}->{_content} ) or die ($!);
    if ( $self->{last_response}->{error} ) {
        my $error = $self->{last_response}->{error}->{data};
        croak("Error: $error");
    }
    $self->{auth} = $self->{last_response}->{'result'};
}

sub do {
    my $self      = shift;
    my $method    = shift;
    my %args      = @_;
    my $id        = new String::Random;
    my $ua        = $self->ua;
    my $auth      = $self->auth;
    my $url       = $self->server;
    my $json_data = {
        jsonrpc => '2.0',
        id      => $id->randpattern("nnnnnnnnnn"),
        method  => $method,
        auth    => $auth,
        params  => \%args,
    };
    my $json = encode_json($json_data) or die($!);
    $self->{post_response} = $ua->post( $url, @content_type, Content => $json );
	$self->{json_request} = $self->{post_response}->{'_request'}->{_content};
	$self->{json_response} = $self->{post_response}->{_content};
    $self->{last_response} =
      decode_json( $self->{post_response}->{_content} );

    if ( $self->{last_response}->{error} ) {
        my $error = $self->{last_response}->{error}->{data};
        croak("Error: $error");
    }
    return $self->{last_response}->{'result'};
}

sub DEMOLISH {
    my $self      = shift;
    my $method    = shift;
    my $id        = new String::Random;
    my $ua        = $self->ua;
    my $auth      = $self->auth;
    my $url       = $self->server;
    my $json_data = {
        jsonrpc => '2.0',
        id      => $id->randpattern("nnnnnnnnnn"),
        method  => 'user.logout',
        auth    => $auth,
    };
    my $json = encode_json($json_data);
    $self->{post_response} = $ua->post( $url, @content_type, Content => $json );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Zabbix::Tiny - A small module to eliminate boilerplate overhead when using the Zabbix API

=head1 SYNOPSIS

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
  
  
=head1 DESCRIPTION

This module functions as a simple wrapper to eliminate boilerplate that might otherwise need to be created when interfacing with the Zabbix API.  Login to the Zabbix server is handled with the constructor. Beyond that, the primary method is the C<do> method. The user.logout method is implemented  in the object deconstructor as well, so there should be no need to explicity logout of Zabbix.

This module was developed against Zabbix 2.4, and is expected to work with Zabbix 2.2, and likely 2.0 as well.  It is much less certain it will work with Zabbix 1.8.  Please refer to the API section of the Zabbix manual for details on its methods.

=head1 METHODS

=head2 PRIMARY METHODS

=over 4

=item my $zabbix = Zabbix::Tiny->new( server => $url, password => $password, user => $username, [ssl_opts => {%ssl_opts}]);

The constructor requires server, user, and password.  It will create the Zabbix::Tiny object, and log in to the server all at once.  The C<ssl_opts> argument can be set to set the LWP::UserAgent ssl_opts attribute when connecting to https with a self-signed or otherwise un-trusted certificate (see note about untrusted certificates below).

=item my $hosts = $zabbix->do('zabbix.method', %params);

This will execute any defined Zabbix method, with the corresponding params.  Refer to the Zabbix manual for a list of available methods.  If the Zabbix method is of a *.get flavor, the return is an arrayref data structure containing the response from the Zabbix server.

=back

=head2 DEBUGGING METHODS

The Zabbix::Tiny C<do> method contains a very succinct arrayref that should contain only the data needed for interacting with the Zabbix server, so there should be little need to worry about serializing json, managing the Zabbix auth token, etc., however these methods are provided for convenience.

=over 4

=item my $auth = $zabbix->auth;

The main purpose of this module is to hide away the need to track the authentication token in the script.  With that in mind, the token used can be retrieved with this method if needed.

=item my $json_request = $zabbix->json_request;

Used to retrieve the last raw json message sent to the Zabbix server, including the "jsonrpc", "id", and "auth".

=item my $json_response = $zabbix->json_response;

Used to retrieve the last raw json message from the zabbix server,  including the "jsonrpc", "id", and "auth".

=item my $verbose = $zabbix->last_response;

Similar to json_response, but the last response message as a perl data structure (hashref).

=item my $post_response = $zabbix->post_response;

The L<HTTP::Response> from the Zabbix server for the most recent request.

=back

=head1 BUGS and CAVEATS

Probably bugs.

=head1 NOTES

=head2 Untrusted Certificates

In many cases it is expected that zabbix servers may be using self-signed or otherwise 'untrusted' certiifcates.  The ssl_opts argument in the constructor can be set to any valid values for LWP::UserAgent to disallow certificate checks.  For example:

  use strict;
  use warnings;
  use Zabbix::Tiny;
  use IO::Socket::SSL;

  my $zabbix =  Zabbix::Tiny->new(
      server   => $url,
      password => $password,
      user     => $username,
      ssl_opts => {
          verify_hostname => 0, 
          SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE
      },
  );
 

=head1 See Also

Zabbix API Documentation: L<https://www.zabbix.com/documentation/2.4/manual/api>

=head1 COPYRIGHT

Zabbix::Tiny is Copyright (C) 2016, Ben Kaufman.

=head1 License Information

This module is free software; you can redistribute it and/or modify it under the same terms as Perl 5.20.3.

This program is distributed in the hope that it will be useful, but it is provided 'as is' and without any express or implied warranties. 

=head1 AUTHOR

Ben Kaufman


