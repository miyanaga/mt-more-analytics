package MT::MoreAnalytics::Util;

use strict;
use warnings;

use base qw(Exporter);
use MT::Util qw(format_ts epoch2ts ts2epoch);
use MT::MoreAnalytics::Provider;
use MT::MoreAnalytics::Request;

our @EXPORT = qw(
    _stderr
    _dumper
    plugin
    ga_simple_request
    actual_config
    md5_hash
    are_all_days_past
    lookup_fileinfo
    observe_date_range
    treat_config
    date_diff
);

my @INHERITABLE_CONFIG = qw(
    cache_expires_for_future
    cache_expires_for_past
    observe_days
    observe_today
    ka_ignore_keywords
    ka_ignore_regex
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

sub ga_simple_request {
    my ( $app, $param, %opts ) = @_;
    my $eh = $opts{eh} ||= $app;
    my $blog = $opts{blog} ||= $app->can('blog')? $app->blog: undef;

    # Prepare MoreAnalytics provider
    MT::MoreAnalytics::Provider->is_ready( $app, $blog )
        or return $eh->error(plugin->translate('Google Analytics is not set up for this blog or website.'));

    my $ma = MT::MoreAnalytics::Provider->new( 'MoreAnalytics', $blog )
        or return $eh->error(plugin->translate('Cannot create MoreAnalytics provider object.'));

    # Send request
    my $request = MT::MoreAnalytics::Request->new($param);
    defined( my $data = $ma->_request( $app, $request->normalize ) )
        or return $eh->error($app->errstr);

    $data;
}

sub normalize2epoch {
    my ( $blog, $date ) = @_;
    my $ts;

    if ( $date =~ /^\d{8}$/ ) {

        # Assumes TS
        $ts = $date;
    } elsif ( $date =~ m!^(\d+)[\-/](\d+)[\-/](\d+)$! ) {

        # yyyy-mm-dd
        $ts = sprintf('%04d%02d%02d', $1, $2, $3);
    } else {
        return $date;
    }

    ts2epoch( $blog, $ts, $blog? 1: 0 );
}

sub date_diff {
    my ( $blog, $start, $end ) = @_;

    $start = normalize2epoch( $blog, $start );
    $end = normalize2epoch( $blog, $end );

    my $a_day = 60 * 60 * 24;
    my $days = int( ( $end - $start ) / $a_day );

    $days;
}

1;