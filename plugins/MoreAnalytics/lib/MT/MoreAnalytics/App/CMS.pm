package MT::MoreAnalytics::App::CMS;

use strict;
use warnings;

use File::Spec;
use MT::MoreAnalytics::Util;
use MT::MoreAnalytics::Provider;
use MT::MoreAnalytics::PeriodMethod;

sub profiles {
    my $app = shift;
    my $blog = $app->blog or return '';
    my %param;

    # Check if MoreAnalytics provider is ready
    MT::MoreAnalytics::Provider->is_ready( $app, $blog )
        or return $app->error(
            plugin->translate( 'Google Analytics is not ready for blog or website ID:[_1]', $blog->id ) );

    # Generate MoreAnalytics provider and store to cache
    my $provider
        = MT::MoreAnalytics::Provider->new( 'MoreAnalytics', $blog );

    $param{profiles} = $provider->profiles($app);

    plugin->load_tmpl('playground/profiles.tmpl', \%param);
}

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

sub on_edit_period {
    my ( $cb, $app, $id, $obj, $param ) = @_;
    my $values = _split_from_to_params($app);

    if ( $obj ) {
        $param->{id} = $obj->id;
        $param->{name} = $obj->name;
    } else {
        $obj = MT::MoreAnalytics::Period->new;
        $obj->from_method_id('days_before');
        $obj->from_params(q({"days":8}));
        $obj->to_method_id('yesterday');
    }

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

        my @methods = map { {
            %$method_params,
            side        => $side,
            id          => $_->id,
            label       => $_->opts('label'),
            is_selected => $_->id eq $current_id ? 1 : 0,
            form_id     => join('-', $side, $_->id),
            template    => $_->template,
        } } @$methods;

        my $methods_name = $side . '_methods';
        $param->{$methods_name} = \@methods;
    }

    1;
}

sub on_save_filter_period {
    my ( $cb, $app ) = @_;
    my $values = _split_from_to_params($app);
    my $q = $app->param;

    return $cb->error(plugin->translate('Name is required.'))
        unless length($q->param('name'));

    return $cb->error(plugin->translate('Basename is reuquired.'))
        unless length($q->param('basename'));

    my $basename = $q->param('basename');
    return $cb->error(plugin->translate('Basename should be consisted with alphabets, numbers or underscore.'))
        if $basename !~ m!^[a-z_][a-z0-9_]+$!;

    foreach my $side ( qw/from to/ ) {
        my $id_name = $side . '_method_id';
        my $id = $app->param($id_name);

        return $cb->error(plugin->translate(
            ($side eq 'from' ? '"Aggregate from" has no method.' : '"Aggregate to" hash no method')
        )) unless $id;

        my $pm = MT::MoreAnalytics::PeriodMethod->create($id);
        $pm->params($values->{$side}) if $values->{$side};

        my $res = $pm->validate;
        unless ( defined $res ) {
            return $cb->error(plugin->translate(
                ($side eq 'from' ? '"Aggregate from" has probrem: [_1]'
                    : '"Aggregate to" has probrem: [_1]'),
                $pm->errstr,
            ));            
        }
    }

    1;
}

sub on_pre_save_period {
    my ( $cb, $app, $obj, $orig ) = @_;
    my %hash = $app->param_hash;
    my $values = _split_from_to_params($app);

    foreach my $col ( qw/id name basename description/ ) {
        $obj->$col($hash{$col}) if defined $hash{$col};
    }

    foreach my $side ( qw/from to/ ) {
        my $id_name = $side . '_method_id';
        my $id = $hash{$id_name};
        $obj->$id_name($id);

        my $params_name = $side . '_method_params';
        $obj->$params_name($values->{$side} || {});
    }

    1;
}

sub entry_list_props {
    my %base_prop = (
        display     => 'default',
        base        => '__virtual.integer',
        value_format => '%d',
        default_value => 0,
        bulk_html   => sub {
            my $prop = shift;
            my ( $objs, $app, $load_options ) = @_;
            my @ids = map { $_->id } @$objs;
            my ( %values, @rows );
            my $col = $prop->id;

            my @only = ('object_id', $col);
            if ( my $iter = MT->model('ma_object_stat')->load_iter({
                ma_period_id => ($load_options->{ma_period_id} || 0),
                object_ds => 'entry',
                object_id => \@ids
            }, {
                fetchonly => \@only
            }) ) {
                while ( my $os = $iter->() ) {
                    $values{$os->object_id} = $os->$col;
                }
            }

            my $format = plugin->translate($prop->value_format);

            foreach my $obj ( @$objs ) {
                my $value = 0;
                push @rows, sprintf(
                    $format,
                    $values{$obj->id} || $prop->default_value
                );
            }
            @rows;
        },
        terms => sub {
            my $prop = shift;
            my ( $args, $db_terms, $db_args, $load_options ) = @_;
            my $super_terms = $prop->super(@_);
            push @{ $db_args->{joins} ||= [] }, MT->model('ma_object_stat')->join_on(
                undef,
                {
                    ma_period_id => ($load_options->{ma_period_id} || 0),
                    object_ds => 'entry',
                    object_id => \'= entry_id',
                    %$super_terms,
                },
                {
                    unique => 1,
                }
            );
        },
        bulk_sort => sub {
            my $prop = shift;
            my ($objs, $load_options) = @_;
            print STDERR (scalar @$objs), "\n";
            my @ids = map { $_->id } @$objs;
            my $col = $prop->col;
            my @only = ('object_id', $col);
            my @oss = MT->model('ma_object_stat')->load({
                ma_period_id => ($load_options->{ma_period_id} || 0),
                object_ds => 'entry',
                object_id => \@ids
            }, {
                fetchonly => \@only
            });
            my %values = map { $_->object_id => $_->$col } @oss;

            sort { ($values{$a->id} || 0) <=> ($values{$b->id} || 0) } @$objs;
        },
        sort => 0,
    );

    my %time_prop = (
        %base_prop,
        value_format => '%0.2f Sec.',
    );

    my %percent_prop = (
        %base_prop,
        value_format => '%0.2f%%',
    );

    my $order = 5000;
    my $props = {
        pageviews => {
            %base_prop,
            col => 'pageviews',
            label => 'GA:Pageviews',
            order => $order++,
        },
        unique_pageviews => {
            %base_prop,
            col => 'unique_pageviews',
            label => 'GA:Unique PV',
            order => $order++,
        },
        entrance_rate => {
            %percent_prop,
            col => 'entrance_rate',
            label => 'GA:Entrance Rate',
            order => $order++,
        },
        exit_rate => {
            %percent_prop,
            col => 'exit_rate',
            label => 'GA:Exit Rate',
            order => $order++,
        },
        visit_bounce_rate => {
            %percent_prop,
            col => 'visit_bounce_rate',
            label => 'GA:Bounce Rate',
            order => $order++,
        },
        avg_page_download_time => {
            %time_prop,
            col => 'avg_page_download_time',
            label => 'GA:Avg. DL Time',
            order => $order++,
        },
        avg_page_load_time => {
            %time_prop,
            col => 'avg_page_load_time',
            label => 'GA:Avg. Load Time',
            order => $order++,
        },
        avg_time_on_page => {
            %time_prop,
            col => 'time_on_page',
            label => 'GA:Avg. View Time',
            order => $order++,
        },

    };

    $props;
}

sub on_template_param_list_common {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $ds = $param->{object_type};
    return if $ds ne 'entry' && $ds ne 'page';

    my $blog_id = $app->param('blog_id') || 0;

    # Insert period pulldown template
    my $insert = $tmpl->createElement('app:setting', {
        id => 'ma_period',
        label => plugin->translate('GA:Aggregation Period'),
        label_class => 'top-label',
    });
    $insert->innerHTML(q{
        <style>
            #per_page-field { float:left; margin-right:16px; }
            #display_columns-field { clear:both; }
        </style>
        <select name="ma_period_id" id="ma-period">
            <mt:loop name="ma_period_loop">
                <option value="<mt:var name='id'>"<mt:if name="is_selected"> selected="selected"</mt:if>><mt:var name="name" escape="html"></option>
            </mt:loop>
        </select>
    });
    my $target = $tmpl->getElementById('per_page');
    $tmpl->insertAfter($insert, $target);

    # Current period
    my $list_prefs = $app->user->list_prefs || {};
    my $list_pref = $list_prefs->{$ds}{$blog_id} ||= {};
    my $current_period_id = $list_pref->{ma_period_id};

    # Load periods and pass as param
    my @blog_ids = (0);
    push @blog_ids, $blog_id if $blog_id;
    if ( my $blog = $app->blog ) {
        if ( !$blog->is_blog ) {
            push @blog_ids, map { $_->id } @{ $blog->blogs };
        }
    }

    my @periods = map {
        {
            id => $_->id,
            name => $_->long_name,
            is_selected => ($_->id == $current_period_id ?1: 0),
        }
    } MT->model('ma_period')->load({blog_id => \@blog_ids});

    $param->{ma_period_loop} = \@periods;

    # Insert javascript
    $param->{jq_js_include} ||= '';
    $param->{jq_js_include} .= q{
        (function($) {
            // Override jQuery Ajax
            var originalAjax = $.ajax;
            $.ajax = function() {
                var args = arguments;
                if ( args[0] && args[0].data
                    && args[0].data['__mode']
                    && args[0].data['__mode'] === 'filtered_list' )
                {
                    console.log('jack');
                    args[0].data['ma_period_id'] = $('#ma-period').val();
                }
                return originalAjax.apply($, args);
            };

            // Bind period to renderList
            $('#ma-period').change(function() {
                renderList('filtered_list', cols, vals, jQuery('#row').val(), 1);
            });
        })(jQuery);
    };

    1;
}

sub on_pre_load_filtered_list_entry {
    my ( $cb, $app, $filter, $load_options, $cols ) = @_;
    my $q = $app->param;
    my $blog_id = $q->param('blog_id') || 0;
    my $ds = $q->param('datasource');

    # Get available period.
    my $ma_period_id = $app->param('ma_period_id') || 0;
    my $period;
    $period = MT->model('ma_period')->load($ma_period_id) if $ma_period_id;

    unless ( $period ) {
        $period = MT->ma_period_id->load({basename => 'default'})
            or return 1;
    }

    # Save list prefs
    my $list_prefs = $app->user->list_prefs || {};
    my $list_pref = $list_prefs->{$ds}{$blog_id} ||= {};
    $list_pref->{ma_period_id} = $period->id;
    # $app->user->save
    # Will save in caller

    # Set to load_options
    $load_options->{ma_period_id} = $period->id;

    1;
}

1;