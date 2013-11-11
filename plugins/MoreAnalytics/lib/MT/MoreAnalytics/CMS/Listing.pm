package MT::MoreAnalytics::CMS::Listing;

use strict;
use warnings;

use MT::MoreAnalytics::Util;
use MT::MoreAnalytics::Provider;
use MT::MoreAnalytics::PeriodMethod;

sub entry_list_props {
    MT->registry('more_analytics', 'object_stats', 'by_page_path');
}

sub on_template_param_list_common {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $ds = $param->{object_type};
    return if $ds ne 'entry' && $ds ne 'page';

    my $blog_id = $app->param('blog_id') || 0;

    # Insert period pulldown template
    my $insert = $tmpl->createElement('app:setting', {
        id => 'ma_period',
        label => plugin->translate('GA:Aggregation Period'),
        label_class => 'top-label',
    });
    $insert->innerHTML(q{
        <__trans_section component="MoreAnalytics">
        <style>
            #per_page-field { float:left; margin-right:16px; }
            #display_columns-field { clear:both; }
        </style>
        <select name="ma_period_id" id="ma-period">
            <mt:loop name="ma_period_loop">
                <option value="<mt:var name='id'>"<mt:if name="is_selected"> selected="selected"</mt:if>>
                    <mt:var name="name" escape="html">
                    <mt:unless name="stats"><__trans phrase=" - Uncollected"></mt:unless>
                </option>
            </mt:loop>
        </select>
        </__trans_section>
    });
    my $target = $tmpl->getElementById('per_page');
    $tmpl->insertAfter($insert, $target);

    # Current period
    my $list_prefs = $app->user->list_prefs || {};
    my $list_pref = $list_prefs->{$ds}{$blog_id} ||= {};
    my $current_period_id = $list_pref->{ma_period_id};

    # Load periods and pass as param
    my @blog_ids = (0);
    push @blog_ids, $blog_id if $blog_id;
    if ( my $blog = $app->blog ) {
        if ( !$blog->is_blog ) {
            push @blog_ids, map { $_->id } @{ $blog->blogs };
        }
    }

    # Check object stats exists
    my %stats_count;
    my $count_iter = MT->model('ma_object_stat')->count_group_by({
        blog_id => \@blog_ids,
    }, {
        group => ['ma_period_id'],
    });
    if ( $count_iter ) {
        while ( my ( $count, $period_id ) = $count_iter->() ) {
            $stats_count{$period_id} = $count;
        }
    }

    my @periods = map {
        {
            id => $_->id,
            name => $_->long_name,
            stats => $stats_count{$_->id} || 0,
            is_selected => ($_->id == $current_period_id ?1: 0),
        }
    } MT->model('ma_period')->load({blog_id => \@blog_ids});

    $param->{ma_period_loop} = \@periods;

    # Insert javascript
    $param->{jq_js_include} ||= '';
    $param->{jq_js_include} .= q{
        (function($) {
            // Override jQuery Ajax
            var originalAjax = $.ajax;
            $.ajax = function() {
                var args = arguments;
                if ( args[0] && args[0].data
                    && args[0].data['__mode']
                    && args[0].data['__mode'] === 'filtered_list' )
                {
                    console.log('jack');
                    args[0].data['ma_period_id'] = $('#ma-period').val();
                }
                return originalAjax.apply($, args);
            };

            // Bind period to renderList
            $('#ma-period').change(function() {
                renderList('filtered_list', cols, vals, jQuery('#row').val(), 1);
            });
        })(jQuery);
    };

    1;
}

sub on_pre_load_filtered_list_entry {
    my ( $cb, $app, $filter, $load_options, $cols ) = @_;
    my $q = $app->param;
    my $blog_id = $q->param('blog_id') || 0;
    my $ds = $q->param('datasource');

    # Get available period.
    my $ma_period_id = $app->param('ma_period_id') || 0;
    my $period;
    $period = MT->model('ma_period')->load($ma_period_id) if $ma_period_id;

    unless ( $period ) {
        $period = MT->ma_period_id->load({basename => 'default'})
            or return 1;
    }

    # Save list prefs
    my $list_prefs = $app->user->list_prefs || {};
    my $list_pref = $list_prefs->{$ds}{$blog_id} ||= {};
    $list_pref->{ma_period_id} = $period->id;
    # $app->user->save
    # Will save in caller

    # Set to load_options
    $load_options->{ma_period_id} = $period->id;

    1;
}

1;