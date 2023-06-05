#!/usr/bin/env bash

TMPFILE=/var/tmp/offline$$.log
MODULE_TYPE="${MODULE_TYPE:-cjs}"

if [ -f test/integration/.offline.pid ]; then
  echo Found file .offline.pid. Not starting.
  exit 1
fi

cd test/integration
npx serverless offline &> $TMPFILE &
PID=$!
echo $PID > .offline.pid

while ! grep "Offline \[http for lambda\] listening" $TMPFILE
do sleep 1; done

rm $TMPFILE