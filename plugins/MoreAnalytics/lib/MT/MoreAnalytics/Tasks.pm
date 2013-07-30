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

sub update_object_stats {
    my $task = shift;
    my $app = MT->instance;

    my $iter = MT->model('blog')->load_iter( { class => '*' } )
        or return;

    # Loop blogs.
    while ( my $blog = $iter->() ) {

        # Loop periods.
        my @ids = ( 0, $blog->id );
        if ( !$blog->is_blog ) {
            push @ids, map { $_->id } @{$blog->blogs};
        }

        my @periods = MT->model('ma_period')->load({blog_id => \@ids});
        foreach my $p ( @periods ) {
            my $age = time;

            MT::MoreAnalytics::Provider->is_ready( $app, $blog ) or next;
            my $ma = MT::MoreAnalytics::Provider->new( 'MoreAnalytics', $blog );

            my $request = MT::MoreAnalytics::Request->new(
                $p->ga_date_range($blog),
                metrics     => join(',', values %OBSERVE_MAP),
                dimensions  => 'pagePath',
            );

            my $data = $ma->_request($app, $request->normalize);
            my $items = $data->{items};
            next if ref $items ne 'ARRAY';

            foreach my $r ( @$items ) {
                my $fi = lookup_fileinfo( $blog, $r->{pagePath} ) or next;

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
            }

            # Cleanup
            MT->model('ma_object_stat')->remove({
                blog_id => $blog->id,
                ma_period_id => $p->id,
                age => { '<' => $age },
            });
        }
    }
}

1;