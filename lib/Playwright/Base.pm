package Playwright::Base;

use strict;
use warnings;

use Sub::Install();

use Playwright::Util();

#ABSTRACT: Object representing Playwright pages

no warnings 'experimental';
use feature qw{signatures};

=head2 SYNOPSIS

    use Playwright;
    my ($handle,$page) = Playwright->new( handle => "chrome" );
    $page->goto('http://www.google.com');
    my $handle_version = $handle->version();
    $handle->quit();

=head2 DESCRIPTION

Base class for each Playwright class.
You probably shouldn't use this directly; instead use a subclass.

The specification for each class can also be inspected with the 'spec' method:

    use Data::Dumper;
    my $page = Playwright::Base->new(...);
    print Dumper($page->spec('Page'));

=head1 CONSTRUCTOR

=head2 new(HASH) = (Playwright::Base)

Creates a new page and returns a handle to interact with it.

=head3 INPUT

    handle (Playwright) : Playwright object.
    spec (HASHREF)      : Specification for the class to build.
    id (STRING)         : _guid returned by a response from the Playwright server with the provided type.
    type (STRING)       : Type to actually use

=cut

sub new ($class, %options) {

    my $self = bless({
        spec    => $Playwright::spec->{$options{type}}{members},
        type    => $options{type},
        guid    => $options{id},
        ua      => $options{handle}{ua},
        port    => $options{handle}{port},
    }, $class);

    # Install the subroutines if they aren't already
    foreach my $method (keys(%{$self->{spec}})) {
        Sub::Install::install_sub({
            code => sub {
                my $self = shift;
                $self->_request( args => [@_], command => $method, object => $self->{guid}, type => $self->{type} )
            },
            as   => $method,
        }) unless $self->can($method);
    }

    return ($self);
}

=head1 METHODS

=head2 spec

Return the relevant methods and their definitions for this module which are built dynamically from the Playwright API spec.

=cut

sub spec ($self) {
    return %{$self->{spec}};
}

sub _request ($self, %args) {
    my $msg = Playwright::Util::request ('POST', 'command', $self->{port}, $self->{ua}, %args);
    return $Playwright::mapper{$msg->{_type}}->($self,$msg) if (ref $msg eq 'HASH') && $msg->{_type} && exists $Playwright::mapper{$msg->{_type}};
    return $msg;
}

1;
