use strict;
use warnings;
package Net::Dynect::Resource;
use Net::Dynect;
use Data::Dumper;
#ABSTRACT: Implentation of the Dynect API Resources (https://manage.dynect.net/help/docs/api2/rest/)

use Moose;
use namespace::autoclean;

has type      => (isa => 'Str', is => 'ro', required => 1);
has fqdn      => (isa => 'Str', is => 'rw');
has ttl       => (isa => 'Int', is => 'rw');
has record_id => (isa => 'Int', is => 'rw');
has dynect    => (isa => 'Net::Dynect', is => 'ro', required => 1);
has rdata     => (isa => 'HashRef', is => 'rw', default => sub { {};  });
has resources => (isa => 'ArrayRef[Net::Dynect::Resource]', is => 'rw', default => undef);


sub BUILD {
    my ($self) = @_;
    $self->load_resource();
}

sub load_resource {
    my ($self) = @_;
    if($self->record_id) {
        my $rv = $self->dynect->get(uc($self->type()) . "Record/" . $self->dynect->zone() . "/" . $self->fqdn . '/' . $self->record_id);
        $self->ttl($rv->{ttl});
        $self->rdata({ %{$rv->{rdata}} });
    } else {
        my $rv = $self->dynect->get(uc($self->type()) . "Record/" . $self->dynect->zone() . "/" . $self->fqdn);
        # most of the time there will be only one record. The default case.
        # However we want to allow for multiples
        my $first = shift @$rv;
        my ($id) = ($first =~ /\/(\d+)$/);
        $self->record_id($id);
        $self->load_resource();
        $self->resources || $self->resources([]);
        push(@{$self->resources}, $self);
        for my $extra (@$rv) {
            ($id) = ($extra =~ /\/(\d+)$/);
            push(@{$self->resources}, Net::Dynect::Resource->new(
                dynect => $self->dynect,
                fqdn => $self->fqdn,
                type => $self->type,
                record_id => $id,
            ));
        }

    }
}

sub DEMOLISH {
    my ($self) = @_;
}


=head1 synopsis

Not to be used directly. Use as part of Net::Dynect.

=cut


__PACKAGE__->meta->make_immutable;
1;
