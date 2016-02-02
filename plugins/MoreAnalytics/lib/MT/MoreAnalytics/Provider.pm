package MT::MoreAnalytics::Provider;

use strict;
use warnings;

use base qw(GoogleAnalytics::Provider);

use HTTP::Request::Common;
use GoogleAnalytics::OAuth2 qw(effective_token get_profiles);
use MT::Util;
use MT::MoreAnalytics::Util;

*new_ua = *GoogleAnalytics::Provider::new_ua;
*translate = *GoogleAnalytics::Provider::translate;

sub _name {
    my $n = shift;
    $n =~ s/^ga://;
    $n eq 'Pageviews' ? lc($n) : $n;
}

sub profiles {
    my $self = shift;
    my ( $app ) = @_;
    $app ||= MT->instance;
    my $ua = new_ua();

    my $plugindata = GoogleAnalytics::current_plugindata( $app, $self->blog );
    my $token = effective_token( $app, $plugindata );

    my $profiles = get_profiles( $app, $ua, $token->{data} ? $token : { data => $token } );

    $profiles;
}

sub _request {
    my $self = shift;
    my ( $app, $params, $retry_count ) = @_;

# DEBUG
	my %debug = ();
	if ( $MT::DebugMode ) {
		%debug = (
			message =>
				'MT::MoreAnalytics::Provider _request called by ' . ( caller(2) )[3],
			metadata => 'Parent: ' . ( caller(1) )[3] . "\n" .
						'Params: ' . Data::Dumper->Dumper($params),
		);
	}

    require GoogleAnalytics::OAuth2;
    my $plugindata = GoogleAnalytics::current_plugindata( $app, $self->blog );
    my $token = effective_token( $app, $plugindata )
        or return;

    my $config = $plugindata->data;

    # Different from original
    $params->{ids} ||= 'ga:' . $config->{profile_id};

    # Normalize date format
    foreach my $key ( qw/start end/ ) {
        my $k = "$key-date";
        my $v = $params->{$k} or next;
        if ( $v =~ m/^\d{4}-\d{2}-\d{2}$/ ) {

            # Right format
        } elsif ( $v =~ m/^(\d{4})(\d{2})(\d{2})(\d{6})$/ ) {

            # MT Timestamp to date
            $params->{$k} = join('-', $1, $2, $3);
        } elsif ( $v =~ m/^\d+$/ ) {

            # Maybe epoch time
            $params->{$k} = MT::Util::epoch2ts(undef, $v, 1);
        }
    }

    my $uri = URI->new('https://www.googleapis.com/analytics/v3/data/ga');
    $uri->query_form($params);

    # Make cacheable
    my $serial = MT::MoreAnalytics::Util::md5_hash( $uri->as_string );
    my $json;

    my $token_type = $token->{data}->{token_type} || '';
    my $access_token = $token->{data}->{access_token} || '';
    if ( my $cache = MT->model('ma_cache')->lookup( ns => 'ga_report', serial => $serial ) ) {
        $json = $cache->text;

# DEBUG
		if ( $MT::DebugMode ) {
			$debug{metadata} .= "\n" . 'Results retrieved from cache key: ' . $serial;
		}

    } else {

# DEBUG
		if ( $MT::DebugMode ) {
			$debug{metadata} .= "\n" . 'Requesting URI: ' . $uri->as_string;
		}

        my $ua  = new_ua();
        my $res = $ua->request(
            GET($uri,
                Authorization => "$token->{data}->{token_type} $token->{data}->{access_token}"
            )
        );

        if ($res->code == 401 && ! $retry_count) {
            return $self->_request(@_ ,1);
        }

        return $app->error(
            translate(
                'An error occurred when retrieving statistics data: [_1]: [_2]',
                GoogleAnalytics::extract_response_error($res)
            ),
            500
        ) unless $res->is_success;

        $json = Encode::decode( 'utf-8', $res->content );

        my $ma_config = MT::MoreAnalytics::Util::actual_config($self->blog);
        my $expires = MT::MoreAnalytics::Util::are_all_days_past( $self->blog,
                $params->{'start-date'}, $params->{'end-date'}
            ) ? $ma_config->{cache_expires_for_past}
                : $ma_config->{cache_expires_for_future};

        MT->model('ma_cache')->store(
            ns      => 'ga_report',
            serial  => $serial,
            text    => $json,
        );

# DEBUG
		if ( $MT::DebugMode ) {
			$debug{metadata} .= "\n" . 'Caching request under serial key: ' . $serial;
		}
    }

    my $data
        = MT::Util::from_json( $json );

    my @headers = map { _name( $_->{name} ) } @{ $data->{columnHeaders} };
    my $date_index = undef;
    for ( my $i = 0; $i <= $#headers; $i++ ) {
        if ( $headers[$i] eq 'date' ) {
            $date_index = $i;
            last;
        }
    }

# DEBUG
	if ( $MT::DebugMode ) {
		$debug{metadata} .= "\n" . 'Total results: ' . $data->{totalResults};
		$app->log({
			message => $debug{message},
			metadata => $debug{metadata},
			class    => 'system',
			category => 'plugin',
			level    => MT::Log::INFO()
		});
	}

    +{  totalResults => $data->{totalResults},
        totals       => {
            map { _name($_) => $data->{totalsForAllResults}{$_} }
                keys %{ $data->{totalsForAllResults} }
        },
        items => [
            map {
                my @row = @$_;
                if ( defined($date_index) ) {
                    $row[$date_index] =~ s/(\d{4})(\d{2})/$1-$2-/;
                }
                +{ map { $headers[$_] => $row[$_], } ( 0 .. $#headers ) }
            } @{ $data->{rows} }
        ],
        headers => \@headers,
        ( $MT::DebugMode ? ( debug => { query => $params, rawData => $data }, ) : () )
    };
}

1;