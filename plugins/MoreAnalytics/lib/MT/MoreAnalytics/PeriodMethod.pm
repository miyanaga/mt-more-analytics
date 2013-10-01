package MT::MoreAnalytics::PeriodMethod;

use strict;
use warnings;

use base qw(MT::ErrorHandler);
use MT::Util;
use MT::MoreAnalytics::Util;

sub create {
    my $pkg = shift;
    my ( $id, $blog, $params ) = @_;

    $id or die 'Requires period method id';

    my $self = $pkg->new;
    my $opts = MT->registry('more_analytics', 'period_methods', $id)
        or die "Unknown period method id: $id";

    $self->id($id);
    $self->blog($blog);
    $self->opts($opts);
    $self->params($params) if $params;
    $self->params($opts->{default_params})
        if $opts->{default_params} && !$params;

    $self;
}

sub now { MT::MoreAnalytics::Util::now }

sub errstr {
    my $err = shift->SUPER::errstr;
    $err =~ s/\n+$//;
    $err;
}

sub _property {
    my $self = shift;
    my $col = (split(/::/, (caller(1))[3]))[-1];

    if ( @_ ) {
        $self->{$col} = $_[0];
    } else {
        return $self->{$col};
    }
}

sub id { shift->_property(@_) }
sub blog { shift->_property(@_) }

sub _hash_values {
    my $self = shift;
    my $col = (split(/::/, (caller(1))[3]))[-1];
    my $name = '__' . $col;

    $self->{$name} ||= {};
    if ( @_ ) {
        my $ref = ref $_[0];
        if ( $ref eq 'HASH' ) {
            $self->{$name} = $_[0];
            return;
        } elsif ( !$ref ) {
            if ( defined $_[1] ) {
                $self->{$name}{$_[0]} = $_[1];
                return;
            } else {
                return $self->{$name}{$_[0]};
            }
        }
    } else {
        return $self->{$name};
    }
}

sub params { shift->_hash_values(@_) }
sub opts { shift->_hash_values(@_) }

sub _run_as_code {
    my $self = shift;
    my $col = (split(/::/, (caller(1))[3]))[-1];
    my $code = MT->handler_to_coderef($self->opts($col));
    die "No $col code" if ref $code ne 'CODE';
    $self->error('') if $col eq 'validate';
    $code->($self, $self->params, $self->blog);
}

sub summarize { shift->_run_as_code(@_) }
sub timestamp { shift->_run_as_code(@_) }
sub validate { shift->_run_as_code(@_) }

sub format_ga {
    my $self = shift;
    my $ts = $self->timestamp();
    MT::Util::format_ts('%Y-%m-%d', $ts, $self->blog);
}

sub template {
    my $self = shift;
    my $id = $self->id;
    my $template = $self->opts('template') || '';

    if ( $template =~ /\.tmpl$/ ) {
        my $component = $self->opts('plugin') || plugin;
        $template = $component->load_tmpl($template)
            or die "No template for period $id";
        $template = $template->text;
    }

    $template;
}

sub all_methods {
    my $pkg = shift;
    my ( $for ) = @_;
    my $methods = MT->registry('more_analytics', 'period_methods') || {};

    my @all = sort {
        ( $a->opts('order') || 1000 ) <=> ( $b->opts('order') || 1000 );
    } map {
        MT::MoreAnalytics::PeriodMethod->create($_);
    } keys %$methods;

    if ( $for ) {
        @all = grep {
            my $available = $_->opts('available_for');
            !defined($available) || $available->{$for};
        } @all;
    }

    \@all;
}

1;