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

  # allow Ruby versions other than the target version to bundle
  mv vendor/bundle/ruby/* $base_dir

  for sub_dir in 'bin' 'build_info' 'cache' 'doc' 'extensions' 'plugins'; do
    rm -rf $base_dir/$sub_dir
  done

  # if Gemfile points Bundler to GitHub for the agent, discard extraneous repo
  # content and repackage the vendored gem content as if it were sourced
  # from RubyGems.org
  if [[ -e "$base_dir/bundler" ]]; then
    local phony_version=1.1.38
    mkdir $base_dir/gems
    local nr_dir=$base_dir/gems/newrelic_rpm-$phony_version
    mv $base_dir/bundler/gems/newrelic-ruby-agent* $nr_dir
    rm -rf $base_dir/bundler

    mkdir $base_dir/specifications
    echo -e "Gem::Specification.new {|s| s.name = 'newrelic_rpm'; s.version = '$phony_version'}" > $base_dir/specifications/newrelic_rpm-$phony_version.gemspec

    for sub_dir in '.git' '.github' '.gitignore' '.rubocop.yml' '.rubocop_todo.yml' '.simplecov' '.snyk' '.yardopts' 'Brewfile' 'config' 'CONTRIBUTING.md' 'docker-compose.yml' 'DOCKER.md' 'Dockerfile' 'Gemfile' 'Guardfile' 'infinite_tracing' 'init.rb' 'install.rb' 'lefthook.yml' 'newrelic.yml' 'README.md' 'test' 'THIRD_PARTY_NOTICES.md' 'Thorfile' 'recipes' '.build_ignore'; do
      rm -rf "$nr_dir/$sub_dir"
    done
  fi

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
