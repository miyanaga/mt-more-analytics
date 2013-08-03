package MT::MoreAnalytics::Util;

use strict;
use warnings;

use base qw(Exporter);
use MT::Util qw(format_ts epoch2ts);

our @EXPORT = qw(plugin treat_config _stderr _dumper);
our @EXPORT_OK = qw(
    actual_config
    md5_hash
    are_all_days_past
    lookup_fileinfo
    observe_date_range
);

my @INHERITABLE_CONFIG = qw(
    cache_expires_for_future
    cache_expires_for_past
    observe_days
    observe_today
);

our $NOW;

sub now {
    $NOW || time;
}

sub _stderr {
    print STDERR "\n\n", @_, "\n\n";
}

sub _dumper {
    use Data::Dumper;
    print STDERR "\n", Dumper(@_), "\n";
}

sub plugin {

    # The component
    MT->component('MoreAnalytics');
}

sub treat_config {
    my ( $callback, $scope ) = @_;
    $scope ||= 'system';

    my %config;
    plugin->load_config(\%config, $scope);
    my $result = $callback->( \%config );
    plugin->save_config(\%config, $scope);

    $result;
}

sub actual_config {
    my ( $blog ) = @_;
    my $blog_id;
    my $parent_config;

    # Normalize blog and id
    if ( $blog ) {
        $blog = ( MT->model('blog')->load($blog) || MT->model('website')->load($blog) )
            unless ref $blog;

        $blog_id = $blog->id;
        $parent_config = actual_config( $blog->is_blog ? $blog->website : undef );
    } else {
        $blog_id = 0;
    }

    # Load current config
    my $scope = $blog_id ? "blog:$blog_id" : 'system';
    my %config;
    plugin->load_config(\%config, $scope);

    # No inherit if scope is system.
    return \%config if $scope eq 'system';

    # Combine config
    foreach my $c ( @INHERITABLE_CONFIG ) {
        $config{$c} = $parent_config->{$c}
            if $config{"inherit_$c"};
    }

    \%config;
}

sub md5_hash {
    my ( $str ) = @_;
    require Digest::MD5;
    Digest::MD5::md5_hex( $str );
}

sub are_all_days_past {
    my $blog = shift;
    my @days = @_;

    my $today = format_ts( '%Y-%m-%d', epoch2ts( $blog, time ) );
    foreach my $d ( @days ) {
        return 0 if ( $today cmp $d ) <= 0;
    }

    1;
}

sub lookup_fileinfo {
    my ( $blog, $path ) = @_;

    # Fill index.EXT
    my $ext = $blog->file_extension || 'html';
    $ext =~ s/^\.+//;
    if ( $path !~ m!$ext$! ) {
        $path =~ s!/+$!!;
        $path = "$path/index.$ext";
    }

    my @blog_ids = ( $blog->id );
    if ( $blog->can('blogs') ) {
        push @blog_ids, map { $_->id } @{$blog->blogs};
    }

    # Look up fileinfo
    my $fi = MT->model('fileinfo')->load({
        blog_id => \@blog_ids,
        url     => $path,
    });

    $fi;
}

sub observe_date_range {
    my ( $blog ) = @_;

    my $config = actual_config($blog);
    my $aday = 60 * 60 * 24;
    my $end = time;
    $end -= $aday unless $config->{observe_today};
    my $start = $end - $aday * $config->{observe_days};

    (
        start_date  => format_ts( '%Y-%m-%d', epoch2ts( $blog, $start ) ),
        end_date    => format_ts( '%Y-%m-%d', epoch2ts( $blog, $end ) ),
    );
}

1;