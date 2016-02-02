# MT MoreAnalytics Plugin

This plugin provides many features about Google Analytics based on GoogleAnalytics plugin.

## Differences from the original version 0.4.0 at https://github.com/miyanaga/mt-more-analytics

- Fixed an incompatibility with Six Apart's stock Google Analytics plugin, where MoreAnalytics would void all stats for the Dashboard Site Stats widget. See: https://github.com/miyanaga/mt-more-analytics/issues/2

- Fixed a bug where the cache would never return any record and abnormally grow by storing multiple identical values because namespace and serial keys were not stored. See: https://github.com/miyanaga/mt-more-analytics/issues/4

- Fixed a few typos and minor bugs

- Added a configuration parameter to set the maximum number of results in a GA response (useful for big sites, otherwise you might not get stats for more than a few thousands entries)

- Added Debug messages (if DebugMode is not null, calls and requests are logged in the System Log)

## Install

Put the following directories into your Movable Type.

* `plugins/MoreAnalytics` to `$MT_HOME/plugins`
* `mt-static/plugins/MoreAnalytics` to `$MT_HOME/mt-static/plugins/`

The upgrader runs once.

## Google Analytics API Playground

If you already set up Google Analytics API in Movable Type, open playground on Google Analytics menu.

## Template Tags

Google Analytics API is assigned to each blog or website. So template tags around GA are need blog or website context.

### mt:GAIfReady

Checks if Google Analytics API is ready for blog in current context.

    <mt:MultiBlog ids="1,2,3">
    <mt:GAIfReady>
      <!-- READY TO USE OTHER TAGS -->
    <mt:Else>
      <!-- NOT READY -->
    </mt:GAIfReady>
    <mt:MultiBlog>

### mt:GAProfiles and mt:GAProfile

Enumrates profiles.

    <mt:GAProfiles>
      <$mt:GAProfile name="name">: <$mt:GAProfile name="id"$>
    </mt:GAProfiles>

`mt:GAProfile` looks up attribute of each profile.

You can dump profiles like this:

    <mt:GAProfiles _dump="table"></mt:GAProfiles>

`_dump` modifires can take `table`, `csv` or `tsv`.

### mt:GAReport and mt:GAValue

Queries Google Analytics Core Reporting API.

You can also use `mt:GAReportHeader` and `mt:GAReportFooter` to write each section.

    <mt:GAReport start_date="2013-08-01" end_date="2013-08-31" metrics="pageviews" dimensions="pagePath">
      <$mt:GAValue name="pagePath"$>: <$mt:GAValue name="pageviews">
    </mt:GAReport>

`mt:GAReport` takes the following modifies. These are based on Google Analytics API, but `ga:` prefix is optional.

* start_date *(Required)*
* end_date *(Required)*
* ids
* metrics *(Required)*
* dimensions
* fields
* filters
* segment
* start_index *(Default: 1)*
* max_results *(Default: 10000)*

And you can also set a basename of `Aggregation Period` described as bellow.

* period

`mt:GAValue` can take field name in metrics and dimensions.

Dump is also available for `mt:GAReport`.

    <mt:GAReport … _dump="table"></mt:GAReport>

### mt:GAReportBreak

If you want to break `mt:GAReport` loop, put `mt:GAReportBreak` function tag.

    <mt:If tag="Foo" eq="Bar">
      <$mt:GAReportBreak$>
    </mt:If>

Take note `mt:GAReportBreak` is different from programming statement. It's cancel all output the turn reaches `mt:GAReportBreak`.

### mt:GAGuessObject and mt:GAIfObjectType

`mt:GAGuessObject` tries to link Google Analytics report with Movable Type object via page path.

Database of Movable Type has `mt_fileinfo` table to mapping paths and objects. `mt:GAGuessObject` uses the records.

    <!-- Report pageviews about entries and categories -->
    <mt:GAReport period="default" metrics="pageviews" dimensions="pagePath">

      <!-- Guess object from pagePath -->
      <mt:GAGuessObject name="pagePath">

        <!-- If the object was entry or page -->
        <mt:GAIfObjectType is="entry">
          <mt:EntryTitle>: <mt:GAValue name="pageviews">
        </mt:GAIfObjectType>

        <!-- If the object was category of folder -->
        <mt:GAIfObjectType is="category">
          <mt:CategoryLabel>: <mt:GAValue name="pageviews">
        </mt:GAIfObjectType>

      </mt:GAGussObject>

    </mt:GAReport>

It's interesting set `landingPagePath` or `exitPagePath` to `name` of `mt:GAGuessObject` to guess about landing or exit page.

You can filter object type in `mt:GAGuessObject` like this:

    <!-- Guess only for entries -->
    <mt:GAGuessObject name="exitPagePath" only="entry">
      <mt:EntryTitle>
    </mt:GAGuessObject>

### mt:Entries and mt:Pages

**This section related with `Object Stats` feature.**

These are typical template tags of Movable Type. MoreAnalytics plugin expand these tags to enable sort with Google Analytics metrics.

    <!-- Entries ordered by pageviews -->
    <mt:Entries sort_by="ga:pageviews" sort_order="descend" ga:period="your_period">
      <mt:EntryTitle>: <mt:GAEntryStat name="pageviews">
    </mt:Entries>

### mt:GAEntryStat and mt:GAPageStat

**This section related with `Object Stats` feature.**

You can refer metrics about entries and pages in each context.

    <mt:EntryTitle>: <mt:GAEntryStat name="exit_rate" sprintf="%0.2f%%">

## Object Stats and Aggregation Period

Object stats are pre-fetch Google Analytics metrics that used for sorting in `mt:Entries` and listing screen.

* Pgeviews
* Unique Visitors
* Entrance Rate
* Exit Rate
* Bounce Rate
* Average Page Download Time
* Average Page Load Time
* Average Time On Page

After you enable object stats features at plugins management screen, execute `run-periodic-tasks`.

You can display, filter and sort metrics in listing screen of entries.
