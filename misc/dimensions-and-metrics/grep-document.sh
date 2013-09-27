#!/bin/sh

curl -L https://developers.google.com/analytics/devguides/reporting/core/dimsmets \
| perl -e 'print join("\n", sort { $a cmp $b } grep { $_ } map { /#ga:(\w+)/g; $1 } <STDIN>)'
