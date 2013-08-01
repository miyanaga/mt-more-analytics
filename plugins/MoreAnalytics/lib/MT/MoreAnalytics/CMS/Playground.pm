package MT::MoreAnalytics::CMS::Playground;

use strict;
use warnings;

use MT::MoreAnalytics::Util;
use MT::MoreAnalytics::Provider;
use MT::MoreAnalytics::Request;

sub index {
    my $app = shift;
    my $blog = $app->blog;
    my $blog_id = $blog->id;
    my %param;

    # Check permission
    my $user = $app->user;
    return $app->permission_denied()
        if !$user->is_superuser
            && !$user->permissions($app->param('blog_id') || 0)->can_do('ma_playground');

    my $plugindata = GoogleAnalytics::current_plugindata( $app, $app->blog );
    my $config = $plugindata->data;
    my $profile_id = $config->{profile_id} || return $app->error('No profile');

    $param{more_analytics_version_id} = plugin->{version};
    $param{current_profile_id} = $profile_id;

    # Metrics and dimensions for the language
    {
        my $lang = MT->current_language;
        my $base = File::Spec->catdir(MT->instance->config('StaticFilePath'), qw(plugins MoreAnalytics metrics-and-dimensions));
        my $path = File::Spec->catdir($base, "$lang.js");
        $lang = 'en_US' unless -f $path;        

        $param{metrics_and_dimensions_lang} = $lang;
    }

    # Load periods and pass as param
    my @blog_ids = (0);
    push @blog_ids, $blog_id if $blog_id;
    if ( my $blog = $app->blog ) {
        if ( !$blog->is_blog ) {
            push @blog_ids, map { $_->id } @{ $blog->blogs };
        }
    }

    my @periods = map {
        {
            basename => $_->basename,
            name => $_->long_name,
            is_selected => ($_->basename == 'default' ?1 : 0),
        }
    } MT->model('ma_period')->load({blog_id => \@blog_ids});

    $param{ma_period_loop} = \@periods;

    plugin->load_tmpl('playground.tmpl', \%param);
}

sub query {
    my $app = shift;
    my %hash = $app->param_hash;
    my $blog = $app->blog
        or return $app->json_error(plugin->translate('Blog required.'));

    return $app->json_error(plugin->translate('Request needs a metric at least.'))
        if !defined($hash{metrics}) || length($hash{metrics}) < 1;

    # Check permission
    my $user = $app->user;
    return $app->json_error($app->translate('Permission denied.'))
        if !$user->is_superuser
            && !$user->permissions($app->param('blog_id') || 0)->can_do('ma_playground');

    # Max results limit to 1000
    my $max_results = $hash{'max-results'} || $hash{'max_results'} || 1000;
    $max_results = 1000 if $max_results > 1000;

    # Aggregation
    if ( my $ma_period = delete $hash{'ma-period'} ) {
        my $period = MT->model('ma_period')->load({basename => $ma_period})
            or return $app->json_error(plugin->translate('Unknown period [_1]', $ma_period));
        $hash{'start-date'} = $hash{'start_date'} = $period->from_method->format_ga($blog);
        $hash{'end-date'} = $hash{'end_date'} = $period->to_method->format_ga($blog);
    }

    # Prepare MoreAnalytics provider
    MT::MoreAnalytics::Provider->is_ready( $app, $blog )
        or return $app->json_error(plugin->translate('Google Analytics is not set up for this blog or website.'));

    my $ma = MT::MoreAnalytics::Provider->new( 'MoreAnalytics', $blog )
        or return $app->json_error(plugin->translate('Cannot create MoreAnalytics provider object.'));

    # Send request
    my $request = MT::MoreAnalytics::Request->new(\%hash);
    defined( my $data = $ma->_request( $app, $request->normalize ) )
        or return $app->json_error($app->errstr);

    $app->json_result($data);
}

1;