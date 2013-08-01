package MT::MoreAnalytics::CMS::Widget;

use strict;
use warnings;
use MT::MoreAnalytics::Util;

sub _custom_widget {
    my ( $app, $tmpl, $widget_param ) = @_;
    my $author = $app->user;
    my $blog = $app->blog;
    my $widget = 'ma_custom_widget'; # Placeholder

    # TODO permission
    my $template = $blog
        ? $blog->$widget
        : $author->$widget;

    # Check permission
    if ( $blog ) {

        # For blog, user needs permission
        my $user = $app->user;
        $widget_param->{editable} = $user->is_superuser
            || $user->permissions($app->param('blog_id') || 0)->can_do('ma_edit_custom_widget');
    } else {

        # No blog, user dashboard always editable
        $widget_param->{editable} = 1;
    }

    $widget_param->{more_analytics_version_id} = plugin->{id};
    $widget_param->{has_template} = 1 if defined $template;

    1;
}

sub custom_main_widget { _custom_widget(@_) }
sub custom_sidebar_widget { _custom_widget(@_) }

sub _instant_build {
    my ( $app, $tmpl, $stash, $vars ) = @_;

    # Template should be string
    $tmpl = '' unless defined $tmpl;

    require MT::Builder;
    require MT::Template::Context;
    my $builder = MT::Builder->new;
    my $ctx = MT::Template::Context->new;

    if ( $stash ) {
        $ctx->stash($_, $stash->{$_}) foreach keys %$stash;
    }

    if ( $vars ) {
        $ctx->var($_, $vars->{$_}) foreach keys %$vars;
    }

    if ( my $tokens = $builder->compile($ctx, ref $tmpl ? $tmpl->text : $tmpl) ) {
        if ( defined( my $res = $builder->build($ctx, $tokens) ) ) {
            return $res;
        } else {
            return $app->error($builder->errstr);
        }
    } else {
        return $app->error($builder->errstr);
    }
}

sub custom_widget_ajax {
    my ( $app ) = @_;
    my $q = $app->param;
    my $author = $app->user;
    my $blog = $app->blog;
    my $action = $q->param('action');
    my $widget = 'ma_custom_widget'; # Placeholder # $q->param('widget');

    # Check permission only for blog widget editing
    if ( $blog && $action ne 'view' ) {
        my $user = $app->user;
        return $app->json_error(plugin->translate('Permission denigied.'))
            if !$user->is_superuser
                && !$user->permissions($blog->id)->can_do('ma_edit_custom_widget');
    }

    my $current_template = $blog
        ? $blog->$widget
        : $author->$widget;

    if ( $action eq 'edit' ) {

        # Return raw template
        return $app->json_result({template => $current_template || 'welcome'});
    } elsif ( $action eq 'save' or $action eq 'preview' or $action eq 'view' ) {

        # Template is current or passed
        my $template = $action eq 'view'
            ? $current_template
            : $q->param('template');

        # Build the template
        defined ( my $render = _instant_build( $app, $template, { blog => $blog, author => $author }, {} ) )
            or return $app->json_error($app->errstr);

        # Save if action is save
        if ( $action eq 'save' ) {
            my $to_save = $blog || $author;
            $to_save->$widget($template);
            $to_save->save()
                or return $app->json_error($to_save->errstr);
        }

        return $app->json_result({ viewport => $render});
    }

    $app->json_error(plugin->translate('Unknown action'));
}

1;