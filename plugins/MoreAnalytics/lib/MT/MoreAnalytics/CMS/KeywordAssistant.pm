package MT::MoreAnalytics::CMS::KeywordAssistant;

use strict;
use MT::MoreAnalytics::Util;
use MT::MoreAnalytics::KeywordAssistant;

sub on_template_param_edit_entry {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $blog = $app->blog or return 1;
    my $author = $app->user or return 1;

    # Widget
    my $partial = plugin->load_tmpl('keyword_assistant.tmpl');
    my $widget = $tmpl->createElement( 'app:widget', {
        id => 'ma-keyword-assistant',
        label => plugin->translate('Keyword Assistant'),
    });
    $widget->innerHTML($partial->text);
    my $anchor = $tmpl->getElementById('entry-publishing-widget');

    $tmpl->insertBefore( $widget, $anchor );

    # Options
    my $pref = MT::MoreAnalytics::KeywordAssistant::context_pref($app);

    # If display keywords as default
    my $prefs = $author->ma_ka_prefs || {};
    $param->{ma_ka_display} = $prefs->{0} && $prefs->{0}->{display};
    $param->{ma_ka_display} = 1 unless defined $param->{ma_ka_display};

    # Metrics and terms
    foreach my $k ( qw/metric term/ ) {
        $pref->{$k} ||= '';
        if ( my $reg = MT->registry('more_analytics', "keyword_assistant_${k}s" ) ) {
            $param->{"ma_ka_${k}s"} = [ map {
                $_->{selected} = 1 if $_->{id} eq $pref->{$k};
                $_;
            } sort {
                ($a->{order} || 1000) <=> ($b->{order} || 1000);
            } map {
                my $m = $reg->{$_};
                $m->{id} = $_;
                $m;
            } keys %$reg ];
        }
    }

    # Max results
    my $canditates = $app->config('MoreAnalyticsKeywordCounts') || '10,20,30,50,100';
    $pref->{max_results} ||= 0;
    $param->{ma_ka_max_results} = [ map {
        {
            value => $_,
            selected => $pref->{max_results} eq $_? 1: 0,
        }
    } split( /\s*,\s*/, $canditates ) ];

    1;
}

sub ma_ka_save {
    my ( $app ) = @_;
    my $q = $app->param;
    my $blog = $app->blog
        or return $app->json_error( plugin->translate('Unknown blog.') );
    my $user = $app->user
        or return $app->json_error( plugin->translate('Unknown user.') );

    my $scope = $q->param('scoep');
    $scope = 0 if $q->param('ma_ka_scope_all');
    $scope = $blog->id unless defined $scope;

    my $prefs = $user->ma_ka_prefs || {};
    my $pref = $prefs->{$scope} ||= {};

    foreach my $name ( qw/display metric term max_results/ ) {
        my $value = $q->param("ma_ka_${name}");
        $pref->{$name} = $value if defined $value;
    }

    $prefs = { 0 => $pref } if $scope == 0;

    $user->ma_ka_prefs($prefs);
    $user->save;

    return $app->json_result(1);
}

sub ma_ka_keywords {
    my ( $app ) = @_;
    my $q = $app->param;
    my $blog = $app->blog
        or return $app->json_error( plugin->translate('Unknown blog.') );

    my %param;

    # Lookup metric handler
    my $metric = MT->registry('more_analytics', 'keyword_assistant_metrics', $q->param('ma_ka_metric') || '')
        or return $app->json_error( plugin->translate('Unknown metric.') );
    my $metric_code = MT->handler_to_coderef($metric->{code});
    $metric_code = \&MT::MoreAnalytics::KeywordAssistant::hdlr_default_metric_handler
        if ref $metric_code ne 'CODE';

    # Resolve term
    my $term_key = $q->param('ma_ka_term') || '';
    if ( $term_key =~ /^period:([0-9]+)$/ ) {

        # In the case of period object
        my $period_id = $1;
        my $period = MT->model('ma_period')->load($period_id)
            or return $app->json_error( plugin->translate('Unknown period as term: id=[_1].', $period_id) );

        # TODO Check if can access to period?

        my %range = $period->ga_date_range;
        $param{start_date} = $range{'start-date'};
        $param{end_date} = $range{'end-date'};
    } else {

        # In the case of resitry handler
        my $term = MT->registry('more_analytics', 'keyword_assistant_terms', $term_key)
            or return $app->json_error( plugin->translate('Unknown term.') );
        my $term_code = MT->handler_to_coderef($term->{code});
        $term_code = \&MT::MoreAnalytics::KeywordAssistant::hdlr_default_term_handler
            if ref $term_code ne 'CODE';

        ( $param{start_date}, $param{end_date} ) = $term_code->( $app, $term );
    }

    # Max keywords
    $param{max_results} = $q->param('ma_ka_max_results') || 10;

    # Dimensions
    $param{dimensions} = 'keyword';

    # Filters
    $param{filters} = MT::MoreAnalytics::KeywordAssistant::actual_ignore_filters($app, $blog);

    defined ( my $keywords = $metric_code->( $app, $metric, \%param ) )
        or return $app->json_error( $app->errstr );

    # Check if the result is an array
    return $app->json_error( plugin->translate('No results.') )
        if ref $keywords ne 'ARRAY' || scalar(@$keywords) < 1;

    # Normalize
    my @results;
    my $loop = scalar @$keywords;

    foreach my $k ( @$keywords ) {
        $k = {} if ref $k ne 'HASH'; 
        $k->{keyword} = '(undef)' unless defined $k->{keyword};
        $k->{value} = '(undef)' unless defined $k->{value};

        push @results, $k;
    }

    return $app->json_result( { keywords => \@results } );
}

1;