#!/usr/bin/env bash

set -Eeuo pipefail

source ./build-layers.sh

function publish-java-agent {
    distribution_file=$1
    arch=$2
    slim=$3
    if [[ $slim != "slim" ]]; then
        slim=""
    fi
    if [ ! -f $distribution_file ]; then
        echo "Package not found: ${distribution_file}"
        exit 1
    fi

    for region in "${REGIONS[@]}"; do
        echo "Publishing $slim java agent layer in region $region"
        publish_layer $distribution_file $region java $arch $NEWRELIC_AGENT_VERSION $slim
    done

    publish_docker_ecr $distribution_file java $arch $slim
}

publish-java-agent $JAVA_AGENT_DIST_X86_64 x86_64 ""
publish-java-agent $JAVA_AGENT_DIST_ARM64 arm64 ""

publish-java-agent $JAVA_AGENT_SLIM_DIST_X86_64 x86_64 slim
publish-java-agent $JAVA_AGENT_SLIM_DIST_ARM64 arm64 slim