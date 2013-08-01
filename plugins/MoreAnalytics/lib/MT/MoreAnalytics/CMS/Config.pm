package MT::MoreAnalytics::CMS::Config;

use strict;
use warnings;

use MT::MoreAnalytics::Util;

sub system {
    my ( $app ) = @_;

    _dumper([map { ref $_ } @_]);

    plugin->load_tmpl('config/system.tmpl');
}

sub blog_config {
    
}

1;