package MT::MoreAnalytics::Tags;

use strict;
use warnings;

use MT::MoreAnalytics::Util qw(lookup_fileinfo);
use MT::MoreAnalytics::Provider;
use MT::MoreAnalytics::Request;

{
    sub _lookup_more_analytics {
        my ( $ctx, $args ) = @_;
        my $app = MT->instance;

        # Context cache
        my $providers = ( $ctx->{__stash}{ma_providers} ||= {} );

        # Requires blog context
        my $blog_id = $args->{blog_id} || $args->{blog_ids};
        my $blog = $blog_id
            ? ( MT->model('blog')->load($blog_id) || MT->model('website')->load($blog_id) )
            : $ctx->stash('blog');

        $blog or return $ctx->error(
                plugin->translate( '[_1] requires blog context.', 'mt:GAReport' ) );

        # Lookup cache
        return $providers->{$blog->id}
            if defined $providers->{$blog->id};

        # Check if MoreAnalytics provider is ready
        MT::MoreAnalytics::Provider->is_ready( $app, $blog )
            or return $ctx->error(
                plugin->translate( 'Google Analytics is not ready for blog or website ID:[_1]', $blog->id ) );

        # Generate MoreAnalytics provider and store to cache
        $providers->{$blog->id}
            = MT::MoreAnalytics::Provider->new( 'MoreAnalytics', $blog );
    }
}

sub hdlr_GAReport {
    my ( $ctx, $args, $cond ) = @_;
    my $app = MT->instance;
    my $builder = $ctx->stash('builder');
    my $tokens = $ctx->stash('tokens');

    my $ma = _lookup_more_analytics( $ctx, $args );
    my $request = MT::MoreAnalytics::Request->new($args);

    defined ( my $data = $ma->_request( $app, $request->normalize ) )
        or return $ctx->error($app->errstr);

    # Check if items is array
    my $items = $data->{items};
    return $ctx->error( plugin->translate('items is not an array.') )
        unless ref $items eq 'ARRAY';

    my $out = '';
    my $count = scalar @$items;
    local $ctx->{__stash}{ga_data} = $data;
    for ( my $i = 0; $i < $count; $i++ ) {
        my $item = $items->[$i];

        local $ctx->{__stash}{ga_record} = $item;
        local $ctx->{__stash}{vars} = {
            __index__   => $i,
            __number__  => $i + 1,
            __count__   => $count,
            __first__   => ($i == 0)? 1: 0,
            __even__    => ($i % 2)? 0: 1,
            __odd__     => ($i % 2)? 1: 0,
            __last__    => ($i == $count-1)? 1: 0,
            __break__   => 0,
        };

        defined ( my $line = $builder->build($ctx, $tokens) )
            or return $ctx->error($builder->errstr);

        last if $ctx->var('__break__');

        $out .= $line;
    }

    $out;
}

sub _hdlr_GAReportBreak {
    my ( $ctx, $args ) = @_;
    $ctx->var('__break__', 1);
    '';
}

sub _hdlr_GAReportPosition {
    my ( $tag, $position, $ctx, $args, $cond ) = @_;
    my $record = $ctx->stash('ga_record')
        or return $ctx->error(
            plugin->translate('[_1] is not used in mt:GAReport context.', $tag ) );

    $ctx->var($position)? 1: 0;
}

sub hdlr_GAReportHeader {
    _hdlr_GAReportPosition( 'mt:GAReportHeader', '__first__', @_ );
}

sub hdlr_GAReportFooter {
    _hdlr_GAReportPosition( 'mt:GAReportFooter', '__last__', @_ );
}

sub hdlr_GAValue {
    my ( $ctx, $args ) = @_;
    my $record = $ctx->stash('ga_record')
        or return $ctx->error(
            plugin->translate('[_1] is not used in mt:GAReport context.', 'mt:GAValue' ) );

    my $name = $args->{name}
        or return $ctx->error(
            plugin->translate( '[_1] requires [_2] attribute.', 'mt:GAReport', 'name' ) );

    $record->{$name};
}

sub hdlr_GAGuessObject {
    my ( $ctx, $args, $cond ) = @_;
    my $blog = $ctx->stash('blog');
    my $type = $args->{type} || '';
    my $builder = $ctx->stash('builder');
    my $tokens = $ctx->stash('tokens');

    # Type shoud be entry, category or template
    $type = '' if $type !~ /^(entry|category|template)$/;

    # Requres mt:GAReport context
    my $record = $ctx->stash('ga_record')
        or return $ctx->error(
            plugin->translate( '[_1] is not used in mt:GAReport context.', 'mt:GALookupObject' ) );

    # Detect target path
    my $path = $args->{path} || $record->{pagePath}
        or return $ctx->error(
            plugin->translate( '[_1] is requires pagePath as report dimension or path attribute.', 'mt:GALookupObject' ) );

    # Look up fileinfo
    my $fi = lookup_fileinfo( $blog, $path ) or return '';

    # Look up related objects
    my %objects;
    $objects{blog} = MT->model('blog')->load($fi->blog_id)
        || MT->model('website')->load($fi->blog_id)
        if $fi->blog_id;
    $objects{template} = MT->model('template')->load($fi->template_id)
        if $fi->template_id;
    $objects{entry} = MT->model('entry')->load($fi->entry_id)
        || MT->model('page')->load($fi->entry_id)
        if $fi->entry_id;
    $objects{category} = MT->model('category')->load($fi->category_id)
        || MT->model('folder')->load($fi->category_id)
        if $fi->category_id;

    # Skip if no object for the type
    return '' if $type && !$objects{$type};

    my $stash = $ctx->{__stash};
    my @locals = keys %objects;
    local @$stash{@locals} = map { $objects{$_} } @locals;
    local $ctx->{__stash}{ga_objects} = \%objects;

    defined ( my $out = $builder->build($ctx, $tokens) )
        or return $ctx->error($builder->errstr);

    $out;
}

sub hdlr_GAIfObjectType {
    my ( $ctx, $args, $cond ) = @_;
    my $is = $args->{is} || $args->{type}
        or return $ctx->error('mt:GAIfObjectType is requires "is" or "type" attribute.');

    $ctx->{__stash}{ga_objects}{$is} ? 1 : 0;
}

1;