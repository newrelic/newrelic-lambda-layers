#!/usr/bin/env bash

set -Eeuo pipefail

AGENT_PATH=$1
export AGENT_JAR=newrelic.jar

export AGENT_DIR=newrelic
export DIST_DIR=dist
export EXEC_WRAPPER=newrelic-java-handler
export LIB_HANDLER=lib-handler.sh

export JAVA_AGENT_DIST_X86_64=$DIST_DIR/java-agent.x86_64.zip
export JAVA_AGENT_DIST_ARM64=$DIST_DIR/java-agent.arm64.zip

export JAVA_AGENT_SLIM_DIST_X86_64=$DIST_DIR/java-agent-slim.x86_64.zip
export JAVA_AGENT_SLIM_DIST_ARM64=$DIST_DIR/java-agent-slim.arm64.zip

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

source ../libBuild.sh
source versions.sh

function build-java-agent {
    distribution_file=$1
    arch=$2
    agent_path=$3
    java_handler_path=$4
    echo "Building New Relic layer for the Java Agent ($arch)"
    rm -rf $AGENT_DIR $distribution_file
    mkdir -p $DIST_DIR
    get_agent $agent_path
    download_extension $arch
    cp $java_handler_path ./$EXEC_WRAPPER
    zip -rq $distribution_file $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE ./$EXEC_WRAPPER $AGENT_DIR $LIB_HANDLER
    rm -rf $AGENT_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE ./$EXEC_WRAPPER
    echo "Build complete: ${distribution_file}"
}

function get_agent {
    agent_path=$1
    rm -rf $AGENT_JAR

    if [[ -n "$agent_path" ]]; then
        echo "Copying agent from $agent_path"
        cp ${agent_path} $AGENT_JAR
    else
         url="https://download.newrelic.com/newrelic/java-agent/newrelic-agent/${NEWRELIC_AGENT_VERSION}/newrelic-agent-${NEWRELIC_AGENT_VERSION}.jar"
         echo "Downloading agent from $url"
         curl -L $url -o $AGENT_JAR
    fi

    mkdir -p $AGENT_DIR
    mv $AGENT_JAR $AGENT_DIR/$AGENT_JAR
    rm -f $AGENT_JAR
}

build-java-agent $JAVA_AGENT_DIST_X86_64 x86_64 $AGENT_PATH ./java-handler-full
build-java-agent $JAVA_AGENT_DIST_ARM64 arm64 $AGENT_PATH ./java-handler-full
build-java-agent $JAVA_AGENT_SLIM_DIST_X86_64 x86_64 $AGENT_PATH ./java-handler-slim
build-java-agent $JAVA_AGENT_SLIM_DIST_ARM64 arm64 $AGENT_PATH ./java-handler-slim