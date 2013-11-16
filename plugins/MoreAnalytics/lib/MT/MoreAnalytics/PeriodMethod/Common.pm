package MT::MoreAnalytics::PeriodMethod::Common;

use strict;
use warnings;

use MT::Util qw(epoch2ts format_ts);
use MT::MoreAnalytics::Util;

sub validate_free { 1 }

sub timestamp_yesterday {
    my $self = shift;
    epoch2ts($self->blog, $self->now - 60 * 60 * 24);
}

sub summarize_yesterday {
    my $self = shift;
    plugin->translate('Yesterday(The last day)');
}

sub timestamp_days_before {
    my $self = shift;
    my $params = $self->params;
    epoch2ts($self->blog, $self->now - 60 * 60 * 24 * $params->{days});
}

sub summarize_days_before {
    my $self = shift;
    my $params = $self->params;
    plugin->translate('[_1] days before', $params->{days});
}

sub validate_days_before {
    my $self = shift;
    my $params = $self->params;

    my $days = $params->{days};
    return $self->error(plugin->translate('Enter an integer zero or over.'))
        if $days !~ /^[0-9]+$/ || $days < 0;

    1;
}

1;