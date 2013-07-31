package MT::MoreAnalytics::Tags;

use strict;
use warnings;

use MT::MoreAnalytics::Util qw(lookup_fileinfo _dumper);
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

    sub _dump_results {
        my ( $ctx, $args, $array ) = @_;
        no warnings 'uninitialized';

        # Collect headers
        my %headers;
        foreach my $row ( @$array ) {
            $headers{$_} = 1 foreach keys %$row;
        }
        my @headers = sort keys %headers;

        # Format: table, csv or tsv
        my $format = lc($args->{_dump} || '');
        $format = 'table' if $format !~ /^(table|csv|tsv)$/i;

        # Handler and separator by format
        my ( $sep, $headerer, $rower, $liner );
        if ( $format eq 'csv' || $format eq 'tsv' ) {
            $sep = $format eq 'csv'? ',': "\t";
            $headerer = $rower = sub {
                $_ = shift;
                $_ =~ s/"/\\"/;
                $_ = qq("$_") if /($sep|\n)/;
                $_;
            };
            $liner = sub { shift };
        } else {
            $headerer = sub {
                $_ = shift;
                "<th>$_</th>";
            };
            $rower = sub {
                $_ = shift;
                "<td>$_</td>";
            };
            $liner = sub {
                $_ = shift;
                "<tr>$_</tr>";
            };
        }

        $sep ||= '';
        my $result = '';

        # Concat headers
        $result .= $liner->(
            join( $sep,
                map { $headerer->($_) }
                @headers
            )
        );
        $result .= "\n";

        # Concat lines
        foreach my $r ( @$array ) {
            my $line = join( $sep,
                map { $rower->($_) }
                map { $r->{$_} }
                @headers
            );
            $result .= $liner->($line);
            $result .= "\n";
        }

        # For table
        $result = qq(<table>\n$result</table>)
            if $format eq 'table';

        $result;
    }
}

{
    sub _report_loop {
        my ( $ctx, $args, $data, $items ) = @_;

        # Loop inside
        my $builder = $ctx->stash('builder');
        my $tokens = $ctx->stash('tokens');
        my $out = '';
        my $count = scalar @$items;
        local $ctx->{__stash}{ga_data} = $data;
        local $ctx->{__stash}{ga_items} = $items;
        local $ctx->{__stash}{ga_break} = 0;
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

            last if $ctx->{__stash}{ga_break};

            $out .= $line;
        }

        $out;
    }
}

sub hdlr_GAReport {
    my ( $ctx, $args, $cond ) = @_;
    my $app = MT->instance;

    my $ma = _lookup_more_analytics( $ctx, $args );

    # Profile id from 1st: profile_id or ids args, 2nd: ga_profile stash, 3rd: blog default.
    $args->{ids} = delete $args->{profile_id} if $args->{profile_id};
    unless ( $args->{ids} ) {
        if ( my $profile = $ctx->stash('ga_profile') ) {
            $args->{ids} = $profile->{id} if $profile->{id};
        }
    }

    # Send request
    my $request = MT::MoreAnalytics::Request->new($args);
    defined ( my $data = $ma->_request( $app, $request->normalize ) )
        or return $ctx->error($app->errstr);

    # Check if items is array
    my $items = $data->{items};
    return $ctx->error( plugin->translate('items in results is not an array.') )
        unless ref $items eq 'ARRAY';

    # Dump mode
    return _dump_results( $ctx, $args, $items ) if $args->{_dump};

    _report_loop( $ctx, $args, $data, $items );
}

sub _hdlr_GAReportBreak {
    my ( $ctx, $args ) = @_;
    $ctx->{__stash}{ga_break} = 1;
    '';
}

{
    sub _hdlr_GAReportPosition {
        my ( $tag, $position, $ctx, $args, $cond ) = @_;
        my $record = $ctx->stash('ga_record')
            or return $ctx->error(
                plugin->translate('[_1] is not used in mt:GAReport context.', $tag ) );

        $ctx->var($position)? 1: 0;
    }
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

sub hdlr_GAProfiles {
    my ( $ctx, $args, $cond ) = @_;
    my $ma = _lookup_more_analytics( $ctx, $args )
        or return;

    my $profiles = $ma->profiles;

    # Dump mode
    return _dump_results( $ctx, $args, $profiles )
        if $args->{_dump};

    my $result = '';
    my $builder = $ctx->stash('builder');
    my $tokens = $ctx->stash('tokens');
    foreach my $profile ( @$profiles ) {
        local $ctx->{__stash}{ga_profile} = $profile;
        defined ( my $out = $builder->build($ctx, $tokens) )
            or return $ctx->error($builder->errstr);

        $result .= $out;
    }

    $result;
}

sub hdlr_GAProfile {
    my ( $ctx, $args ) = @_;

    my $profile = $ctx->stash('ga_profile')
        or return $ctx->error('[_1] should be in mt:GAProfiles context.', 'mt:GAProfile');
    my $name = $args->{name} || 'id';
    my $value = defined($profile->{$name}) ? $profile->{$name} : '';

    $value;
}

sub hdlr_Entries {
    my ( $ctx, $args, $cond ) = @_;
    my $sort_by = $args->{sort_by};

    if ( $sort_by && $sort_by =~ /^ga:(.+)$/i ) {
        my $col = $1;
        return $ctx->error(plugin->translate('[_1] is not found.', $col))
            unless MT->model('ma_object_stat')->has_column_def($col);

        my $ma_period = (delete $args->{'ga:period'}) || 'default';
        my $period = MT->model('ma_period')->load({basename => $ma_period})
            or return $ctx->error(
                plugin->translate('Aggregation period [_1] not found.', $ma_period));

        my $bulk_values;
        my $max_len = 0;
        my $default = '';

        # Temporary injection sorter method for MT::Template::Tags::Entry L1173
        # FIXME!
        require MT::Entry;
        local *MT::Entry::ma_sorter = sub {
            my $self = shift;

            unless( $bulk_values ) {

                # Lookup-table
                my @only = ( qw/object_id object_ds/, $col );
                my %values = map {
                    my $val = $_->$col;
                    $max_len = length($val) if $max_len < length($val);
                    ( $_->object_id => $val );
                } MT->model('ma_object_stat')->load({
                    ma_period_id => $period->id,
                    object_ds => 'entry',
                }, { fetchonly => \@only });

                # Pad head with 0 to sort with cmp in original mt:Entries
                # FIXME!!
                $values{$_} = ( '0' x ($max_len - length($values{$_})) ) . $values{$_}
                    foreach keys %values;
                $default = '0' x $max_len;

                $bulk_values = \%values;
            }

            $bulk_values->{$self->id} || $default;
        };

        # Clear sort_by and set ga:sort_by as 'ma_sorter'
        # entries_filter will swap these
        # FIXME!!!
        delete $args->{sort_by};
        local $args->{'ga:sort_by'} = 'ma_sorter';

        return $ctx->super_handler($args, $cond);

    } else {

        # Pass thru
        return $ctx->super_handler($args, $cond);
    }
}

sub entries_filter {
    my ( $ctx, $args, $cond ) = @_;

    my $s = delete $args->{'ga:sort_by'} or return;
    $args->{sort_by} = 'ma_sorter';

    return;
}

{
    sub ga_object_stat {
        my $tag = shift;
        my $scope = shift;
        my $model = shift;
        my ( $ctx, $args ) = @_;
        my $name = $args->{name}
            or return $ctx->error(
                plugin->translate( '[_1] requires [_2] attribute.', $tag, 'name' ) );

        my $obj = $ctx->stash($model)
            or return $ctx->error('[_1] should be in [_2] context.', $tag, plugin->translate($scope));

        my $ma_period = $args->{period} || 'default';
        my $period = MT->model('ma_period')->load({basename => $ma_period})
            or return $ctx->error('Aggregation period [_1] not found.', $ma_period);

        my $stat = MT->model('ma_object_stat')->load({
            ma_period_id => $period->id,
            object_ds => $model,
            object_id => $obj->id,
        });

        return '' unless $stat;
        return '' unless $stat->can($name);
        my %names = map { $_ => 1 } @{MT->model('ma_object_stat')->column_names};
        return '' unless $names{$name};

        return $stat->$name;
    }
}

sub hdlr_GAEntryStat { ga_object_stat( 'mt:GAEntryStat', 'Entries', 'entry', @_ ) }
sub hdlr_GAPageStat { ga_object_stat( 'mt:GAEntryStat', 'Pages', 'entry', @_ ) }

sub hdlr_GACategoryStat { ga_object_stat( 'mt:GAEntryStat', 'Categories', 'category', @_ ) }
sub hdlr_GAFolderStat { ga_object_stat( 'mt:GAEntryStat', 'Folders', 'category', @_ ) }

1;