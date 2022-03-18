#!/usr/bin/env bash

set -Eeuo pipefail

BUILD_DIR=nodejs
DIST_DIR=dist

source ../libBuild.sh

NJS12X_DIST_ARM64=$DIST_DIR/nodejs12x.arm64.zip
NJS14X_DIST_ARM64=$DIST_DIR/nodejs14x.arm64.zip

NJS12X_DIST_X86_64=$DIST_DIR/nodejs12x.x86_64.zip
NJS14X_DIST_X86_64=$DIST_DIR/nodejs14x.x86_64.zip

function usage {
  	echo "./publish-layers.sh [nodejs12.x|nodejs14.x]"
}

function build-nodejs12x-arm64 {
    echo "Building new relic layer for nodejs12.x (arm64)"
    rm -rf $BUILD_DIR $NJS12X_DIST_ARM64
    mkdir -p $DIST_DIR
    npm install --prefix $BUILD_DIR newrelic@latest
    mkdir -p $BUILD_DIR/node_modules/newrelic-lambda-wrapper
    cp index.js $BUILD_DIR/node_modules/newrelic-lambda-wrapper
    download_extension arm64
    zip -rq $NJS12X_DIST_ARM64 $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    echo "Build complete: ${NJS12X_DIST_ARM64}"
}

function build-nodejs12x-x86 {
    echo "Building new relic layer for nodejs12.x (x86_64)"
    rm -rf $BUILD_DIR $NJS12X_DIST_X86_64
    mkdir -p $DIST_DIR
    npm install --prefix $BUILD_DIR newrelic@latest
    mkdir -p $BUILD_DIR/node_modules/newrelic-lambda-wrapper
    cp index.js $BUILD_DIR/node_modules/newrelic-lambda-wrapper
    download_extension x86_64
    zip -rq $NJS12X_DIST_X86_64 $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    echo "Build complete: ${NJS12X_DIST_X86_64}"
}

function publish-nodejs12x-arm64 {
    if [ ! -f $NJS12X_DIST_ARM64 ]; then
      echo "Package not found: ${NJS12X_DIST_ARM64}"
      exit 1
    fi

    for region in "${REGIONS_ARM[@]}"; do
      publish_layer $NJS12X_DIST_ARM64 $region nodejs12.x arm64
    done
}

function publish-nodejs12x-x86 {
    if [ ! -f $NJS12X_DIST_X86_64 ]; then
      echo "Package not found: ${NJS12X_DIST_X86_64}"
      exit 1
    fi

    for region in "${REGIONS_X86[@]}"; do
      publish_layer $NJS12X_DIST_X86_64 $region nodejs12.x x86_64
    done
}

function build-nodejs14x-arm64 {
	echo "Building new relic layer for nodejs14.x (arm64)"
	rm -rf $BUILD_DIR $NJS14X_DIST_ARM64
	mkdir -p $DIST_DIR
	npm install --prefix $BUILD_DIR newrelic@latest
	mkdir -p $BUILD_DIR/node_modules/newrelic-lambda-wrapper
	cp index.js $BUILD_DIR/node_modules/newrelic-lambda-wrapper
	download_extension arm64
	zip -rq $NJS14X_DIST_ARM64 $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
	rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
	echo "Build complete: ${NJS14X_DIST_ARM64}"
}

function build-nodejs14x-x86 {
	echo "Building new relic layer for nodejs14.x (x86_64)"
	rm -rf $BUILD_DIR $NJS14X_DIST_X86_64
	mkdir -p $DIST_DIR
	npm install --prefix $BUILD_DIR newrelic@latest
	mkdir -p $BUILD_DIR/node_modules/newrelic-lambda-wrapper
	cp index.js $BUILD_DIR/node_modules/newrelic-lambda-wrapper
	download_extension x86_64
	zip -rq $NJS14X_DIST_X86_64 $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
	rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
	echo "Build complete: ${NJS14X_DIST_X86_64}"
}

function publish-nodejs14x-arm64 {
    if [ ! -f $NJS14X_DIST_ARM64 ]; then
      echo "Package not found: ${NJS14X_DIST_ARM64}"
      exit 1
    fi

    for region in "${REGIONS_ARM[@]}"; do
      publish_layer $NJS14X_DIST_ARM64 $region nodejs14.x arm64
    done
}

function publish-nodejs14x-x86 {
    if [ ! -f $NJS14X_DIST_X86_64 ]; then
      echo "Package not found: ${NJS14X_DIST_X86_64}"
      exit 1
    fi

    for region in "${REGIONS_X86[@]}"; do
      publish_layer $NJS14X_DIST_X86_64 $region nodejs14.x x86_64
    done
}

case "$1" in
"build-nodejs12x")
	build-nodejs12x-arm64
	build-nodejs12x-x86
	;;
"publish-nodejs12x")
	publish-nodejs12x-arm64
	publish-nodejs12x-x86
	;;
"build-nodejs14x")
	build-nodejs14x-arm64
	build-nodejs14x-x86
	;;
"publish-nodejs14x")
	publish-nodejs14x-arm64
	publish-nodejs14x-x86
	;;
"nodejs12x")
	$0 build-nodejs12.x
	$0 publish-nodejs12.x
	;;
"nodejs14x")
	$0 build-nodejs14x
	$0 publish-nodejs14x
	;;
*)
	usage
	;;
esac
