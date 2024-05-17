#!/usr/bin/env bash

set -Eeuo pipefail

BUILD_DIR=build
GRADLE_ARCHIVE=$BUILD_DIR/distributions/NewRelicJavaLayer.zip

DIST_DIR=dist
JAVA8_DIST_ARM64=$DIST_DIR/java8.arm64.zip
JAVA8_DIST_X86_64=$DIST_DIR/java8.x86_64.zip
JAVA11_DIST_ARM64=$DIST_DIR/java11.arm64.zip
JAVA11_DIST_X86_64=$DIST_DIR/java11.x86_64.zip
JAVA17_DIST_ARM64=$DIST_DIR/java17.arm64.zip
JAVA17_DIST_X86_64=$DIST_DIR/java17.x86_64.zip
JAVA21_DIST_ARM64=$DIST_DIR/java21.arm64.zip
JAVA21_DIST_X86_64=$DIST_DIR/java21.x86_64.zip

source ../libBuild.sh

function usage {
	  echo "./publish-layers.sh [java8al2, java11, java17, java21]"
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

function build-java17-arm64 {
    build-arm "java17 (arm64)" 17 $JAVA17_DIST_ARM64
}

function build-java17-x86 {
    build-x86 "java17 (x86_64)" 17 $JAVA17_DIST_X86_64
}

function publish-java17-arm64 {
    if [ ! -f $JAVA17_DIST_ARM64 ]; then
      echo "Package not found"
      exit 1
    fi

    for region in "${REGIONS_ARM[@]}"; do
      publish_layer $JAVA17_DIST_ARM64 $region java17 arm64
    done
}

function publish-java17-x86 {
    if [ ! -f $JAVA17_DIST_X86_64 ]; then
      echo "Package not found"
      exit 1
    fi

    for region in "${REGIONS_X86[@]}"; do
      publish_layer $JAVA17_DIST_X86_64 $region java17 x86_64
    done
}

function build-java21-arm64 {
    build-arm "java21 (arm64)" 21 $JAVA21_DIST_ARM64
}

function build-java21-x86 {
    build-x86 "java21 (x86_64)" 21 $JAVA21_DIST_X86_64
}

function publish-java21-arm64 {
    if [ ! -f $JAVA21_DIST_ARM64 ]; then
      echo "Package not found"
      exit 1
    fi

    for region in "${REGIONS_ARM[@]}"; do
      publish_layer $JAVA21_DIST_ARM64 $region java21 arm64
    done
}

function publish-java21-x86 {
    if [ ! -f $JAVA21_DIST_X86_64 ]; then
      echo "Package not found"
      exit 1
    fi

    for region in "${REGIONS_X86[@]}"; do
      publish_layer $JAVA21_DIST_X86_64 $region java21 x86_64
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
"build-java17")
	build-java17-arm64
	build-java17-x86
        ;;
"publish-java17")
	publish-java17-arm64
	publish-java17-x86
	;;
"build-java21")
	build-java21-arm64
	build-java21-x86
        ;;
"publish-java21")
	publish-java21-arm64
	publish-java21-x86
	;;
"build-publish-java8al2-ecr-image")
	build-java8al2-arm64
  publish_docker_ecr $JAVA8_DIST_ARM64 java8 arm64
	build-java8al2-x86
  publish_docker_ecr $JAVA8_DIST_X86_64 java8 x86_64
	;;
"build-publish-java11-ecr-image")
	build-java11-arm64
  publish_docker_ecr $JAVA11_DIST_ARM64 java11 arm64
	build-java11-x86
  publish_docker_ecr $JAVA11_DIST_X86_64 java11 x86_64
	;;
"build-publish-java17-ecr-image")
	build-java17-arm64
  publish_docker_ecr $JAVA17_DIST_ARM64 java17 arm64
	build-java17-x86
  publish_docker_ecr $JAVA17_DIST_X86_64 java17 x86_64
        ;;
"build-publish-java21-ecr-image")
	build-java21-arm64
  publish_docker_ecr $JAVA21_DIST_ARM64 java21 arm64
	build-java21-x86
  publish_docker_ecr $JAVA21_DIST_X86_64 java21 x86_64
        ;;
"java8al2")
	$0 build-java8al2
	$0 publish-java8al2
	;;
"java11")
	$0 build-java11
	$0 publish-java11
	;;
"java17")
	$0 build-java17
	$0 publish-java17
	;;
"java21")
	$0 build-java21
	$0 publish-java21
	;;
*)
	usage
	;;
esac
