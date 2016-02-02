package MT::MoreAnalytics;

use strict;
use warnings;

# FIXME! Dummy hook to load this file in bootstrap
sub on_post_init { 1 }

sub on_post_save_plugin_config {
    my ( $cb, $obj ) = @_;

    # Reboot if config updated
    MT->app->reboot if $obj->plugin eq 'MoreAnalytics';

    1;
}

# Support system.ma_manage_period system permission.

package MT::Author;

sub can_ma_manage_period {
    my $author = shift;
    if (@_) {
        $author->permissions(0)->can_ma_manage_period(@_);
    }
    else {
        $author->is_superuser()
            || $author->permissions(0)->can_ma_manage_period(@_);
    }
}

1;