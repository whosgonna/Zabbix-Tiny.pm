package Zabbix::Tiny;
use strict;
use warnings;
use Moo;
use Carp;
use LWP;
use JSON;
use String::Random;

has 'server' => (
	is 	=> 'rw',
	required => 1,
);
has 'user' => (
	is	=> 'rw',
	required => 1,
);
has 'password' => (
	is	=> 'rw',
	required => 1,
);
has 'auth' => (
	is 	=> 'ro',
);
has 'ua' => (
	is	=> 'ro',
);
has 'last_response' => (
	is	=> 'ro',
);
has 'response_content' => (
	is	=> 'ro',
);

my @content_type = ('content-type', 'application/json',);


sub BUILD {
	my $self = shift;
	$self->{ua} = LWP::UserAgent->new;
	my $ua = $self->ua;
	my $url = $self->server;
	my $id = new String::Random;
	my $json_data = {
		jsonrpc => '2.0',
		id => $id->randpattern("nnnnnnnnnn"),
		method => 'user.login',
		params => {
			user    => $self->user,
			password => $self->password,
		},
	};
	my $json = encode_json($json_data);
	my $post_response = $ua->post($url, @content_type, Content => $json);
	$self->{last_response} = $ua->post($url, @content_type, Content => $json);
	$self->{response_content} = decode_json($self->{last_response}->{_content});
	if ($self->{response_content}->{error}) {
		my $error = $self->{response_content}->{error}->{data};
		croak("Error: $error");
	}
	$self->{auth} = $self->{response_content}->{'result'};
}


sub do {
	my $self = shift;
	my $method = shift;
	my %args = @_;
	my $id = new String::Random;
	my $ua = $self->ua;
	my $auth = $self->auth;
	my $url = $self->server;
	my $json_data = {
		jsonrpc => '2.0',
		id 	=> $id->randpattern("nnnnnnnnnn"),
		method 	=> $method,
		auth	=> $auth,
		params 	=> \%args,
	};
	my $json = encode_json($json_data);
	my $post_response = $ua->post($url, @content_type, Content => $json);
	$self->{last_response} = $ua->post($url, @content_type, Content => $json);
	$self->{response_content} = decode_json($self->{last_response}->{_content});
	if ($self->{response_content}->{error}) {
		my $error = $self->{response_content}->{error}->{data};
		croak("Error: $error");
	}
	return $self->{response_content}->{'result'};
}


sub DEMOLISH {
	my $self = shift;
	my $method = shift;
	my $id = new String::Random;
	my $ua = $self->ua;
	my $auth = $self->auth;
	my $url = $self->server;
	my $json_data = {
		jsonrpc => '2.0',
		id      => $id->randpattern("nnnnnnnnnn"),
		method  => 'user.logout',
		auth    => $auth,
	};
	my $json = encode_json($json_data);
	$self->{last_response} = $ua->post($url, @content_type, Content => $json);
}


1;



__END__

=pod

=encoding UTF-8

=head1 NAME

Zabbix::Tiny - A small module to eliminate boilerplate overhead when using the Zabbix API

=head1 VERSION

0.500

=head1 SYNOPSIS

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
  
=head1 DESCRIPTION

This module functions as a simple wrapper to eliminate boilerplate that might otherwise need to be
created when interfacing with the Zabbix API.  Login to the Zabbix servre is handled with the 
constructor.  Beyond that, the primary method is the C<do> method. The user.logout method is implemented 
in the object deconstructor as well, so there should be no need to explicity logout of zabbix.

=head1 METHOD

=over 4

=item my $zabbix = new( server => $url, password => $password, user => $username);

The constructor requires server, user, and password.  It will create the zabbix object, and log in 
to the server all at once.

=item my $hosts = $zabbix->do('zabbix.method', %params);

This will execute any defined zabbix method, with the corresponding params.  Refer to the Zabbix manual 
for a list of available methods.  If the zabbix method is of a *.get flavor, the return is an arrayref 
data structure containing the response from the zabbix server.

=item my $verbose = $zabbix->last_response;

Communication with the zabbix server is done via the C<LWP> module.  The C<do> method 
contains a very succinct array ref that should contain only the data needed for interacting with the 
zabbix server.  The C<last_response> argument returns the LWP C<HTTP::Response> object, 
which may be useful for troubleshooting.

=back

=head1 BUGS and CAVEATS

Probaly many bugs.

=head1 COPYRIGHT

BSD License

=head1 AUTHOR
Ben Kaufman


