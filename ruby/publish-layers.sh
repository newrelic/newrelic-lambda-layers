#!/usr/bin/env bash

set -Eeuo pipefail

BUILD_DIR=vendor
DIST_DIR=dist
BUNDLE_DIR=.bundle
WRAPPER_FILE=newrelic_lambda_wrapper.rb

source ../libBuild.sh

function usage {
  echo "./publish-layers.sh [ruby3.2]"
}

function build_and_publish_ruby {
  local ruby_version=$1
  build_and_publish_ruby_for_arch $ruby_version 'x86_64'
  build_and_publish_ruby_for_arch $ruby_version 'arm64'
}

function build_and_publish_ruby_for_arch {
  local ruby_version=$1
  local arch=$2

  echo "Building New Relic layer for ruby v$ruby_version ($arch)"

  local dist_file="$DIST_DIR/ruby${ruby_version//./}.$arch.zip"

  rm -rf $BUILD_DIR $BUNDLE_DIR $dist_file
  mkdir -p $DIST_DIR

  bundle config set --local without development
  bundle config set --local path $BUILD_DIR/bundle
  bundle install

  local base_dir="vendor/bundle/ruby/${ruby_version}.0"
  mv vendor/bundle/ruby/* $base_dir

  for subdir in 'bin' 'build_info' 'cache' 'doc' 'extensions' 'plugins'; do
    rm -rf $base_dir/$sub_dir
  done

  download_extension $arch
  zip -rq $dist_file $WRAPPER_FILE $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
  rm -rf $BUILD_DIR $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
  echo "Build complete: ${dist_file}"

  for region in "${REGIONS_X86[@]}"; do
    echo "Publishing $dist_file for region=$region, ruby=$ruby_version, arch=$arch"
    publish_layer $dist_file $region "ruby${ruby_version}" $arch
  done
  echo 'Publishing complete'
}

set +u # permit $1 to be unbound so that '*' matches it when no args are present
case "$1" in
  "ruby3.2")
    build_and_publish_ruby '3.2'
    ;;
  *)
    usage
    ;;
esac
