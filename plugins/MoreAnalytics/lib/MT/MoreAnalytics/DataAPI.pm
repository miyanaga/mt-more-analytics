package MT::MoreAnalytics::DataAPI;

use strict;
use MT::MoreAnalytics::Util;
use MT::MoreAnalytics::Tags;
use MT::Template::Context;

my @stat_fields = qw(
    pageviews unique_pageviews
    entrance_rate exit_rate visit_bounce_rate
    avg_page_download_time avg_page_load_time
    avg_time_on_page
);

sub _check_condition {
    my ( $type, $app, $endpoint ) = @_;
    my $blog = $app->blog;

    # Filter by current policy
    my ( $key, $policy ) = data_api_policy($blog, $type);
    return $app->error(403) unless $policy;
    my $code = MT->handler_to_coderef($policy->{condition});
    return $app->error(403) if !$code or ref $code ne 'CODE';

    $code->(@_) or return;
}

sub endpoint {
    my ( $app, $endpoint ) = @_;
    my $q = $app->param;

    defined( my $res = _check_condition('ondemand', @_) )
        or return;

    # TODO Fix reusing tag routime. GA handling should be more abstract
    my %args = $app->param_hash;
    my $ctx = MT::Template::Context->new;
    $ctx->stash( 'blog_id', $q->param('site_id') );
    $ctx->stash( 'blog',  $app->blog );

    my $res = MT::MoreAnalytics::Tags::_handle_report_tag( $ctx, \%args, undef, output => sub {
        my ( $ctx, $args, $data, $items ) = @_;
        return $app->error($ctx->error) if $ctx->errstr;
        $data;
    });

    # TODO Guess object if requested

    delete $res->{debug} if ref $res eq 'HASH';
    $res;
}

sub fields {
    [
        {
            name        => 'ma_object_stats',
            condition   => sub {
                my $app = MT->instance;
                my $blog = $app->blog or return 0;
                my ( $id, $policy ) = data_api_policy( $blog, 'stats' );
                return 0 unless $policy;

                my $condition = MT->handler_to_coderef($policy->{condition});
                return 0 if ref $condition ne 'CODE';
                $condition->();
            },
            bulk_from_object => sub {
                my ( $objs, $hashs ) = @_;
                return unless scalar @$objs;
                my $obj = $objs->[0];
                my $app = MT->instance;
                my $q = $app->param;

                # Period
                my $period;
                if ( defined( my $ma_period = $q->param('period') ) ) {
                    $period = MT->model('ma_period')->load({ basename => $ma_period });
                }

                # Default period
                $period ||= MT->model('ma_period')->load({ basename => 'default' });
                return unless $period;

                # Find object stat
                my %terms = (
                    object_ds       => $obj->datasource,
                    object_id       => [ map { $_->id } @$objs ],
                    ma_period_id    => $period->id,
                );
                my @stats = MT->model('ma_object_stat')->load(\%terms);
                my %stats = map {
                    $_->object_id => $_
                } @stats;

                # Fileds
                my $defines = MT->registry('more_analytics', 'object_stats', 'by_page_path');
                my @keys = keys %$defines;

                my $all_fields = MT->config->DisableResourceField;
                my %disabled_fields = map {
                    $_ => 1
                } split( ',', ( MT->config->DisableResourceField->{ $obj->class } || '' ) );

                if ( %disabled_fields ) {
                    @keys = grep {
                        my $define = $defines->{$_};
                        my $metrics = $define->{metrics} || $_;
                        !$disabled_fields{$metrics};
                    } @keys;
                }

                for ( my $i = 0; $i < scalar @$objs; $i++ ) {
                    my $obj = $objs->[$i] || next;
                    my $stat = $stats{$obj->id} || next;
                    $hashs->[$i] ||= {};

                    foreach my $col ( @keys ) {
                        my $define = $defines->{$col} or next;
                        $col = $define->{col} || $col;
                        my $metric = $define->{metrics} || $col;
                        $hashs->[$i]{$metric} = $stat->$col;
                    }
                }
            },
        },
    ];
}

sub on_pre_load_filtered_list_entry {
    my ( $cb, $app, $filter, $opts, $cols ) = @_;
    my $q = $app->param;

    return 1 unless $opts->{sort_by};

    my $mets2cols = MT->model('ma_object_stat')->metrics_to_cols('by_page_path');
    my $col = $mets2cols->{$opts->{sort_by}} or return 1;

    # Get available period.
    my $period;
    if ( my $basename = $app->param('period') ) {
        $period = MT->model('ma_period')->load({basename => $basename});
    }

    unless ( $period ) {
        $period = MT->model('ma_period')->load({basename => 'default'})
            or return 1;
    }

    $opts->{ma_period_id} = $period->id;
    $opts->{sort_by} = $col;

    1;
}

1;