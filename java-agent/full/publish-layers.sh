#!/usr/bin/env bash

set -Eeuo pipefail

source ../shared/lib.sh
source ./build-layers.sh

publish-java-agent $JAVA_AGENT_DIST_X86_64 full x86_64
publish-java-agent $JAVA_AGENT_DIST_ARM64 full arm64