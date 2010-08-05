use strict;
use warnings;
package Net::Dynect;
use REST::Client;
use JSON;
use Data::Dumper;
use Net::Dynect::Resource;
#ABSTRACT: Implentation of the Dynect API (https://manage.dynect.net/help/docs/api2/rest/)

use Moose;
use namespace::autoclean;

has base_uri => (isa => 'Str', is => 'ro', default => 'https://api2.dynect.net/REST/');
has customer => (isa => 'Str', is => 'ro', required => 1);
has username => (isa => 'Str', is => 'ro', required => 1);
has password => (isa => 'Str', is => 'ro', required => 1);
has zone     => (isa => 'Str', is => 'ro', required => 1);
has c        => (isa => 'REST::Client', is => 'ro', lazy_build => 1);


=method resource
    Create a new resource object
    resource(type => "", ttl => "", ..); where 'type' is in
    AAAA A CNAME DNSKEY DS KEY LOC MX NS PTR RP SOA SRV TXT
=cut

sub resource {
    my($self, %arg) = @_;
    return Net::Dynect::Resource->new(dynect => $self, %arg);
}


=method login
    Login to Dynect - must be done before any other methods called. (Automatically called @ build)
    See: https://manage.dynect.net/help/docs/api2/rest/resources/Session.html
=cut 

sub login {
    my ($self) = @_;
    my $r = $self->post('Session', 
        { 'customer_name' => $self->customer, 
          'user_name'     => $self->username, 
          'password' => $self->password
    });
    $self->c->addHeader('Auth-Token', $r->{token});
    return $r;
}

=method logout
    Logout from Dynect - must be done last. (Automatically called @ destructor time)
    See: https://manage.dynect.net/help/docs/api2/rest/resources/Session.html
=cut 

sub logout {
    my ($self) = @_;
    $self->delete('Session');
}

=method get_zone
    Get zone from dynect
    See: https://manage.dynect.net/help/docs/api2/rest/resources/Zone.html
    Optionally pass zone argument, else $self->zone is used
=cut

sub get_zone {
    my ($self, $zone) = @_;
    $zone ||= $self->zone;
    $self->get("Zone/$zone");
}

=method publish
    Publish zone to dynect. Required to make alterations permanent
    See: https://manage.dynect.net/help/docs/api2/rest/resources/Zone.html
    Optionally pass zone argument, else $self->zone is used
=cut

sub publish {
    my($self, $zone) = @_;
    $zone ||= $self->zone;
    $self->put("Zone/$zone", { publish => 'true' });
}

=method freeze
    Freeze zone. Prevents other changes happening to it.
    See: https://manage.dynect.net/help/docs/api2/rest/resources/Zone.html
    Optionally pass zone argument, else $self->zone is used
=cut

sub freeze {
    my($self, $zone) = @_;
    $zone ||= $self->zone;
    $self->put("Zone/$zone", { freeze => 'true' });
}

=method thaw
    Thaw zone. Allows changes to happen to it again.
    See: https://manage.dynect.net/help/docs/api2/rest/resources/Zone.html
    Optionally pass zone argument, else $self->zone is used
=cut

sub thaw {
    my($self, $zone) = @_;
    $zone ||= $self->zone;
    $self->put("Zone/$zone", { thaw => 'true' });
}

sub get {
    my($self, $uri) = @_;
    return $self->_req(type => 'GET', uri => $uri);
}

sub delete {
    my($self, $uri) = @_;
    return $self->_req(type => 'DELETE', uri => $uri);
}

sub put {
    my($self, $uri, $content) = @_;
    return $self->_req(type => 'PUT', uri => $uri, content => $content);
}

sub post {
    my($self, $uri, $content) = @_;
    return $self->_req(type => 'POST', uri => $uri, content => $content);
}

sub _req {
    my ($self, %arg) = @_;
    my $content = undef;
    if(ref($arg{content}) eq "HASH") {
        $content = to_json($arg{content});
    } elsif(defined($arg{content})) {
        $content = $arg{content};
    }
    my $r = $self->c->request(uc($arg{type}), $self->base_uri . $arg{uri}, $content);

    # If a job takes a while, we'll get a 307 and the body is the Job URI to poll
    # This may recurse for a while. TODO check depth
    if($r->responseCode() == 307) {
        return $self->get($r->responseContent());
    }

    my $rv = from_json($r->responseContent());

    print Dumper($rv); # DEBUG

    if($rv->{status} eq "success") {
        return $rv->{data};
    } else {
        die "Request Failed: " . Dumper($rv->{msgs}) . "\n";
    }
}

sub BUILD {
    my ($self) = @_;
    $self->login();
}

sub DEMOLISH {
    my ($self) = @_;
    $self->logout();
}

sub _build_c {
    my ($self) = @_;
    my $c = REST::Client->new();
    $c->addHeader('Content-Type', 'application/json');
    return $c;
}



=head1 synopsis

my $dyn = Net::Dynect->new(customer => "", username => "", password => "", zone => "");
$dyn->r(type => "A", fqdn => "", ttl => "", address => "")->save();
$dyn->publish;

=cut


__PACKAGE__->meta->make_immutable;
1;
