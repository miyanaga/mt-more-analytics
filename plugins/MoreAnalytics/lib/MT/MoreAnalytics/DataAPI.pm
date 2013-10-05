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

sub endpoint {
    my ( $app, $endpoint ) = @_;
    my $q = $app->param;
    my $blog = $app->blog;

    # TODO Check if allowed URL
    # TODO Fix reusing tag routime. GA handling should be more abstract

    my %args = $app->param_hash;
    my $ctx = MT::Template::Context->new;
    $ctx->stash( 'blog_id', $q->param('site_id') );
    $ctx->stash( 'blog',  $app->blog );

    my $res = MT::MoreAnalytics::Tags::_handle_report_tag( $ctx, \%args, undef, output => sub {
        my ( $ctx, $args, $data, $items ) = @_;
        $data;
    });

    delete $res->{debug};
    $res;
}

sub fields {
    [   {   name        => 'ma_object_stat',
            from_object => sub {
                my ($obj) = @_;
                my $app = MT->instance;
                my $q = $app->param;

                # TODO Check if allowed stat

                # Period
                my $period;
                if ( my $ma_period = $q->param('ma_period') ) {
                    $period = MT->model('ma_period')->load({ basename => $ma_period });
                    return [] unless $period;
                }

                # Default period
                $period = MT->model('ma_period')->load({ basename => 'default' })
                    or return [];

                # Find stat
                my $stat = MT->model('ma_object_stat')->load({
                    object_ds       => $obj->datasource,
                    object_id       => $obj->id,
                    ma_period_id    => $period->id,
                }) or return [];

                [   map {
                        +{  basename => $_,
                            value    => $stat->$_,
                        };
                    } @stat_fields
                ];
            },
        },
    ];
}


1;