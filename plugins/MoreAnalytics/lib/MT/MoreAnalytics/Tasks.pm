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

sub update_object_stats_freq {
    my %config;
    plugin->load_config(\%config, 'system');
    _dumper('reach');
    $config{update_object_stats_freq_min} * 60;
}

sub update_object_stats {
    my $task = shift;
    my $app = MT->instance;

    my $iter = MT->model('blog')->load_iter( { class => '*' } )
        or return;

    # Loop blogs and periods.
    my %blog_ids;
    my %period_ids;
    my $queries = 0;
    my $stats = 0;
    my $removed = 0;

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

            my $request = MT::MoreAnalytics::Request->new(
                $p->ga_date_range($blog),
                metrics     => join(',', values %OBSERVE_MAP),
                dimensions  => 'pagePath',
            );

            my $data = $ma->_request($app, $request->normalize);
            $queries++;

            my $items = $data->{items};
            next if ref $items ne 'ARRAY';

            foreach my $r ( @$items ) {

                # Lookup object via fileinfo
                my $fi = MT::MoreAnalytics::Util::lookup_fileinfo( $blog, $r->{pagePath} ) or next;

                my ( $ds, $id );
                if ( $id = $fi->entry_id ) {
                    $ds = 'entry';
                } elsif ( $id = $fi->category_id ) {
                    $ds = 'category';
                } elsif ( $id = $fi->template_id ) {
                    $ds = 'template';
                } else {
                    next;
                }

                # Store to object_stat
                my $values = {
                    blog_id => $blog->id,
                    object_ds => $ds,
                    object_id => $id,
                    ma_period_id => $p->id,
                };

                my $stat = MT->model('ma_object_stat')->load($values)
                    || MT->model('ma_object_stat')->new;

                $values = {
                    %$values,
                    age => $age,
                    map {
                        my $snake = $_;
                        my $camel = $OBSERVE_MAP{$_};

                        ( $snake => $r->{$camel} || 0 );
                    } keys %OBSERVE_MAP,
                };

                $stat->set_values($values);
                $stat->save;
                $stats++;
            }

            # Cleanup
            my $terms = {
                blog_id => $blog->id,
                ma_period_id => $p->id,
                age => { '<' => $age },
            };
            $removed = MT->model('ma_object_stat')->count($terms);
            MT->model('ma_object_stat')->remove($terms);
        }
    }

    # TODO How about notification?
    eval {
        require MT::Log;
        $app->log({
            message => plugin->translate(
                'MoreAnalytics updated object stats. [_1] blog(s), [_2] period(s), [_3] query(ies), [_4] stat(s).',
                    scalar keys %blog_ids, scalar keys %period_ids, $queries, $stats
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