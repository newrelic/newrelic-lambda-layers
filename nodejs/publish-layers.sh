#!/usr/bin/env bash

set -Eeuo pipefail

BUILD_DIR=nodejs
DIST_DIR=dist

source ../libBuild.sh

NJS14X_DIST_ARM64=$DIST_DIR/nodejs14x.arm64.zip
NJS16X_DIST_ARM64=$DIST_DIR/nodejs16x.arm64.zip
NJS18X_DIST_ARM64=$DIST_DIR/nodejs18x.arm64.zip

NJS14X_DIST_X86_64=$DIST_DIR/nodejs14x.x86_64.zip
NJS16X_DIST_X86_64=$DIST_DIR/nodejs16x.x86_64.zip
NJS18X_DIST_X86_64=$DIST_DIR/nodejs18x.x86_64.zip

function usage {
  	echo "./publish-layers.sh [nodejs14x|nodejs16x|nodejs18x]"
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

function build-nodejs16x-arm64 {
	echo "Building new relic layer for nodejs16.x (arm64)"
	rm -rf $BUILD_DIR $NJS16X_DIST_ARM64
	mkdir -p $DIST_DIR
	npm install --prefix $BUILD_DIR newrelic@latest
	mkdir -p $BUILD_DIR/node_modules/newrelic-lambda-wrapper
	cp index.js $BUILD_DIR/node_modules/newrelic-lambda-wrapper
	download_extension arm64
	zip -rq $NJS16X_DIST_ARM64 $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
	rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
	echo "Build complete: ${NJS16X_DIST_ARM64}"
}

function build-nodejs16x-x86 {
	echo "Building new relic layer for nodejs16.x (x86_64)"
	rm -rf $BUILD_DIR $NJS16X_DIST_X86_64
	mkdir -p $DIST_DIR
	npm install --prefix $BUILD_DIR newrelic@latest
	mkdir -p $BUILD_DIR/node_modules/newrelic-lambda-wrapper
	cp index.js $BUILD_DIR/node_modules/newrelic-lambda-wrapper
	download_extension x86_64
	zip -rq $NJS16X_DIST_X86_64 $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
	rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
	echo "Build complete: ${NJS16X_DIST_X86_64}"
}

function publish-nodejs16x-arm64 {
    if [ ! -f $NJS16X_DIST_ARM64 ]; then
      echo "Package not found: ${NJS16X_DIST_ARM64}"
      exit 1
    fi

    for region in "${REGIONS_ARM[@]}"; do
      publish_layer $NJS16X_DIST_ARM64 $region nodejs16.x arm64
    done
}

function publish-nodejs16x-x86 {
    if [ ! -f $NJS16X_DIST_X86_64 ]; then
      echo "Package not found: ${NJS16X_DIST_X86_64}"
      exit 1
    fi

    for region in "${REGIONS_X86[@]}"; do
      publish_layer $NJS16X_DIST_X86_64 $region nodejs16.x x86_64
    done
}

function build-nodejs18x-arm64 {
	echo "Building new relic layer for nodejs18.x (arm64)"
	rm -rf $BUILD_DIR $NJS18X_DIST_ARM64
	mkdir -p $DIST_DIR
	npm install --prefix $BUILD_DIR newrelic@latest
	mkdir -p $BUILD_DIR/node_modules/newrelic-lambda-wrapper
	cp index.js $BUILD_DIR/node_modules/newrelic-lambda-wrapper
	download_extension arm64
	zip -rq $NJS18X_DIST_ARM64 $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
	rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
	echo "Build complete: ${NJS18X_DIST_ARM64}"
}

function build-nodejs18x-x86 {
	echo "Building new relic layer for nodejs18.x (x86_64)"
	rm -rf $BUILD_DIR $NJS18X_DIST_X86_64
	mkdir -p $DIST_DIR
	npm install --prefix $BUILD_DIR newrelic@latest
	mkdir -p $BUILD_DIR/node_modules/newrelic-lambda-wrapper
	cp index.js $BUILD_DIR/node_modules/newrelic-lambda-wrapper
	download_extension x86_64
	zip -rq $NJS18X_DIST_X86_64 $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
	rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
	echo "Build complete: ${NJS18X_DIST_X86_64}"
}

function publish-nodejs18x-arm64 {
    if [ ! -f $NJS18X_DIST_ARM64 ]; then
      echo "Package not found: ${NJS18X_DIST_ARM64}"
      exit 1
    fi

    for region in "${REGIONS_ARM[@]}"; do
      publish_layer $NJS18X_DIST_ARM64 $region nodejs18.x arm64
    done
}

function publish-nodejs18x-x86 {
    if [ ! -f $NJS18X_DIST_X86_64 ]; then
      echo "Package not found: ${NJS18X_DIST_X86_64}"
      exit 1
    fi

    for region in "${REGIONS_X86[@]}"; do
      publish_layer $NJS18X_DIST_X86_64 $region nodejs18.x x86_64
    done
}

case "$1" in
"build-nodejs14x")
	build-nodejs14x-arm64
	build-nodejs14x-x86
	;;
"publish-nodejs14x")
	publish-nodejs14x-arm64
	publish-nodejs14x-x86
	;;
"build-nodejs16x")
	build-nodejs16x-arm64
	build-nodejs16x-x86
	;;
"publish-nodejs16x")
	publish-nodejs16x-arm64
	publish-nodejs16x-x86
	;;
"build-nodejs18x")
	build-nodejs18x-arm64
	build-nodejs18x-x86
	;;
"publish-nodejs18x")
	publish-nodejs18x-arm64
	publish-nodejs18x-x86
	;;
"nodejs14x")
	$0 build-nodejs14x
	$0 publish-nodejs14x
	;;
"nodejs16x")
	$0 build-nodejs16x
	$0 publish-nodejs16x
	;;
"nodejs18x")
	$0 build-nodejs18x
	$0 publish-nodejs18x
	;;
*)
	usage
	;;
esac
