package MT::MoreAnalytics::PeriodMethod::Common;

use strict;
use warnings;

use MT::Util qw(epoch2ts format_ts);
use MT::MoreAnalytics::Util;
use Time::Local qw(timelocal);

sub validate_free { 1 }

sub timestamp_today {
    my $self = shift;
    epoch2ts($self->blog, $self->now);
}

sub summarize_today {
    my $self = shift;
    plugin->translate('Today(The day)');
}

sub timestamp_yesterday {
    my $self = shift;
    epoch2ts($self->blog, $self->now - 60 * 60 * 24);
}

sub summarize_yesterday {
    my $self = shift;
    plugin->translate('Yesterday(The last day)');
}

sub timestamp_fixed {
    my $self = shift;
    my $params = $self->params;
    my ( $year, $month, $day ) = split('-', $params->{date});
    sprintf('%04d%02d%02d000000', $year, $month, $day);
}

sub summarize_fixed {
    my $self = shift;
    my $ts = $self->timestamp;
    format_ts(plugin->translate('_DATE_FORMAT'), $ts, $self->blog);
}

sub validate_fixed {
    my $self = shift;
    my $params = $self->params;

    my $date = $params->{date};
    return $self->error(plugin->translate('Invalid date format.'))
        if $date !~ /^[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}$/;

    my ( $year, $month, $day ) = split('-', $date);

    return $self->error(plugin->translate('Invalid year.'))
        if $year < 1900;

    return $self->error(plugin->translate('Invalid month.'))
        if $month < 1 || $month > 12;

    return $self->error(plugin->translate('Invalid day.'))
        if $day < 1 || $day > 31;

    unless ( eval { timelocal(0, 0, 0, $day, $month - 1, $year - 1900) } ) {
        return $self->error(plugin->translate('Invalid date.'));
    }

    1;
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