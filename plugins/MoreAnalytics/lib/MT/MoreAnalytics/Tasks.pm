package MT::MoreAnalytics::Tasks;

use strict;
use warnings;

use MT::Util qw(format_ts epoch2ts);
use MT::MoreAnalytics::Util qw(observe_date_range lookup_fileinfo _dumper);
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

sub update_fileinfo_stats {
    my $task = shift;
    my $app = MT->instance;

    my $iter = MT->model('blog')->load_iter( { class => '*' } )
        or return;

    while ( my $blog = $iter->() ) {

        my $ts = epoch2ts($blog, time);

        MT::MoreAnalytics::Provider->is_ready( $app, $blog ) or next;
        my $ma = MT::MoreAnalytics::Provider->new( 'MoreAnalytics', $blog );

        my $request = MT::MoreAnalytics::Request->new(
            observe_date_range( $blog ),
            metrics     => join(',', values %OBSERVE_MAP),
            dimensions  => 'pagePath',
        );

        my $data = $ma->_request($app, $request->normalize);
        my $items = $data->{items};
        next if ref $items ne 'ARRAY';

        foreach my $record ( @$items ) {
            my $fi = lookup_fileinfo( $blog, $record->{pagePath} ) or next;

            my $values = { 
                ga_observed_on => $ts,
                map {
                    my $snake = $_;
                    my $camel = $OBSERVE_MAP{$_};

                    "ga_$snake" => $record->{$camel} || 0,
                } keys %OBSERVE_MAP,
            };

            use MT::MoreAnalytics::Util;
            _dumper($values);

            $fi->set_values($values);
            $fi->save;
        }

    }
}

1;