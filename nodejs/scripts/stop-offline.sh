#!/usr/bin/env bash
MODULE_TYPE="${MODULE_TYPE:-cjs}"

cd test/integration
kill `cat .offline.pid`
rm .offline.pid