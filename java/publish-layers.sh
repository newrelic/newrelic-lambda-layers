#!/usr/bin/env bash

set -Eeuo pipefail

BUILD_DIR=build
GRADLE_ARCHIVE=$BUILD_DIR/distributions/NewRelicJavaLayer.zip

DIST_DIR=dist
JAVA8_DIST_ARM64=$DIST_DIR/java8.arm64.zip
JAVA8_DIST_X86_64=$DIST_DIR/java8.x86_64.zip
JAVA11_DIST_ARM64=$DIST_DIR/java11.arm64.zip
JAVA11_DIST_X86_64=$DIST_DIR/java11.x86_64.zip

source ../libBuild.sh

function usage {
	  echo "./publish-layers.sh [java8al2, java11]"
}

function build-arm() {
    platform=$1
    javaVersion=$2
    target=$3

    echo "Building New Relic layer for ${platform}"
    rm -rf $BUILD_DIR $target
    download_extension arm64
    ./gradlew packageLayer -P javaVersion=$javaVersion
    mkdir -p $DIST_DIR
    cp $GRADLE_ARCHIVE $target
    rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    echo "Build complete"
}

function build-x86() {
    platform=$1
    javaVersion=$2
    target=$3

    echo "Building New Relic layer for ${platform}"
    rm -rf $BUILD_DIR $target
    download_extension x86_64
    ./gradlew packageLayer -P javaVersion=$javaVersion
    mkdir -p $DIST_DIR
    cp $GRADLE_ARCHIVE $target
    rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    echo "Build complete"
}

function build-java8al2-arm64 {
    build-arm "java8.al2 (arm64)" 8 $JAVA8_DIST_ARM64
}

function build-java8al2-x86 {
    build-x86 "java8.al2 (x86_64)" 8 $JAVA8_DIST_X86_64
}

function publish-java8al2-arm64 {
    if [ ! -f  $JAVA8_DIST_ARM64 ]; then
      echo "Package not found"
      exit 1
    fi

    for region in "${REGIONS_ARM[@]}"; do
      publish_layer $JAVA8_DIST_ARM64 $region java8.al2 arm64
    done
}

function publish-java8al2-x86 {
    if [ ! -f $JAVA8_DIST_X86_64 ]; then
      echo "Package not found"
      exit 1
    fi

    for region in "${REGIONS_X86[@]}"; do
      publish_layer $JAVA8_DIST_X86_64 $region java8.al2 x86_64
    done
}

function build-java11-arm64 {
    build-arm "java11 (arm64)" 11 $JAVA11_DIST_ARM64
}

function build-java11-x86 {
    build-x86 "java11 (x86_64)" 11 $JAVA11_DIST_X86_64
}

function publish-java11-arm64 {
    if [ ! -f $JAVA11_DIST_ARM64 ]; then
      echo "Package not found"
      exit 1
    fi

    for region in "${REGIONS_ARM[@]}"; do
      publish_layer $JAVA11_DIST_ARM64 $region java11 arm64
    done
}

function publish-java11-x86 {
    if [ ! -f $JAVA11_DIST_X86_64 ]; then
      echo "Package not found"
      exit 1
    fi

    for region in "${REGIONS_X86[@]}"; do
      publish_layer $JAVA11_DIST_X86_64 $region java11 x86_64
    done
}

case "$1" in
"build-java8al2")
	build-java8al2-arm64
	build-java8al2-x86
	;;
"publish-java8al2")
	publish-java8al2-arm64
	publish-java8al2-x86
	;;
"build-java11")
	build-java11-arm64
	build-java11-x86
	;;
"publish-java11")
	publish-java11-arm64
	publish-java11-x86
	;;
"java8al2")
	$0 build-java8al2
	$0 publish-java8al2
	;;
"java11")
	$0 build-java11
	$0 publish-java11
	;;
*)
	usage
	;;
esac
