package MT::MoreAnalytics::App::CMS;

use strict;
use warnings;

use File::Spec;
use MT::MoreAnalytics::Util;
use MT::MoreAnalytics::Provider;
use MT::MoreAnalytics::PeriodMethod;

sub profiles {
    my $app = shift;
    my $blog = $app->blog or return '';
    my %param;

    # Check if MoreAnalytics provider is ready
    MT::MoreAnalytics::Provider->is_ready( $app, $blog )
        or return $app->error(
            plugin->translate( 'Google Analytics is not ready for blog or website ID:[_1]', $blog->id ) );

    # Generate MoreAnalytics provider and store to cache
    my $provider
        = MT::MoreAnalytics::Provider->new( 'MoreAnalytics', $blog );

    $param{profiles} = $provider->profiles($app);

    plugin->load_tmpl('playground/profiles.tmpl', \%param);
}


sub drop_all_caches {
    my ( $app ) = @_;

    # Check permission
    my $user = $app->user;
    return $app->json_error(plugin->translate('Permission denied.'))
        if !$user->is_superuser;

    MT->model('ma_cache')->remove;

    $app->json_result(plugin->translate('Droped all caches.'));
}

1;