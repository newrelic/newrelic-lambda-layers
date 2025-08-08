#!/bin/bash

set -euf -o pipefail

mkdir -p ./nodejs

# Backup the bundled newrelic package if it exists
if [ -d "./nodejs/node_modules/newrelic" ]; then
  mv ./nodejs/node_modules/newrelic ./newrelic-backup
fi

# Remove any existing node_modules in the nodejs directory
rm -rf ./nodejs/node_modules

# Space separated list of external NPM packages
EXTERNAL_PACKAGES=( "import-in-the-middle" )

for EXTERNAL_PACKAGE in "${EXTERNAL_PACKAGES[@]}"
do
  echo "Installing external package $EXTERNAL_PACKAGE ..."

  PACKAGE_VERSION=$(npm query "#$EXTERNAL_PACKAGE" \
    | grep version \
    | head -1 \
    | awk -F: '{ print $2 }' \
    | sed 's/[",]//g')

  echo "Resolved version of the external package $EXTERNAL_PACKAGE: $PACKAGE_VERSION"

  npm install "$EXTERNAL_PACKAGE@$PACKAGE_VERSION" --prefix ./nodejs --production --ignore-scripts

  echo "Installed external package $EXTERNAL_PACKAGE"
done

# Restore the bundled newrelic package if it was backed up
if [ -d "./newrelic-backup" ]; then
  mkdir -p ./nodejs/node_modules
  mv ./newrelic-backup ./nodejs/node_modules/newrelic
fi