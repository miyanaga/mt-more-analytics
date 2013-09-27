#!/bin/sh

cat ../../mt-static/plugins/MoreAnalytics/metrics-and-dimensions/en_US.coffee \
| perl -e 'print join("\n", sort { $a cmp $b } grep { $_ } map { m|\s+(.+?):\{l:|; $1 } <STDIN>)'