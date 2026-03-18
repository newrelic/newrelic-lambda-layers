#!/usr/bin/env bash

set -Eeuo pipefail

source ../shared/lib.sh

export JAVA_AGENT_DIST_X86_64=$DIST_DIR/java-agent-full.x86_64.zip
export JAVA_AGENT_DIST_ARM64=$DIST_DIR/java-agent-full.arm64.zip
AGENT_PATH=$1

build-java-agent $JAVA_AGENT_DIST_X86_64 x86_64 $AGENT_PATH
build-java-agent $JAVA_AGENT_DIST_ARM64 arm64 $AGENT_PATH