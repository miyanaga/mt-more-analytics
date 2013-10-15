package MT::MoreAnalytics::CMS::Config;

use strict;
use warnings;

use MT::MoreAnalytics::Util;
use MT::MoreAnalytics::KeywordAssistant;

sub system {
    my ( $plugin, $param ) = @_;

    plugin->load_tmpl('config/system.tmpl');
}

sub blog_config {
    my ( $plugin, $param ) = @_;
    my $app = MT->instance;
    my $blog = $app->blog;

    # Parent config
    my $parent = $blog->is_blog? $blog->website: undef;
    $param->{inherit_from} = $blog->is_blog? 'website': 'system';
    my ( $parent_keywords, $parent_regex ) = MT::MoreAnalytics::KeywordAssistant::actual_ignore_config( $app, $parent );

    $param->{parent_ka_ignore_keywords} = join( ',', map { qq{"$_"} } @$parent_keywords );
    $param->{parent_ka_ignore_regex} = $parent_regex;

    # No settings
    foreach my $k ( qw/keywords regex/ ) {
        my $n = "parent_ka_ignore_${k}";
        $param->{$n} = plugin->translate('(No Settings)')
            if length($param->{$n}) < 1;
    }

    plugin->load_tmpl('config/blog.tmpl');
}

1;