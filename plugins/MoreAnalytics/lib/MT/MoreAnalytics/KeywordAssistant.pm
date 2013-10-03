package MT::MoreAnalytics::KeywordAssistant;

use strict;

use Carp;
use MT::MoreAnalytics::Util;
use MT::Util qw(epoch2ts format_ts);

sub context_pref {
    my ( $app, $user ) = @_;
    my $blog = $app->blog or Carp::confess('context_pref requires blog');

    # Keyword assistant prefs, 1st the blog, 2nd parent if can, 3rd global:0, or empty
    my $ka_prefs = $app->user->ma_ka_prefs || {};
    my $pref = $ka_prefs->{$blog->id};
    $pref = $ka_prefs->{$blog->parent_id} if !$pref && $blog->is_blog;
    $pref = $ka_prefs->{0} || {} unless $pref;

    $pref;
}

sub actual_ignore_config {
    my ( $app, $blog ) = @_;
    $blog ||= $app->blog;
    my $config = MT::MoreAnalytics::Util::actual_config($blog);

    # Escape each word
    my @keywords = map { s/[\\,;]/\\$&/g; $_ }
        grep { length($_) > 0 }
        split( /\r?\n/, $config->{ka_ignore_keywords} || '' );
    @keywords = @keywords[0..4] if scalar(@keywords) > 4; # At most 5 keywords
    my $regex = $config->{ka_ignore_regex} || '';

    ( \@keywords, $regex );
}

sub actual_ignore_filters {
    my ( $app, $blog ) = @_;
    my ( $keywords, $regex ) = actual_ignore_config(@_);

    my @filters = map { qq{keyword!=$_} } ( @$keywords, '(not set)', '(not provided)' );
    push @filters, qq{keyword!~$regex} if length($regex) > 0;

    join( ';', @filters ) || '';
}

sub hdlr_default_metric_handler {
    my ( $app, $metric, $param ) = @_;

    # Target field
    my $field = $metric->{metric};
    $param->{metrics} = $field;

    # Sort direction
    my $dir = ( $metric->{sort} || '' ) eq 'ascend'? '': '-';
    $param->{sort} = $dir . $field;

    # Format
    my $formatter = MT->handler_to_coderef( $metric->{formatter} );

    # Query and format
    my $data = ga_simple_request($app, $param);
    my @results = map {
        {
            keyword => $_->{keyword} || '',
            value => $formatter? $formatter->($_->{$field}): $_->{$field},
        }
    } @{$data->{items}};

    \@results;
}

sub hdlr_default_term_handler {
    my ( $app, $term ) = @_;

    # Unit
    my $days = $term->{days} || 0;
    my $now = time;
    my $a_day = 60 * 60 * 24;
    my $end_date = epoch2ts($app->blog, $now - $a_day);
    my $start_date = epoch2ts($app->blog, $now - $a_day * $days);

    ( $start_date, $end_date );
}

1;