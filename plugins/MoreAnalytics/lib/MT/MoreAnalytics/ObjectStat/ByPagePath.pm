package MT::MoreAnalytics::ObjectStat::ByPagePath;

use strict;
use warnings;

use MT::Util qw(format_ts epoch2ts);
use MT::MoreAnalytics::Util;
use MT::MoreAnalytics::Provider;
use MT::MoreAnalytics::Request;

sub stats {
    my $order = 5000;
    my $stats = {
        pageviews => {
            base    => '__stat_common.integer',
            col     => 'pageviews',
            metrics => 'pageviews',
            label   => 'GA:Pageviews',
            order   => $order++,
        },
    };

    $stats;
}

sub update_object_limit {
    my %config;
    plugin->load_config(\%config, 'system');
    $config{update_object_limit} || 1000;
}

sub task {
    my ( $eh, %param ) = @_;
    my ( $app, $task, $report, $blog, $p, $age, $ma )
        = map { $param{$_} } qw/app task report blog period age provider/;

    my $stats = MT->registry('more_analytics', 'object_stats', 'by_page_path') || {};
    my %metrics;
    foreach my $stat ( values %$stats ) {
        my $metrics = $stat->{metrics} || next;
        if ( ref $metrics eq 'ARRAY' ) {
            $metrics{$_} = 1 foreach @$metrics;
        } elsif ( !ref $metrics ) {
            $metrics{$metrics} = 1;
        }
    }

    # TODO add filter.
    my $request = MT::MoreAnalytics::Request->new(
        $p->ga_date_range($blog),
        metrics     => join(',', keys %metrics),
        dimensions  => 'pagePath',
        'max-results' => update_object_limit(),
    );

    my $data = $ma->_request($app, $request->normalize);
    $report->{queries}++;

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
        }

        # Store to object_stat
        my $values;

        if ( $ds ) {
            $values = {
                blog_id => $blog->id,
                object_ds => $ds,
                object_id => $id,
                ma_period_id => $p->id,
            };
        } else {
            # TODO callback to reqcue
            next;
        }

        my $stat = MT->model('ma_object_stat')->load($values)
            || MT->model('ma_object_stat')->new;

        $values->{age} = $age;
        foreach my $stat ( values %$stats ) {
            my $col = $stat->{col} || next;

            # Handle if computed stat
            if ( my $compute = $stat->{compute} ) {
                $compute = MT->handler_to_coderef($compute);
                $values->{$col} = $compute->( $r )
                    if ref $compute eq 'CODE';
            } elsif ( !ref $stat->{metrics} ) {
                $values->{$col} = $r->{$stat->{metrics}};
            }

            # Default value
            $values->{$col} = $stat->{default}
                unless defined $values->{$col};
        }

        $stat->set_values($values);
        $stat->save;
        $report->{stats}++;
    }
}

1;