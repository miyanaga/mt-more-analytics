package MT::MoreAnalytics::L10N::ja;

use strict;
use utf8;
use base 'MT::MoreAnalytics::L10N::en_us';
use vars qw( %Lexicon );

%Lexicon = (
	'Profile' => 'プロファイル',
	'Profiles' => 'プロファイル',
	'Metric' => '指標',
	'Metrics' => '指標',
	'Dimension' => 'ディメンジョン',
	'Dimensions' => 'ディメンジョン',

	'API Playground' => 'APIプレイグラウンド',
	'Google Analytics API Playground'
		=> 'Google Analytics APIプレイグラウンド',
    'New Period' => '集計期間の作成',

    '%0.2f Sec.' => '%0.2f秒',
    '_DATE_FORMAT' => '%Y年%m月%d日',

    'Aggregation Period' => '集計期間',
    'Aggregation Periods' => '集計期間',
    'period' => '集計期間',
    'periods' => '集計期間',

    'Today(The day)' => '今日(集計当日)',
    'Yesterday(The last day)' => '昨日(集計前日)',
    'Fixed date' => '特定の日付',
    'Days before' => '○日前',

    'Invalid date format.' => '正しい日付の形式ではありません。',
    'Invalid year.' => '年の指定が正しくありません。',
    'Invalid month.' => '月の指定が正しくありません。',
    'Invalid day.' => '日の指定が正しくありません。',
    'Invalid date.' => '存在しない日付です。',

    '[_1] days before' => '[_1]日前',
    'Enter an integer zero or over.' => '0以上の整数を指定してください。',

    'Summary' => '概要',
    '[_1] - [_2]' => '[_1]([_2])',
    'From "[_1]" to "[_2]".' => '"[_1]"から"[_2]"まで',

    # Edit
    'Create Aggregation Period' => '集計期間の作成',
    'Edit Aggregation Period' => '集計期間の編集',
    'Save this period (s)' => 'この集計期間を保存する (s)',
    'Delete this period (x)' => 'この集計期間を削除する (x)',
    'Aggregate from' => '集計開始日',
    'Aggregate to' => '集計終了日',
    'days before' => '日前',
    'Basename' => 'ベースネーム',
    'Name is required.' => '名称は必須です。',
    'Basename is required.' => 'ベースネームは必須です。',
    'Basename should be consisted with alphabets, numbers or underscore.'
        => 'ベースネームは半角英数字またはアンダースコア(_)で構成してください。',
    '"Aggregate from" has no method.' => '集計開始日の計算方法が不明です。',
    '"Aggregate to" has no method.' => '集計終了日の計算方法が不明です。',
    '"Aggregate from" has probrem: [_1]' => '集計開始日の指定に問題があります: [_1]',
    '"Aggregate to" has probrem: [_1]' => '集計終了日の指定に問題があります: [_1]',

    '_PREFIX_FROM' => ' ',
    '_SUFFIX_FROM' => ' から',
    '_PREFIX_TO' => ' ',
    '_SUFFIX_TO' => ' まで',

    'GA:Aggregation Period' => 'GA:集計期間',
    'GA:Pageviews' => 'GA:ページビュー数',
    'GA:Unique PV' => 'GA:ユニークPV数',
    'GA:Entrance Rate' => 'GA:開始率',
    'GA:Exit Rate' => 'GA:離脱率',
    'GA:Bounce Rate' => 'GA:直帰率',
    'GA:Avg. DL Time' => 'GA:平均DL時間',
    'GA:Avg. Load Time' => 'GA:平均読込時間',
    'GA:Avg. View Time' => 'GA:平均閲覧時間', 
);

1;

