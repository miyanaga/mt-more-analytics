package MT::MoreAnalytics::Tags::Util;

use strict;
use MT::Util;
use MT::Entry;
use MT::MoreAnalytics::Util;

sub hdlr_GADateDiff {
    my ( $ctx, $args ) = @_;
    my $blog = $ctx->stash('blog');
    my $base = $args->{base};
    $base = 1 unless defined $base;

    # Days
    my $days = $base + date_diff( $blog, $args->{from} || $args->{start}, $args->{to} || $args->{end} );

    $days;
}

sub hdlr_GACompareEntries {
    my ( $ctx, $args, $cond ) = @_;
    my $current = $ctx->stash('entry')
        or return $ctx->_no_entry_error();

    # Direction: default previous
    my $dir = $args->{dir} || '';
    $dir = 'previous' if $dir ne 'next';

    my $terms = { status => MT::Entry::RELEASE() };
    $terms->{by_author}   = 1 if $args->{by_author};
    $terms->{by_category} = 1 if $args->{by_category};

    my $count = $args->{entries} || 2;
    my @entries;

    # First one
    if ( $dir eq 'next' ) {
        push @entries, $current;
    } else {
        unshift @entries, $current;
    }
    $count --;
    my $entry = $current->$dir($terms);

    # Unshift others
    for ( my $i = 0; $entry && $i < $count; $i++ ) {
        if ( $dir eq 'next' ) {
            push @entries, $entry;
        } else {
            unshift @entries, $entry;
        }
        $entry = $entry->$dir($terms);
    }

    # Reverse?
    @entries = reverse @entries if $args->{reverse};

    my @ids = map { $_->id } @entries;

    # Loop entries and build
    my $out = '';
    my $builder = $ctx->stash('builder');
    my $tokens = $ctx->stash('tokens');
    my $index = 1;
    foreach my $e ( @entries ) {
        local $ctx->{__stash}->{entry} = $e;
        local $ctx->{__stash}{vars}{__is_current__} = $e->id == $current->id ? 1: 0;
        local $ctx->{__stash}{vars}{__index__} = $index++;
        local $ctx->{current_timestamp} = $e->authored_on;
        my $partial = $builder->build( $ctx, $tokens, $cond );
        return $ctx->error( $builder->errstr ) unless defined $partial;
        $out .= $partial;
    }

    $out;
}

1;