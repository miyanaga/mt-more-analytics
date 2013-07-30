package MT::MoreAnalytics::App::Widget;

use strict;
use warnings;

sub _custom_widget {
    my ( $app, $tmpl, $widget_param ) = @_;

    1;
}

sub custom_main_widget { _custom_widget(@_) }
sub custom_sidebar_widget { _custom_widget(@_) }

sub _get_custom_tmpl {
    my ( $app, $type ) = @_;
    my $blog = $app->blog;
    my $author = $app->user;
    my $blog_id = $app->param('blog_id');

    if ( $blog ) {
        return ( $blog->ma_custom_widget, { blog => $blog, author => $author }, {} );
    } elsif ( !defined($blog_id) ) {
        return ( $author->ma_custom_widget, { author => $app->user }, {} );
    }
}

sub _save_custom_tmpl {
    my ( $app, $type, $tmpl ) = @_;
    my $blog = $app->blog;
    my $author = $app->user;
    my $blog_id = $app->param('blog_id');

    if ( $blog ) {
        $blog->ma_custom_widget($tmpl);
        $blog->save;
    } elsif ( !defined($blog_id) ) {
        my $author = $app->user;
        $author->ma_custom_widget($tmpl);
        $author->save;
    }
}

sub _instant_build {
    my ( $app, $tmpl, $stash, $vars ) = @_;

    require MT::Builder;
    require MT::Template::Context;
    my $builder = MT::Builder->new;
    my $ctx = MT::Template::Context->new;

    if ( $stash ) {
        $ctx->stash($_, $stash->{$_}) foreach $stash;
    }

    if ( $vars ) {
        $ctx->var($_, $vars->{$_}) foreach $vars;
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

sub view {
    my ( $app ) = @_;
    my $widget = 'ma_custom'; # Placeeholder

    my @context = _get_custom_tmpl;

    require MT::Builder;
}

sub edit {
    my ( $app ) = @_;
    my $widget = 'ma_custom'; # Placeeholder

}

sub save {
    my ( $app ) = @_;
    my $widget = 'ma_custom'; # Placeeholder

}

1;