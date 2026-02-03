#!/usr/bin/env bash

set -Eeuo pipefail

BUILD_DIR=lib # for .net can either be lib  or bin. See: https://docs.aws.amazon.com/lambda/latest/dg/packaging-layers.html
DIST_DIR=dist

DOTNET_DIST_ARM64=$DIST_DIR/dotnet.arm64.zip
DOTNET_DIST_X86_64=$DIST_DIR/dotnet.x86_64.zip

AGENT_DIST_ZIP=agent.zip
NEWRELIC_AGENT_VERSION=""
VERSION_REGEX='^v([0-9]+\.[0-9]+\.[0-9]+)$'
GITHUB_REF_URL="https://api.github.com/repos/newrelic/newrelic-dotnet-agent/releases/latest"

source ../libBuild.sh

function usage {
    echo "./publish-layers.sh"
}

function build-dotnet-x86-64 {
    echo "Building New Relic layer for .NET 6, 7, 8 and 10 (x86_64)"
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

    for region in "${REGIONS[@]}"; do
      publish_layer $DOTNET_DIST_X86_64 $region dotnet x86_64 $NEWRELIC_AGENT_VERSION
    done

    publish_docker_ecr $DOTNET_DIST_X86_64 dotnet x86_64
}

function build-dotnet-arm64 {
    echo "Building New Relic layer for .NET 6, 7, 8 and 10 (ARM64)"
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

    for region in "${REGIONS[@]}"; do
      publish_layer $DOTNET_DIST_ARM64 $region dotnet arm64 $NEWRELIC_AGENT_VERSION
    done

    publish_docker_ecr $DOTNET_DIST_ARM64 dotnet arm64
}

# exmaple https://download.newrelic.com/dot_net_agent/latest_release/newrelic-dotnet-agent_amd64.tar.gz
function get_agent {
    arch=$1

    if command -v jq >/dev/null 2>&1; then
        latest_tag=$(curl -s ${GITHUB_REF_URL} | jq -r '.tag_name')
    else
        latest_tag=$(curl -s ${GITHUB_REF_URL} | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    fi
    
    if [[ -z "${latest_tag}" || "${latest_tag}" == "null" ]]; then
        echo "Unable to fetch latest tag from GitHub API." >&2
        exit 1
    fi
    
    echo "Latest tag found: ${latest_tag}"
    
    # Extract version number from tag (assuming tag format like "v1.2.3")
    if [[ "${latest_tag}" =~ ${VERSION_REGEX} ]]; then
        NEWRELIC_AGENT_VERSION="${BASH_REMATCH[1]}"
        echo "$NEWRELIC_AGENT_VERSION" > version.txt
        echo "Detected NEWRELIC_DOTNET_AGENT_VERSION: ${NEWRELIC_AGENT_VERSION}"
    else
        echo "Unable to parse version from tag: ${latest_tag}" >&2
        exit 1
    fi
    
    url="https://download.newrelic.com/dot_net_agent/latest_release/newrelic-dotnet-agent_${NEWRELIC_AGENT_VERSION}_${arch}.tar.gz"
    rm -rf $AGENT_DIST_ZIP
    curl -L $url -o $AGENT_DIST_ZIP
    mkdir -p $BUILD_DIR
    tar -xvf $AGENT_DIST_ZIP -C ./$BUILD_DIR # under $BUILD_DIR/newrelic-dotnet-agent
    cp version.txt $BUILD_DIR/newrelic-dotnet-agent/version.txt
    rm -f $AGENT_DIST_ZIP
}


build-dotnet-arm64
publish-dotnet-arm64
build-dotnet-x86-64
publish-dotnet-x86-64

