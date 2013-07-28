package MT::MoreAnalytics::App::CMS;

use strict;
use warnings;

use File::Spec;
use MT::MoreAnalytics::Util;
use MT::MoreAnalytics::Provider;

sub playground {
    my $app = shift;
    my %param;

    my $plugindata = GoogleAnalytics::current_plugindata( $app, $app->blog );
    my $config = $plugindata->data;
    my $profile_id = $config->{profile_id} || return $app->error('No profile');

    $param{more_analytics_version_id} = plugin->{version};
    $param{current_profile_id} = $profile_id;

    # Metrics and dimensions
    {
        my $lang = MT->current_language;
        my $base = File::Spec->catdir(MT->instance->config('StaticFilePath'), qw(plugins MoreAnalytics metrics-and-dimensions));
        my $path = File::Spec->catdir($base, "$lang.js");
        $lang = 'en_US' unless -f $path;        

        $param{metrics_and_dimensions_lang} = $lang;
    }


    plugin->load_tmpl('playground.tmpl', \%param);
}

sub preview {

}

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

sub entry_list_props {
    my %base_prop = (
        display     => 'default',
        base        => '__virtual.integer',
        value_format => '%d',
        default_value => 0,
        bulk_html   => sub {
            my $prop = shift;
            my ( $objs, $app ) = @_;
            my @ids = map { $_->id } @$objs;
            my ( %values, @rows );
            my $col = 'ga_' . $prop->id;

            my @only = ('entry_id', $col);
            if ( my $iter = MT->model('fileinfo')->load_iter({entry_id => \@ids}, {fetchonly => \@only}) ) {
                while ( my $fi = $iter->() ) {
                    $values{$fi->entry_id} = $fi->$col;
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
            my ( $args, $db_terms, $db_args ) = @_;
            my $super_terms = $prop->super(@_);
            push @{ $db_args->{joins} ||= [] }, MT->model('fileinfo')->join_on(
                undef,
                {
                    entry_id => \'= entry_id',
                    %$super_terms,
                },
                {
                    unique => 1,
                }
            );
        },
        bulk_sort => sub {
            my $prop = shift;
            my ($objs) = @_;
            my @ids = map { $_->id } @$objs;
            my $col = $prop->col;
            my @only = ('entry_id', $col);
            my @fis = MT->model('fileinfo')->load({entry_id => \@ids}, {fetchonly => \@only});
            my %values = map { $_->entry_id => $_->$col } @fis;

            _dumper($col);
#            _dumper(\%values);

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
            col => 'ga_pageviews',
            label => 'Pageviews',
            order => $order++,
        },
        unique_pageviews => {
            %base_prop,
            col => 'ga_unique_pageviews',
            label => 'Unique Pageviews',
            order => $order++,
        },
        entrance_rate => {
            %percent_prop,
            col => 'ga_entrance_rate',
            label => 'Entrance Rate',
            order => $order++,
        },
        exit_rate => {
            %percent_prop,
            col => 'ga_exit_rate',
            label => 'Exit Rate',
            order => $order++,
        },
        visit_bounce_rate => {
            %percent_prop,
            col => 'ga_visit_bounce_rate',
            label => 'Bounce Rate',
            order => $order++,
        },
        avg_page_download_time => {
            %time_prop,
            col => 'ga_avg_page_download_time',
            label => 'Averate Page Download Time',
            order => $order++,
        },
        avg_page_load_time => {
            %time_prop,
            col => 'ga_avg_page_load_time',
            label => 'Averate Page Load Time',
            order => $order++,
        },
        avg_page_load_time => {
            %time_prop,
            col => 'ga_avg_page_load_time',
            label => 'Averate Time On Page',
            order => $order++,
        },

    };

    $props;
}

1;