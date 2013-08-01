package MT::MoreAnalytics::L10N::ja;

use strict;
use utf8;
use base 'MT::MoreAnalytics::L10N::en_us';
use vars qw( %Lexicon );

%Lexicon = (

    # config.yaml
    'MoreAnalytics' => 'MoreAnalytics',
    'Edit Custom KPI Widget' => 'カスタムKPIウィジェットの編集',
    'Manage Aggregation Period' => '集計期間の管理',
    'Google Analytics API Playground' => 'Google Analytics APIプレイグラウンド',
    'Yesterday(The last day)' => '昨日(集計前日)',
    'Today(The day)' => '今日(集計当日)',
    'Days before' => '○日前',
    'Fixed date' => '特定の日付',
    'New Period' => '集計期間の作成',
    'Google Analytics' => 'Google Analytics',
    'API Playground' => 'APIプレイグラウンド',
    'Custom Widget' => 'カスタムウィジェット',
    'MoreAnalytics Updates Object Stats' => 'MoreAnalytics オブジェクト統計更新',
    'MoreAnalytics Cleanup Cache' => 'MoreAnalytics キャッシュ整理',
    'Aggregation Period' => '集計期間',
    'Aggregation Periods' => '集計期間',
    'period' => '集計期間',
    'periods' => '集計期間',


    # tmpl/playground.tmpl
    'Google Analytics API Playground' => 'Google Analytics APIプレイグラウンド',
    'Profile' => 'プロファイル',
    'Profiles' => 'プロファイル',
    'Metric' => '指標',
    'Metrics' => '指標',
    'Dimension' => 'ディメンジョン',
    'Dimensions' => 'ディメンジョン',
    'Fields' => 'フィルター',
    'Filters' => 'フィルター',
    'Options' => 'オプション',
    'Sort' => '並べ替え',
    'Set as below' => '以下で指定',
    'Start Date' => '開始日',
    'End Date' => '終了日',
    'Start Index' => '開始インデックス',
    'Max Results' => '最大件数',
    'Result Table' => '結果表',
    'Template Snipet' => 'テンプレート記述例',
    'Run Query' => 'クエリ実行',
    'Example Template' => 'テンプレート記述例',
    '(Asc)' => '(昇順)',
    '(Desc)' => '(降順)',
    '\\(Asc\\)' => '\\(昇順\\)',
    '\\(Desc\\)' => '\\(降順\\)',

    # tmpl/config/system.tmpl
    'Update Object Stats' => 'オブジェクト統計の更新',
    'Update Frequency' => '更新の頻度',
    'Minutes' => '分',
    'Cleanup Cache' => 'キャッシュの整理',
    'Cleanup Frequency' => '整理の頻度',
    'Limit Size' => '制限容量',
    'MB' => 'MB',
    'Drop All Caches' => 'キャッシュをすべて削除',
    'Processing...' => '処理中です...',
    'Are you sure to drop all caches?' => 'すべてのキャッシュを削除してもよろしいですか？',
    'Error: Invalid result.' => 'エラー: 不正なレスポンスです。',
    'Error:' => 'エラー: ',

    # tmpl/edit_ma_period.tmpl
    'Create Aggregation Period' => '集計期間の作成',
    'Edit Aggregation Period' => '集計期間の編集',
    'Save this period (s)' => 'この集計期間を保存する (s)',
    'Delete this period (x)' => 'この集計期間を削除する (x)',
    'Aggregate from' => '集計開始日',
    'Aggregate to' => '集計終了日',
    'days before' => '日前',
    'Basename' => 'ベースネーム',
    'Your changes have been saved.' => '変更が保存されました。',
    'Name' => '名称',
    'Description' => '説明',
    "Warning: Changing this period's basename may require changes to existing templates."
        => '警告: この集計期間のベースネームを変更すると既存のテンプレートに変更が必要になるかもしれません。',
    'Save' => '保存',
    'Delete' => '削除',

    '_PREFIX_FROM' => ' ',
    '_SUFFIX_FROM' => ' から',
    '_PREFIX_TO' => ' ',
    '_SUFFIX_TO' => ' まで',

    # lib/MT/MoreAnalytics/Tags.pm
    '[_1] requires blog context.' => '[_1] はブログコンテキストが必要です。',
    'Google Analytics is not ready for blog or website ID:[_1]'
        => 'ブログまたはウェブサイト(ID:[_1])ではGoogle Analyticsが準備されていません。',
    'Period [_1] is not found.' => '集計期間 [_1] が見つかりません。',
    'items in results is not an array.' => 'レスポンス中のitemsが配列ではありません。',
    '[_1] is not used in mt:GAReport context.' => '[_1] が mt:GAReport の外部で使用されています。',
    '[_1] requires [_2] attribute.' => '[_1] には [_2] モディファイアが必要です。',
    '[_1] can not detect path info.' => '[_1] でパス情報が取得できません。',
    '[_1] is not found.' => '[_1] が見つかりません。',
    'Aggregation period [_1] not found.' => '集計期間 [_1] が見つかりません。',

    # tmpl/playground/profiles.tmpl
    'Default' => 'デフォルト',

    # lib/MT/MoreAnalytics/Tasks.pm
    'MoreAnalytics updated object stats. [_1] blog(s), [_2] period(s), [_3] query(ies), [_4] stat(s).'
        => 'MoreAnalyticsがオブジェクト統計を更新しました: [_1] ブログ [_2] 集計期間 [_3] APIリクエスト [_4] 統計が更新されました。',
    'MoreAnalytics cleanup cache. [_1] cache(s), [_2] bytes cleanup, limit to [_3] bytes, currently total [_4] bytes.'
        => 'MoreAnalyticsがキャッシュを整理しました: [_1] キャッシュ [_2] バイトを整理 制限は [_3] バイト 現在 [_4] バイトのキャッシュがあります。',
    'MoreAnalytics checked cache size, but current total [_1] bytes is within the limit of [_2] bytes.'
        => 'MoreAnalytcsがキャッシュサイズを確認しましたが、現在の総容量 [_1] バイトは制限の [_2] バイトに達していませんでした。',

    # lib/MT/MoreAnalytics/Cache.pm
    'MoreAnalytics Cache' => 'MoreAnalyticsキャッシュ',
    'MoreAnalytics Caches' => 'MoreAnalyticsキャッシュ',

    # lib/MT/MoreAnalytics/Period.pm
    'Aggregation Periods' => '集計期間',
    'Name is required.' => '名称は必須です。',
    'Basename is required.' => 'ベースネームは必須です。',
    'Basename should be consisted with alphabets, numbers or underscore.'
        => 'ベースネームは半角英数字またはアンダースコア(_)で構成してください。',
    '"Aggregate from" has no method.' => '集計開始日の計算方法が不明です。',
    '"Aggregate to" has no method.' => '集計終了日の計算方法が不明です。',
    '"Aggregate from" has probrem: [_1]' => '集計開始日の指定に問題があります: [_1]',
    '"Aggregate to" has probrem: [_1]' => '集計終了日の指定に問題があります: [_1]',
    'Summary' => '概要',
    '[_1] - [_2]' => '[_1]([_2])',
    'From "[_1]" to "[_2]".' => '"[_1]"から"[_2]"まで',


    # lib/MT/MoreAnalytics/App/CMS.pm
    'Google Analytics is not ready for blog or website ID:[_1]'
        => 'このブログまたはウェブサイト(ID:[_1])ではGoogle Analyticsの準備ができていません。',
    'Droped all caches.' => 'すべてのキャッシュを削除しました。',
    'GA:Aggregation Period' => 'GA:集計期間',
    'GA:Pageviews' => 'GA:ページビュー数',
    'GA:Unique PV' => 'GA:ユニークPV数',
    'GA:Entrance Rate' => 'GA:開始率',
    'GA:Exit Rate' => 'GA:離脱率',
    'GA:Bounce Rate' => 'GA:直帰率',
    'GA:Avg. DL Time' => 'GA:平均DL時間',
    'GA:Avg. Load Time' => 'GA:平均読込時間',
    'GA:Avg. View Time' => 'GA:平均閲覧時間', 
    '%0.2f Sec.' => '%0.2f秒',
    '_DATE_FORMAT' => '%Y年%m月%d日',

    # lib/MT/MoreAnalytics/CMS/Widget.pm
    'Permission denigied.' => 'この操作を行う権限はありません。',
    'Unknown action' => '不明なアクションです。',

    # lib/MT/MoreAnalytics/ObjectStat.pm
    'Object Statistics' => 'オブジェクト統計',

    # lib/MT/MoreAnalytics/CMS/Period.pm
    'Basename is reuquired.' => 'ベースネームは必須です。',
    'Aggregation period basename of [_1] is already exists. Basename should be unique.'
        => '[_1]をベースネームに持つ集計期間はすでに存在します。ベースネームは一意のテキストを指定してください。',

    # tmpl/widget/custom_main_widget.tmpl
    'Custom Main Widget' => 'カスタムメインウィジェット',
    'Preview this template (s)' => 'テンプレートをプレビューする (s)',
    'Preview' => 'プレビュー',
    'Save' => '保存',
    'Close editing (s)' => '編集を終了する (s)',
    'Close' => '閉じる',
    'Cancel' => 'キャンセル',
    "Click 'Edit' link to start editing template to show in this widget."
        => "'編集'リンクをクリックしてこのウィジェットに表示するテンプレート編集します。",
    'Edit' => '編集',
    'Your template for widget has been saved.' => 'ウィジェットテンプレートを保存しました。',
    'Parsing JSON has an error.' => 'JSONの解析エラーが発生しました。コンソールで確認ください。',

    # tmpl/widget/custom_sidebar_widget.tmpl
    'Custom Sidebar' => 'カスタムサイドバー',

    # lib/MT/MoreAnalytics/CMS/Playground.pm
    'Blog required.' => 'ブログが必要です。',
    'Request needs a metric at least.' => 'リクエストには指標が少なくとも一つは必要です。',
    'Permission denied.' => 'この操作を行う権限がありません。',
    'Unknown period [_1]' => '不明な集計期間です: [_1]',
    'Google Analytics is not set up for this blog or website.'
        => 'このブログまたはウェブサイトにはGoogle Analyticsがセットアップされていません。',
    'Cannot create MoreAnalytics provider object.'
        => 'MoreAnalyticsプロバイダオブジェクトを作成できません。',

    # lib/MT/MoreAnalytics/PeriodMethod/Common.pm
    'Fixed date' => '特定の日付',
    'Days before' => '○日前',
    'Today(The day)' => '今日(集計当日)',
    'Yesterday(The last day)' => '昨日(集計前日)',
    '[_1] days before' => '[_1]日前',
    'Enter an integer zero or over.' => '0以上の整数を指定してください。',
    'Invalid date format.' => '正しい日付の形式ではありません。',
    'Invalid year.' => '年の指定が正しくありません。',
    'Invalid month.' => '月の指定が正しくありません。',
    'Invalid day.' => '日の指定が正しくありません。',
    'Invalid date.' => '存在しない日付です。',

);

1;

