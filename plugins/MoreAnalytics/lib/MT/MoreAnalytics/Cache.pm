package MT::MoreAnalytics::Cache;

use strict;
use base qw(MT::Object);
use MT::Util qw(epoch2ts);
use MT::MoreAnalytics::Util;

my $DEFAULT_EXPIRES = 60;

__PACKAGE__->install_properties(
    {   column_defs => {
            'id'          => 'integer not null auto_increment',
            'blog_id'     => 'integer not null',
            'ns'          => 'string(64) not null',
            'serial'      => 'string(128) not null',
            'blob'        => 'blob',
            'text'        => 'text',
            'size'        => 'integer',
            'expires_on'  => 'datetime',
        },
        indexes => {
            expires_on    => 1,
            usual_lookup  => {
                columns => [qw/blog_id ns serial/],
            },
        },
        defaults => {
            blog_id       => 0,
            ns            => '',
            serial        => '',
        },
        audit         => 1,
        datasource    => 'ma_cache',
        primary_key   => 'id',
    }
);

sub class_label { plugin->translate('MoreAnalytics Cache') }
sub class_label_plural { plugin->translate('MoreAnalytics Caches') }

sub store {
    my $pkg = shift;
    my %args = @_;

    # Remove values
    my $text = delete $args{text} || '';
    my $blob = delete $args{blob} || '';
    my $size = length($text) + length($blob);

    # Lookup blog
    my $blog = delete $args{blog} || 0;
    my $blog_id = ref $blog ? $blog->id : $blog;

    # Create or update with extension of life
    my $now = epoch2ts( undef, time );
    my $cache = $pkg->load(\%args) || $pkg->new;
    $cache->set_values({
        text        => $text,
        blob        => $blob,
        size        => $size,
        expires_on  => $now,
    });

    $cache->save;
}

sub lookup {
    my $pkg = shift;
    my %args = @_;

    # Load the cache or return
    my $cache = $pkg->load(\%args) || return undef;

    # Return the cache if available
    my $now = epoch2ts( undef, time );
    $cache->expires_on($now);
    $cache->save;

    $cache;
}

sub total_size {
    my $pkg = shift;
    my $total = 0;

    if ( my $iter = $pkg->sum_group_by( undef, { sum => 'size', group => ['ns'] } ) ) {
        while ( my ( $size, $ns ) = $iter->() ) {
            $total += $size;
        }
    }

    $total;
}

sub cleanup_to_size {
    my $pkg = shift;
    my ( $limit ) = @_;

    my $total = $pkg->total_size;
    return { removed => 0, reduced => 0, current => $total }
        if $total < $limit;

    my $iter = $pkg->load_iter( undef, {
        sort => 'expires_on',
        direction => 'descent',
        fetchonly => [qw/id size expires_on/],
    } );

    my $removed = 0;
    my $reduced = 0;
    my $size = $total;

    if ( $iter ) {
        while ( my $cache = $iter->() ) {
            $size -= $cache->size;
            $reduced += $cache->size;
            $removed++;

            $cache->remove;
            last if $size < $limit;
        }
    }

    { removed => $removed, reduced => $reduced, current => $size };
}

1;