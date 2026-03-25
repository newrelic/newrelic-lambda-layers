#!/usr/bin/env bash

set -Eeuo pipefail

export AGENT_JAR=newrelic.jar
export JAVA_HANDLER=java-handler

export AGENT_DIR=newrelic
export DIST_DIR=dist

export JAVA_AGENT_DIST_ARM64=$DIST_DIR/java-agent-lite.arm64.zip
export JAVA_AGENT_DIST_X86_64=$DIST_DIR/java-agent-lite.x86_64.zip

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

source ../../libBuild.sh
source $parent_path/versions.sh

function build-java-agent {
    distribution_file=$1
    arch=$2
    agent_path=$3
    echo "Building New Relic layer for the Java Agent ($arch)"
    rm -rf $AGENT_DIR $distribution_file
    mkdir -p $DIST_DIR
    get_agent $agent_path
    download_extension $arch
    zip -rq $distribution_file $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE $JAVA_HANDLER $AGENT_DIR
    rm -rf $AGENT_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
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


function publish-java-agent {
    distribution_file=$1
    slim=$2
    if [[ $slim != "slim" ]]; then
        slim=""
    fi
    arch=$3
    if [ ! -f $distribution_file ]; then
        echo "Package not found: ${distribution_file}"
        exit 1
    fi

    for runtime in "${SUPPORTED_JAVA_VERSIONS[@]}"; do
        for region in "${REGIONS[@]}"; do
            echo "Publishing for $runtime and $region"
            publish_layer $distribution_file $region $runtime $arch $NEWRELIC_AGENT_VERSION $slim agent
        done

        publish_docker_ecr $distribution_file $runtime $arch agent
    done
}