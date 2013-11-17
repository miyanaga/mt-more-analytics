package MT::MoreAnalytics::ObjectStat;
use strict;

use base qw(MT::Object);
use MT::MoreAnalytics::Util;

our ( %COLS2METS, %METS2COLS );

__PACKAGE__->install_properties(
    {   column_defs => {
            'id'             => 'integer not null auto_increment',
            'blog_id'        => 'integer not null',
            'object_ds'      => 'string(64) not null',
            'object_id'      => 'integer not null',
            'ma_period_id'   => 'integer not null',
            'age'            => 'integer',
            'pageviews'      => 'integer',
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

sub has_column_def {
    my $pkg = shift;
    $pkg = ref $pkg if ref $pkg;

    my $name = shift;
    my %names = map { $_ => 1 } @{$pkg->column_names};

    $names{$name}? 1: 0;
}

sub cleanup {
    my $class = shift;
    # TODO Imprement 
}

sub _hash_stats {
    my ( $type, $hasher ) = @_;
    my $defines = MT->registry('more_analytics', 'object_stats', $type);
    my %hash = map {
        my $define = $defines->{$_};
        my $col = $define->{col} || $_;
        my $metrics = $define->{metrics} || $_;
        $hasher->($col, $metrics);
    } keys %$defines;

    \%hash;
}

sub metrics_to_cols {
    my $pkg = shift;
    my ( $type ) = @_;
    $type ||= 'by_page_path';

    return $METS2COLS{$type} if $METS2COLS{$type};
    $METS2COLS{$type} = _hash_stats( $type, sub { $_[1] => $_[0] });
}

sub cols_to_metrics {
    my $pkg = shift;
    my ( $type ) = @_;
    $type ||= 'by_page_path';

    return $COLS2METS{$type} if $COLS2METS{$type};
    $COLS2METS{$type} = _hash_stats( $type, sub { $_[0] => $_[1] });
}

1;
