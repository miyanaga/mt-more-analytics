package MT::MoreAnalytics::Request;

use strict;
use warnings;

use base qw(MT::ErrorHandler);
use Carp qw(confess);
use MT::MoreAnalytics::Util;

my @ALLOWED = qw(
    ids start-date end-date
    metrics dimensions
    sort filters segment
    start-index max-results
    fields prettyPrint userIp quotaUser
    callback
);

sub new {
    my $pkg = shift;

    my $self = $pkg->SUPER::new();
    $self->init();
    $self->set(@_);

    $self;
}

sub init {
    my $self = shift;
    $self->{args} = {};
    $self;
}

sub set {
    my $self = shift;
    my $args = ref $_[0] eq 'HASH' ? shift : {@_};
    $self->{args} ||= {};

    # Normalize underscore to hyphen
    foreach my $n ( keys %$args ) {
        next unless index($n, '_');
        my $h = $n;
        $h =~ s/_/-/g;
        $args->{$h} = delete $args->{$n};
    }

    foreach my $name ( keys %$args ) {
        $self->{args}->{$name} = $args->{$name};
    }

    $self;
}

sub normalize {
    my $self = shift;
    my $args = $self->{args} || '';
    my $normalized = {};

    foreach my $name ( keys %$args ) {
        my $value = $args->{$name};
        if ( $name =~ /^(ids|filters|fields|metrics|dimensions|sort|segment)$/ ) {

            # Metrics or dimansions
            $value =~ s!ga:!!g;
            $value =~ s!\s*([,;])\s*!$1!g;
            $value =~ s!(^|,|;|-)([a-z])!$1ga:$2!gi;
            $normalized->{$name} = $value if length($value);
        } elsif ( $name =~ /^(start|end)-date$/ ) {

            # Date range
            $normalized->{$name} = $value;
        } elsif ( $name =~ /^(max-results|start-index)$/ ) {

            # Start index and max results
            $normalized->{$name} = $value if $value;
        }
    }

    $normalized;
}

1;