package MT::MoreAnalytics::Tasks;

use strict;
use warnings;

use MT::Util qw(format_ts epoch2ts);
use MT::MoreAnalytics::Util;
use MT::MoreAnalytics::Provider;
use MT::MoreAnalytics::Request;

my @OBSERVE_FIELDS = qw(
    avg_page_download_time avg_page_load_time
    visit_bounce_rate entrance_rate exit_rate
    pageviews time_on_page unique_pageviews
);

my %OBSERVE_MAP = map {
    my $v = $_;
    $v =~ s!_([a-z])!uc($1)!eg;
    $_ => $v;
} @OBSERVE_FIELDS;

sub update_object_stats {
    my $task = shift;
    my $app = MT->instance;

    # Update soon flag
    treat_config( sub {
        my $config = shift;
        $config->{update_object_stats_soon} = 0;
    }, 'system' );

    # Subtasks
    my $subtasks = MT->registry('more_analytics', 'object_stats_tasks');
    my @subtasks = map {
        MT->handler_to_coderef($_->{code});
    } sort {
        ( $a->{order} || 1000 ) <=> ( $b->{order} || 1000 )
    } map {
        my $st = $subtasks->{$_};
        $st = { order => 1000, code => $st } unless ref $st eq 'HASH';
        $st->{id} = $_;
        $st;
    } keys %$subtasks;

    my $iter = MT->model('blog')->load_iter( { class => '*' } )
        or return;

    # Loop blogs and periods.
    my %blog_ids;
    my %period_ids;
    my %report = (
        queries => 0,
        stats => 0,
        removed => 0,
    );

    while ( my $blog = $iter->() ) {
        $blog_ids{$blog->id} = 1;

        # Loop periods.
        my @ids = ( 0, $blog->id );
        if ( !$blog->is_blog ) {
            push @ids, map { $_->id } @{$blog->blogs};
        }

        my @periods = MT->model('ma_period')->load({blog_id => \@ids});
        foreach my $p ( @periods ) {
            $period_ids{$p->id} = 1;
            my $age = time;

            # Query to Google Analytics API
            MT::MoreAnalytics::Provider->is_ready( $app, $blog ) or next;
            my $ma = MT::MoreAnalytics::Provider->new( 'MoreAnalytics', $blog );

            foreach my $subtask ( @subtasks ) {
                next if ref $subtask ne 'CODE';
                my $eh = MT::ErrorHandler->new;
                my $res = $subtask->( $eh,
                    app         => $app,
                    task        => $subtask,
                    report      => \%report,
                    blog        => $blog,
                    period      => $p,
                    age         => $age,
                    provider    => $ma
                );

                if ( !defined($res) || $eh->errstr ) {
                    my $label = $subtask->{label} || $subtask->{id};
                    $label = $label->() if ref $label eq 'CODE';

                }
            }

            # Cleanup
            my $terms = {
                blog_id => $blog->id,
                ma_period_id => $p->id,
                age => { '<' => $age },
            };
            $report{removed} += MT->model('ma_object_stat')->count($terms) || 0;
            MT->model('ma_object_stat')->remove($terms);
        }
    }

    # TODO How about notification?
    eval {
        require MT::Log;
        $app->log({
            message => plugin->translate(
                'MoreAnalytics updated object stats. [_1] blog(s), [_2] period(s), [_3] query(ies), [_4] stat(s).',
                    scalar keys %blog_ids, scalar keys %period_ids, $report{queries}, $report{stats}
            ),
            class    => 'system',
            category => 'plugin',
            level    => MT::Log::INFO()
        });
    };
}

sub cleanup_cache_freq {
    my %config;
    plugin->load_config(\%config, 'system');
    $config{cleanup_cache_freq_min} * 60;
}

sub cleanup_cache {
    my $task = shift;
    my $app = MT->instance;

    # Cleanup cache
    my %config;
    plugin->load_config(\%config, 'system');
    my $limit_mb = $config{cache_size_limit_mb};

    # TODO rescue if limit_mb is not number.

    my $limit = int( 1024 * 1024 * $limit_mb );
    my $result = MT->model('ma_cache')->cleanup_to_size($limit);

    # TODO How about notification?
    eval {
        require MT::Log;
        if ( $result->{removed} ) {
            $app->log({
                message => plugin->translate(
                    'MoreAnalytics cleanup cache. [_1] cache(s), [_2] bytes cleanup, limit to [_3] bytes, currently total [_4] bytes.',
                        $result->{removed}, $result->{reduced}, $limit, $result->{current}
                ),
                class    => 'system',
                category => 'plugin',
                level    => MT::Log::INFO()
            });
        } else {
            $app->log({
                message => plugin->translate(
                    'MoreAnalytics checked cache size, but current total [_1] bytes is within the limit of [_2] bytes.',
                        $limit, $result->{current}
                ),
                class    => 'system',
                category => 'plugin',
                level    => MT::Log::INFO()
            });
        }

    };
}

1;