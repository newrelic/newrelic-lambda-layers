#!/usr/bin/env bash

set -Eeuo pipefail

BUILD_DIR=nodejs
DIST_DIR=dist

source ../libBuild.sh

NJS18X_DIST_ARM64=$DIST_DIR/nodejs18x.arm64.zip
NJS20X_DIST_ARM64=$DIST_DIR/nodejs20x.arm64.zip
NJS22X_DIST_ARM64=$DIST_DIR/nodejs22x.arm64.zip

NJS18X_DIST_X86_64=$DIST_DIR/nodejs18x.x86_64.zip
NJS20X_DIST_X86_64=$DIST_DIR/nodejs20x.x86_64.zip
NJS22X_DIST_X86_64=$DIST_DIR/nodejs22x.x86_64.zip

function usage {
  	echo "./publish-layers.sh [nodejs18x|nodejs20x]"
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

function build-nodejs20x-arm64 {
	echo "Building new relic layer for nodejs20.x (arm64)"
	rm -rf $BUILD_DIR $NJS20X_DIST_ARM64
	mkdir -p $DIST_DIR
	npm install --prefix $BUILD_DIR newrelic@latest
	mkdir -p $BUILD_DIR/node_modules/newrelic-lambda-wrapper
	cp index.js $BUILD_DIR/node_modules/newrelic-lambda-wrapper
	download_extension arm64
	zip -rq $NJS20X_DIST_ARM64 $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
	rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
	echo "Build complete: ${NJS20X_DIST_ARM64}"
}

function build-nodejs20x-x86 {
	echo "Building new relic layer for nodejs20.x (x86_64)"
	rm -rf $BUILD_DIR $NJS20X_DIST_X86_64
	mkdir -p $DIST_DIR
	npm install --prefix $BUILD_DIR newrelic@latest
	mkdir -p $BUILD_DIR/node_modules/newrelic-lambda-wrapper
	cp index.js $BUILD_DIR/node_modules/newrelic-lambda-wrapper
	download_extension x86_64
	zip -rq $NJS20X_DIST_X86_64 $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
	rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
	echo "Build complete: ${NJS20X_DIST_X86_64}"
}

function publish-nodejs20x-arm64 {
    if [ ! -f $NJS20X_DIST_ARM64 ]; then
      echo "Package not found: ${NJS20X_DIST_ARM64}"
      exit 1
    fi

    for region in "${REGIONS_ARM[@]}"; do
      publish_layer $NJS20X_DIST_ARM64 $region nodejs20.x arm64
    done
}

function publish-nodejs20x-x86 {
    if [ ! -f $NJS20X_DIST_X86_64 ]; then
      echo "Package not found: ${NJS20X_DIST_X86_64}"
      exit 1
    fi

    for region in "${REGIONS_X86[@]}"; do
      publish_layer $NJS20X_DIST_X86_64 $region nodejs20.x x86_64
    done
}

function build-nodejs22x-arm64 {
	echo "Building new relic layer for nodejs22.x (arm64)"
	rm -rf $BUILD_DIR $NJS22X_DIST_ARM64
	mkdir -p $DIST_DIR
	npm install --prefix $BUILD_DIR newrelic@latest
	mkdir -p $BUILD_DIR/node_modules/newrelic-lambda-wrapper
	cp index.js $BUILD_DIR/node_modules/newrelic-lambda-wrapper
	download_extension arm64
	zip -rq $NJS22X_DIST_ARM64 $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
	rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
	echo "Build complete: ${NJS22X_DIST_ARM64}"
}

function build-nodejs22x-x86 {
	echo "Building new relic layer for nodejs22.x (x86_64)"
	rm -rf $BUILD_DIR $NJS22X_DIST_X86_64
	mkdir -p $DIST_DIR
	npm install --prefix $BUILD_DIR newrelic@latest
	mkdir -p $BUILD_DIR/node_modules/newrelic-lambda-wrapper
	cp index.js $BUILD_DIR/node_modules/newrelic-lambda-wrapper
	download_extension x86_64
	zip -rq $NJS22X_DIST_X86_64 $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
	rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
	echo "Build complete: ${NJS22X_DIST_X86_64}"
}

function publish-nodejs22x-arm64 {
    if [ ! -f $NJS22X_DIST_ARM64 ]; then
      echo "Package not found: ${NJS22X_DIST_ARM64}"
      exit 1
    fi

    for region in "${REGIONS_ARM[@]}"; do
      publish_layer $NJS22X_DIST_ARM64 $region nodejs22.x arm64
    done
}

function publish-nodejs22x-x86 {
    if [ ! -f $NJS22X_DIST_X86_64 ]; then
      echo "Package not found: ${NJS22X_DIST_X86_64}"
      exit 1
    fi

    for region in "${REGIONS_X86[@]}"; do
      publish_layer $NJS22X_DIST_X86_64 $region nodejs22.x x86_64
    done
}

case "$1" in
"build-nodejs18x")
	build-nodejs18x-arm64
	build-nodejs18x-x86
	;;
"publish-nodejs18x")
	publish-nodejs18x-arm64
	publish-nodejs18x-x86
	;;
"build-nodejs20x")
	build-nodejs20x-arm64
	build-nodejs20x-x86
	;;
"publish-nodejs20x")
	publish-nodejs20x-arm64
	publish-nodejs20x-x86
	;;
"build-nodejs22x")
	build-nodejs22x-arm64
	build-nodejs22x-x86
	;;
"publish-nodejs22x")
	publish-nodejs22x-arm64
	publish-nodejs22x-x86
	;;
"build-publish-nodejs18x-ecr-image")
	build-nodejs18x-arm64
	publish_docker_ecr $NJS18X_DIST_ARM64 nodejs18.x arm64
	build-nodejs18x-x86
	publish_docker_ecr $NJS18X_DIST_X86_64 nodejs18.x x86_64
	;;
"build-publish-nodejs20x-ecr-image")
	build-nodejs20x-arm64
	publish_docker_ecr $NJS20X_DIST_ARM64 nodejs20.x arm64
	build-nodejs20x-x86
	publish_docker_ecr $NJS20X_DIST_X86_64 nodejs20.x x86_64
	;;
"build-publish-nodejs22x-ecr-image")
	build-nodejs22x-arm64
	publish_docker_ecr $NJS22X_DIST_ARM64 nodejs22.x arm64
	build-nodejs22x-x86
	publish_docker_ecr $NJS22X_DIST_X86_64 nodejs22.x x86_64
	;;
"nodejs18x")
	$0 build-nodejs18x
	$0 publish-nodejs18x
	;;
"nodejs20x")
	$0 build-nodejs20x
	$0 publish-nodejs20x
	;;
"nodejs22x")
	$0 build-nodejs22x
	$0 publish-nodejs22x
	;;
*)
	usage
	;;
esac
