use strict;
use warnings;
package Net::Dynect::Resource;
use Net::Dynect;
#ABSTRACT: Implentation of the Dynect API Resources (https://manage.dynect.net/help/docs/api2/rest/)

use Moose;
use namespace::autoclean;

has type     => (isa => 'Str', is => 'ro', required => 1);
has fqdn     => (isa => 'Str', is => 'rw');
has id       => (isa => 'Int', is => 'rw');
has ttl      => (isa => 'Int', is => 'rw');
has dynect   => (isa => 'Net::Dynect', is => 'ro', required => 1);


sub BUILD {
    my ($self) = @_;
    $self->login();
}

sub DEMOLISH {
    my ($self) = @_;
    $self->logout();
}


=head1 synopsis

Not to be used directly. Use as part of Net::Dynect.

=cut


__PACKAGE__->meta->make_immutable;
1;
