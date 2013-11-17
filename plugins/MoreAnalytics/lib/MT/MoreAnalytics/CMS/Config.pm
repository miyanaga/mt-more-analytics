package MT::MoreAnalytics::CMS::Config;

use strict;
use warnings;

use MT::MoreAnalytics::Util;
use MT::MoreAnalytics::KeywordAssistant;

sub data_api_policies {
    my ( $plugin, $param, $actual ) = @_;

    # Data API Policy
    my $options = MT->registry('more_analytics', 'data_api_policy_options');
    foreach my $var ( qw/ondemand_data_api_policy stats_data_api_policy/ ) {
        my $array = $var;
        $array =~ s/_policy/_policies/;

        # Oritinal Options
        my @options;

        # Inheritance
        if ( $actual ) {
            my $label = $options->{$actual->{$var}}->{label};
            push @options, {
                value => '',
                label => plugin->translate('Inherit from Parent - [_1]', $label),
                checked => $param->{$var} ? 0 : 1,
            };
        } else {

            # System
            $param->{$var} ||= 'deny';
        }

        push @options, map {
            my $value = {
                value => $_,
                label => $options->{$_}->{label},
                checked => $param->{$var} eq $_ ? 1: 0,
            };

            $value;
        } sort {
            ( $options->{$a}{order} || 1000 ) <=> ( $options->{$b}{order} || 1000 );
        } keys %$options;

        $param->{$array} = \@options;
    };
}

sub system_config {
    my ( $plugin, $param ) = @_;

    data_api_policies( $plugin, $param );

    plugin->load_tmpl('config/system.tmpl');
}

sub blog_config {
    my ( $plugin, $param ) = @_;
    my $app = MT->instance;
    my $blog = $app->blog;

    # Parent config
    my $parent = $blog->is_blog? $blog->website: undef;
    my $actual = actual_config($parent);

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

    data_api_policies( $plugin, $param, $actual );

    plugin->load_tmpl('config/blog.tmpl');
}

1;