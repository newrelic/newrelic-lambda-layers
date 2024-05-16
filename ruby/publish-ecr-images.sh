#!/usr/bin/env bash

set -Eeuo pipefail

# This script creates an AWS Lambda Ruby layer .zip file for each supported
# architecture. The Ruby content does not change between architectures, but
# the included Go based AWS Lambda extension does. The .zip files are written
# to dist/ and from there they are uploaded to AWS via ../libBuild.sh
# functionality.
#
# Each .zip file is structured like so for Ruby:
#   ruby/gems/<RUBY MAJOR><RUBY MINOR>.0  -- AWS sets this as GEM_PATH. It's where the agent lives
#   ruby/lib                              -- AWS sets this as RUBYLIB. It's where the wrapper script lives
#   extensions/                           -- Where the NR Go based extension content lives
#   preview-extensions-*                  -- Extensions preview file

RUBY_DIR=ruby
DIST_DIR=dist
WRAPPER_FILE=newrelic_lambda_wrapper.rb
# Set this to a path to a clone of newrelic-lambda-extension to build
# an extension from scratch instead of downloading one. Set the path to ''
# to simply download a prebuilt one.
# EXTENSION_CLONE_PATH='../../newrelic-lambda-extension_fallwith'
EXTENSION_CLONE_PATH=''

source ../libBuild.sh

function usage {
  echo "./publish-ecr-images.sh [ruby3.2|ruby3.3]"
}

RUBY33_DIST_ARM64=$DIST_DIR/ruby33.arm64.zip
RUBY32_DIST_ARM64=$DIST_DIR/ruby32.arm64.zip

RUBY33_DIST_X86_64=$DIST_DIR/ruby33.x86_64.zip
RUBY32_DIST_X86_64=$DIST_DIR/ruby32.x86_64.zip


function build_and_publish_ruby_for_arch {
  local dist_file=$1
  local ruby_version=$2
  local arch=$3
  echo "Building New Relic layer for ruby v$ruby_version ($arch)"


  rm -rf $RUBY_DIR $dist_file
  mkdir -p $DIST_DIR

  bundle config set --local without development
  bundle config set --local path . # Bundler will create a 'ruby' dir beneath here
  bundle install

  local base_dir="$RUBY_DIR/gems/$ruby_version.0"

  # Bundler will have created ./ruby/<RUBY VERSION USED TO BUNDLE>/gems
  # AWS wants ./ruby/gems/<RUBY VERSION FOR LAMBDA RUNTIME>
  # So we need to flip the directory structure around and also use the right
  # Ruby version. For building, we insist on the same major Ruby version but
  # are relaxed on the minor version.
  mkdir $RUBY_DIR/gems

  # allow Ruby versions other than the target version to bundle
  # so if Bundler used Ruby v3.3 and the target is v3.2, the '3.3.0' dir
  # gets renamed to '3.2.0'
  mv $RUBY_DIR/${ruby_version:0:1}* $base_dir

  for sub_dir in 'bin' 'build_info' 'cache' 'doc' 'extensions' 'plugins'; do
    rm -rf $base_dir/$sub_dir
  done

  mkdir -p $RUBY_DIR/lib
  cp $WRAPPER_FILE $RUBY_DIR/lib

  # if Gemfile points Bundler to GitHub for the agent, discard extraneous repo
  # content and repackage the vendored gem content as if it were sourced
  # from RubyGems.org
  if [[ -e "$base_dir/bundler" ]]; then
    local phony_version=$(date +'%s')
    mkdir -p $base_dir/gems # dir will exist if non-agent, non-dev gems are in Gemfile
    local nr_dir=$base_dir/gems/newrelic_rpm-$phony_version
    mv $base_dir/bundler/gems/newrelic-ruby-agent* $nr_dir
    rm -rf $base_dir/bundler
    mkdir $base_dir/specifications
    echo -e "Gem::Specification.new {|s| s.name = 'newrelic_rpm'; s.version = '$phony_version'}" > $base_dir/specifications/newrelic_rpm-$phony_version.gemspec
    for sub_dir in '.git' '.github' '.gitignore' '.rubocop.yml' '.rubocop_todo.yml' '.simplecov' '.snyk' '.yardopts' 'Brewfile' 'config' 'CONTRIBUTING.md' 'docker-compose.yml' 'DOCKER.md' 'Dockerfile' 'Gemfile' 'Guardfile' 'infinite_tracing' 'init.rb' 'install.rb' 'lefthook.yml' 'newrelic.yml' 'README.md' 'test' 'THIRD_PARTY_NOTICES.md' 'Thorfile' 'recipes' '.build_ignore'; do
      rm -rf "$nr_dir/$sub_dir"
    done fi

  if [ "$EXTENSION_CLONE_PATH" == "" ]; then
    echo "Downloading prebuilt extension..."
    download_extension $arch
  else
    echo "Building an extension from a local clone..."
    here=$PWD
    cd "$EXTENSION_CLONE_PATH"
    make "dist-$arch"
    mv "$EXTENSION_DIST_DIR" "$here/$EXTENSION_DIST_DIR"
    mv "$EXTENSION_DIST_PREVIEW_FILE" "$here/$EXTENSION_DIST_PREVIEW_FILE"
    cd $here
  fi

  zip -rq $dist_file $RUBY_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
  rm -rf $RUBY_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
  echo "Build complete: ${dist_file}"
}

set +u # permit $1 to be unbound so that '*' matches it when no args are present
case "$1" in
  "ruby3.3")
    build_and_publish_ruby_for_arch $RUBY33_DIST_X86_64 '3.3' 'x86_64' 
	  publish_docker_ecr $RUBY33_DIST_X86_64 ruby3.3 x86_64
    build_and_publish_ruby_for_arch $RUBY33_DIST_ARM64 '3.3' 'arm64' 
	  publish_docker_ecr $RUBY33_DIST_ARM64 ruby3.3 arm64

    ;;
  "ruby3.2")
    build_and_publish_ruby_for_arch $RUBY32_DIST_X86_64 '3.2' 'x86_64'
	  publish_docker_ecr $RUBY32_DIST_X86_64 ruby3.2 x86_64
    build_and_publish_ruby_for_arch $RUBY32_DIST_ARM64 '3.2' 'arm64'
	  publish_docker_ecr $RUBY32_DIST_ARM64 ruby3.2 arm64
    ;;
  *)
    usage
    ;;
esac
