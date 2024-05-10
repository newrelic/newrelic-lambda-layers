#!/usr/bin/env bash

set -Eeuo pipefail

BUILD_DIR=lib # for .net can either be lib  or bin. See: https://docs.aws.amazon.com/lambda/latest/dg/packaging-layers.html
DIST_DIR=dist

DOTNET_DIST_ARM64=$DIST_DIR/dotnet.arm64.zip
DOTNET_DIST_X86_64=$DIST_DIR/dotnet.x86_64.zip

AGENT_DIST_ZIP=agent.zip

source ../libBuild.sh

function usage {
    echo "./publish-layers.sh [dotnet]"
}

function build-dotnet-x86-64 {
    echo "Building New Relic layer for .NET 6, 7 and 8 (x86_64)"
    rm -rf $BUILD_DIR $DOTNET_DIST_X86_64
    mkdir -p $DIST_DIR
    get_agent amd64
    # MAKE CONFIG CHANGES HERE
    download_extension x86_64
    zip -rq $DOTNET_DIST_X86_64 $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    echo "Build complete: ${DOTNET_DIST_X86_64}"
}

function publish-dotnet-x86-64 {
    if [ ! -f $DOTNET_DIST_X86_64 ]; then
        echo "Package not found: ${DOTNET_DIST_X86_64}"
        exit 1
    fi

    for region in "${REGIONS_X86[@]}"; do
      publish_layer $DOTNET_DIST_X86_64 $region dotnet x86_64
    done
}

function build-dotnet-arm64 {
    echo "Building New Relic layer for .NET 6, 7 and 8 (ARM64)"
    rm -rf $BUILD_DIR $DOTNET_DIST_ARM64
    mkdir -p $DIST_DIR
    get_agent arm64
    # MAKE CONFIG CHANGES HERE
    download_extension arm64
    zip -rq $DOTNET_DIST_ARM64 $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    echo "Build complete: ${DOTNET_DIST_ARM64}"
}

function publish-dotnet-arm64 {
    if [ ! -f $DOTNET_DIST_ARM64 ]; then
        echo "Package not found: ${DOTNET_DIST_ARM64}"
        exit 1
    fi

    for region in "${REGIONS_ARM[@]}"; do
      publish_layer $DOTNET_DIST_ARM64 $region dotnet arm64
    done
}

# exmaple https://download.newrelic.com/dot_net_agent/latest_release/newrelic-dotnet-agent_10.22.0_amd64.tar.gz
function get_agent {
    arch=$1
    
    url="https://download.newrelic.com/dot_net_agent/latest_release/newrelic-dotnet-agent_${AGENT_VERSION}_${arch}.tar.gz"
    rm -rf $AGENT_DIST_ZIP
    curl -L $url -o $AGENT_DIST_ZIP
    mkdir -p $BUILD_DIR
    tar -xvf $AGENT_DIST_ZIP -C ./$BUILD_DIR # under $BUILD_DIR/newrelic-dotnet-agent
    rm -f $AGENT_DIST_ZIP
}

if [ -z $AGENT_VERSION ]; then
    echo "Missing required AGENT_VERSION environment variable: ${AGENT_VERSION}."
    exit 1
fi

case "${1:-default}" in
    "dotnet")
        build-dotnet-arm64
        #publish-dotnet-arm64
        build-dotnet-x86-64
        #publish-dotnet-x86-64
        ;;
    *)
        usage
        ;;
esac
