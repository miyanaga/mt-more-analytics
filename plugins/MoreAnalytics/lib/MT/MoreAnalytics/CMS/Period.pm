package MT::MoreAnalytics::CMS::Period;

use strict;
use warnings;

use MT::MoreAnalytics::Util;
use MT::MoreAnalytics::Provider;
use MT::MoreAnalytics::PeriodMethod;

{
    sub _split_from_to_params {
        my ( $app ) = @_;
        my %hash = $app->param_hash;

        my %values;
        foreach my $side ( qw/from to/ ) {
            my %param;
            foreach my $key ( keys %hash ) {
                my @parts = split /\./, $key;
                if ( scalar @parts > 1 && $parts[0] eq $side ) {
                    $param{$parts[1]} = $hash{$key};
                }            
            }
            $values{$side} = \%param;
        }

        \%values;
    }
}

sub on_edit_period {
    my ( $cb, $app, $id, $obj, $param ) = @_;
    my $values = _split_from_to_params($app);

    # Check permission
    my $user = $app->user;
    return $app->permission_denied()
        if !$user->is_superuser
            && !$user->permissions($app->param('blog_id') || 0)->can_do('ma_edit_period');

    # Load or new period
    if ( $obj ) {

        # Consistency
        return $app->return_to_dashboard( redirect => 1 )
            if $obj->blog_id != $param->{blog_id};

        # Value
        $param->{id} = $obj->id;
        $param->{name} = $obj->name;

        $param->{summary} = plugin->translate('This period is from [_1] = [_2] to [_3] = [_4].',
            $obj->from_method->summarize,
            $obj->from_method->readable,
            $obj->to_method->summarize,
            $obj->to_method->readable,
        );
    } else {
        $obj = MT::MoreAnalytics::Period->new;
        $obj->from_method_id('days_before');
        $obj->from_params(q({"days":8}));
        $obj->to_method_id('yesterday');
    }

    # Enum methods for each from and to
    foreach my $side ( qw/from to/ ) {
        my $methods = MT::MoreAnalytics::PeriodMethod->all_methods($side);
        my $id_name = $side . '_method_id';
        my $current_id = $obj->$id_name;

        my $params_name = $side . '_method_params';
        my $method_params = $obj->$params_name;

        if ( my $user_values = $values->{$side} ) {
            foreach my $key ( keys %$user_values ) {
                $method_params->{$key} = $user_values->{$key};
            }
        }

        my @methods = map {
            my $values = {
                %$method_params,
                side        => $side,
                id          => $_->id,
                label       => $_->opts('label'),
                is_selected => $_->id eq $current_id ? 1 : 0,
                form_id     => join('-', $side, $_->id),
                template    => $_->template,
            };

            $_->template_param($cb, $app, $values, $obj);

            $values;
        } @$methods;

        my $methods_name = $side . '_methods';
        $param->{$methods_name} = \@methods;
    }

    1;
}

sub on_save_filter_period {
    my ( $cb, $app ) = @_;
    my $values = _split_from_to_params($app);
    my $q = $app->param;
    my $period_id = $q->param('id');

    # Check permission
    my $user = $app->user;
    return $app->permission_denied()
        if !$user->is_superuser
            && !$user->permissions($app->param('blog_id') || 0)->can_do('ma_edit_period');

    # Requires name and basename
    return $cb->error(plugin->translate('Name is required.'))
        unless length($q->param('name'));

    return $cb->error(plugin->translate('Basename is reuquired.'))
        unless length($q->param('basename'));

    # Basename should be alphanumeric
    my $basename = $q->param('basename');
    return $cb->error(plugin->translate('Basename should be consisted with alphabets, numbers or underscore.'))
        if $basename !~ m!^[a-z_][a-z0-9_]+$!;

    # Basename should be unique
    my $exists = MT->model('ma_period')->load({basename => $basename});
    return $cb->error(
        plugin->translate('Aggregation period basename of [_1] is already exists. Basename should be unique.', $basename))
            if $exists && (!$period_id || $exists->id ne $period_id);

    foreach my $side ( qw/from to/ ) {
        my $id_name = $side . '_method_id';
        my $id = $app->param($id_name);

        # Method id reuqires
        return $cb->error( $side eq 'from'
            ? plugin->translate('"Aggregate from" has no method.')
            : plugin->translate('"Aggregate to" has no method')
        ) unless $id;

        # Validate params for method
        my $pm = MT::MoreAnalytics::PeriodMethod->create($id)
            or return $cb->error(plugin->translate('Unknown period method: [_1]', $id));
        $pm->params($values->{$side}) if $values->{$side};

        my $res = $pm->validate;
        unless ( defined $res ) {
            return $cb->error( $side eq 'from'
                ? plugin->translate('"Aggregate from" has probrem: [_1]', $pm->errstr)
                : plugin->translate('"Aggregate to" has probrem: [_1]', $pm->errstr)
            );
        }
    }

    1;
}

sub on_pre_save_period {
    my ( $cb, $app, $obj, $orig ) = @_;
    my %hash = $app->param_hash;
    my $values = _split_from_to_params($app);

    # Set columns from param
    foreach my $col ( qw/id name basename description/ ) {
        $obj->$col($hash{$col}) if defined $hash{$col};
    }

    # Set method id and params for each from and to
    foreach my $side ( qw/from to/ ) {
        my $id_name = $side . '_method_id';
        my $id = $hash{$id_name};
        $obj->$id_name($id);

        my $params_name = $side . '_method_params';
        $obj->$params_name($values->{$side} || {});
    }

    1;
}

1;