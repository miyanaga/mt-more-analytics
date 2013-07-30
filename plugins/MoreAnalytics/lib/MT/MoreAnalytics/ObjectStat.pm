package MT::MoreAnalytics::ObjectStat;
use strict;

use base qw(MT::Object);
use MT::MoreAnalytics::Util;

__PACKAGE__->install_properties(
    {   column_defs => {
            'id'             => 'integer not null auto_increment',
            'blog_id'        => 'integer not null',
            'object_ds'      => 'string(64) not null',
            'object_id'      => 'integer not null',
            'ma_period_id'   => 'integer not null',
            'age'            => 'integer',
            'pageviews'      => 'integer',
            'unique_pageviews' => 'integer',
            'entrance_rate'  => 'float',
            'exit_rate'      => 'float',
            'visit_bounce_rate' => 'float',
            'avg_page_download_time' => 'float',
            'avg_page_load_time' => 'float',
            'avg_time_on_page' => 'float',
        },
        indexes => {
            blog_id        => 1,
            age => 1,
        },
        datasource  => 'ma_object_stat',
        primary_key => 'id',
        cacheable   => 0,
    }
);

sub class_label { plugin->translate('Object Statistics') }
sub class_label_plural { plugin->translate('Object Statistics') }

sub cleanup {
    my $class = shift;
    # TODO Imprement 
}

1;
