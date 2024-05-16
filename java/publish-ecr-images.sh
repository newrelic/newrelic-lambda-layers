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
	  echo "./publish-ecr-images.sh [java8al2, java11, java17, java21]"
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

function build-java11-arm64 {
    build-arm "java11 (arm64)" 11 $JAVA11_DIST_ARM64
}

function build-java11-x86 {
    build-x86 "java11 (x86_64)" 11 $JAVA11_DIST_X86_64
}


function build-java17-arm64 {
    build-arm "java17 (arm64)" 17 $JAVA17_DIST_ARM64
}

function build-java17-x86 {
    build-x86 "java17 (x86_64)" 17 $JAVA17_DIST_X86_64
}


function build-java21-arm64 {
    build-arm "java21 (arm64)" 21 $JAVA21_DIST_ARM64
}

function build-java21-x86 {
    build-x86 "java21 (x86_64)" 21 $JAVA21_DIST_X86_64
}


case "$1" in
"build-publish-java8al2-ecr-image")
	build-java8al2-arm64
  publish_docker_ecr $JAVA8_DIST_ARM64 java8.al2 arm64
	build-java8al2-x86
  publish_docker_ecr $JAVA8_DIST_X86_64 java8.al2 x86_64
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
	$0 build-publish--java8al2-ecr-image
	;;
"java11")
	$0 build-publish-java11-ecr-image
	;;
"java17")
	$0 build-publish-java17-ecr-image
	;;
"java21")
	$0 build-publish-java21-ecr-image
	;;
*)
	usage
	;;
esac
