package MT::MoreAnalytics::ObjectStat::Common;

use strict;
use warnings;

use MT::MoreAnalytics::Util;

sub list_props {
    my $props = {
        integer => {
            display     => 'default',
            base        => '__virtual.integer',
            value_format => '%d',
            default_value => 0,
            bulk_html   => sub {
                my $prop = shift;
                my ( $objs, $app, $load_options ) = @_;
                my @ids = map { $_->id } @$objs;
                my ( %values, @rows );
                my $col = $prop->id;

                my @only = ('object_id', $col);
                if ( my $iter = MT->model('ma_object_stat')->load_iter({
                    ma_period_id => ($load_options->{ma_period_id} || 0),
                    object_ds => 'entry',
                    object_id => \@ids
                }, {
                    fetchonly => \@only
                }) ) {
                    while ( my $os = $iter->() ) {
                        $values{$os->object_id} = $os->$col;
                    }
                }

                my $format = plugin->translate($prop->value_format);

                foreach my $obj ( @$objs ) {
                    my $value = 0;
                    push @rows, sprintf(
                        $format,
                        $values{$obj->id} || $prop->default_value
                    );
                }
                @rows;
            },
            terms => sub {
                my $prop = shift;
                my ( $args, $db_terms, $db_args, $load_options ) = @_;
                my $super_terms = $prop->super(@_);
                push @{ $db_args->{joins} ||= [] }, MT->model('ma_object_stat')->join_on(
                    undef,
                    {
                        ma_period_id => ($load_options->{ma_period_id} || 0),
                        object_ds => 'entry',
                        object_id => \'= entry_id',
                        %$super_terms,
                    },
                    {
                        unique => 1,
                    }
                );
            },
            bulk_sort => sub {
                my $prop = shift;
                my ($objs, $load_options) = @_;
                my @ids = map { $_->id } @$objs;
                my $col = $prop->col;
                my @only = ('object_id', $col);
                my @oss = MT->model('ma_object_stat')->load({
                    ma_period_id => ($load_options->{ma_period_id} || 0),
                    object_ds => 'entry',
                    object_id => \@ids
                }, {
                    fetchonly => \@only
                });
                my %values = map { $_->object_id => $_->$col } @oss;

                sort { ($values{$a->id} || 0) <=> ($values{$b->id} || 0) } @$objs;
            },
            sort => 0,
        },
        percentage => {
            base => '__stat_common.integer',
            value_format => '%0.2f%%',
        },
        second => {
            base => '__stat_common.integer',
            value_format => '%0.2f Sec.',
        },
    }
}

1;