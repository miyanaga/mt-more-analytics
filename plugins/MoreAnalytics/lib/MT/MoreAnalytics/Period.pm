package MT::MoreAnalytics::Period;

use strict;
use warnings;

use base qw(MT::Object);
use MT::MoreAnalytics::Util;

__PACKAGE__->install_properties(
    {   column_defs => {
            'id'             => 'integer not null auto_increment',
            'blog_id'        => 'integer not null',
            'name'           => 'string(255) not null',
            'basename'       => 'string(255) not null',
            'description'    => 'text',
            'from_method_id' => 'string(64) not null',
            'from_params'    => 'text',
            'to_method_id'   => 'string(64) not null',
            'to_params'      => 'text',
        },
        indexes => {
            blog_id        => 1,
            basename       => 1,
        },
        datasource  => 'ma_period',
        primary_key => 'id',
    }
);

sub class_label { plugin->translate('Aggregation Period') }
sub class_label_plural { plugin->translate('Aggregation Periods') }

use MT::Util;
use MT::MoreAnalytics::PeriodMethod;

sub _period_method {
    my $self = shift;
    my ( $blog ) = @_;

    my $col = (split(/::/, (caller(1))[3]))[-1];
    my $meth = $col . '_id';
    my $id = $self->$meth;
    if ( !$blog && $self->blog_id ) {
        $blog = MT->model('blog')->load($self->blog_id) || MT->model('website')->load($self->blog_id);
    }

    my $tm = MT::MoreAnalytics::PeriodMethod->create($id);
    $meth = $col . '_params';
    $tm->blog($blog) if $blog;
    $tm->params( $self->$meth );

    $tm;
}

sub from_method { shift->_period_method(@_) }
sub to_method { shift->_period_method(@_) }

sub ga_date_range {
    my $self = shift;
    my ( $blog ) = @_;
    my $from = $self->from_method;
    my $to = $self->to_method;

    (
        'start-date' => $from->format_ga($blog),
        'end-date'   => $to->format_ga($blog),
    );
}

sub _json_column {
    my $self = shift;
    my $col = (split(/::/, (caller(1))[3]))[-1];
    $col =~ s/method_//;
    my ( $val ) = @_;

    if ( defined $val ) {
        $self->$col( ref $val ? MT::Util::to_json($val) : $val );
    } else {
        $val = $self->$col();
        $val = eval { MT::Util::from_json($val) } || {};
        return $val;
    }
}

sub from_method_params { shift->_json_column(@_) }
sub to_method_params { shift->_json_column(@_) }

sub summary {
    my $self = shift;
    plugin->translate(
        'From "[_1]" to "[_2]".',
        $self->from_method->summarize,
        $self->to_method->summarize,
    );
}

sub long_name {
    my $self = shift;
    plugin->translate(
        '[_1] - [_2]',
        $self->name,
        $self->summary
    );
}

sub on_post_save {
    my ( $cb, $self ) = @_;
    treat_config( sub {
        my $config = shift;
        $config->{update_object_stats_soon} = 1;
    });

    1;
}

sub list_props {
    my $props = {
        name => {
            auto => 1,
            order => 100,
            label => 'Name',
            display => 'force',
            html_link => sub {
                my ( $prop, $obj, $app ) = @_;
                my $user = $app->user;
                my $blog_id = $obj->blog_id || 0;

                return ''
                    if !$user->is_superuser
                        && !$user->permissions($obj->blog_id)->can_do('ma_edit_period');

                return $app->uri(
                    mode => 'edit',
                    args => {
                        _type => 'ma_period',
                        id => $obj->id,
                        $obj->blog_id ? ( blog_id => $obj->blog_id ) : (),
                    },
                );
            },
        },
        basename => {
            auto => 1,
            label => 'Basename',
            order => 200,
            display => 'default',
        },
        blog_name => {
            base => '__virtual.blog_name',
            label => 'Website/Blog Name',
            order => 300,
            display => 'default',
        },
        summary => {
            label => 'Summary',
            order => 400,
            display => 'force',
            html => sub {
                my ( $prop, $obj, $app ) = @_;
                $obj->summary;
            },
        },
        description => {
            auto => 1,
            label => 'Description',
            order => 500,
            display => 'default',
        },
    };

    $props;
}

1;