package MT::MoreAnalytics::Cache;

use strict;
use base qw(MT::Object);
use MT::Util qw(epoch2ts);

my $DEFAULT_EXPIRES = 60;

__PACKAGE__->install_properties(
    {   column_defs => {
            'id'          => 'integer not null auto_increment',
            'blog_id'     => 'integer not null',
            'ns'          => 'string(64) not null',
            'serial'      => 'string(128) not null',
            'blob'        => 'blob',
            'text'        => 'text',
            'expires_on'  => 'datetime',
        },
        indexes => {
            blog_id       => 1,
            ns            => 1,
            serial        => 1,
            expires_on    => 1,
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

sub store {
    my $pkg = shift;
    my %args = @_;

    # Remove values
    my $text = delete $args{text} || '';
    my $blob = delete $args{blob} || '';
    my $expires = delete $args{expires} || $DEFAULT_EXPIRES;

    # Lookup blog
    my $blog = delete $args{blog} || 0;
    my $blog_id = ref $blog ? $blog->id : $blog;

    # Create or update with extension of life
    my $cache = $pkg->load(\%args) || $pkg->new;
    $cache->set_values({
        text        => $text,
        blob        => $blob,
        expires_on  => epoch2ts( undef, time + $expires ),
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
    return $cache if $cache->expires_on < $now;

    # Remove and return undef because expired
    $cache->remove;
    undef;
}

1;