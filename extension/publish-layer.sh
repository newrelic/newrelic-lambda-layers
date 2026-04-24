#!/usr/bin/env bash

set -Eeuo pipefail

EXTENSION_DIST_ZIP_ARM64=extension.arm64.zip
EXTENSION_DIST_ZIP_X86_64=extension.x86_64.zip

source ../libBuild.sh

function build-layer-x86 {
    echo "Building New Relic Lambda Extension Layer (x86_64)"
    rm -f $EXTENSION_DIST_ZIP_X86_64 $EXTENSION_DIST_ZIP

    fetch_extension x86_64
    mv $EXTENSION_DIST_ZIP $EXTENSION_DIST_ZIP_X86_64
    echo "Build complete: ${EXTENSION_DIST_ZIP_X86_64}"
}

function build-layer-arm64 {
    echo "Building New Relic Lambda Extension Layer (arm64)"
    rm -f $EXTENSION_DIST_ZIP_ARM64 $EXTENSION_DIST_ZIP

    fetch_extension arm64
    mv $EXTENSION_DIST_ZIP $EXTENSION_DIST_ZIP_ARM64
    echo "Build complete: ${EXTENSION_DIST_ZIP_ARM64}"
}

function publish-layer-x86 {
    if [ ! -f $EXTENSION_DIST_ZIP_X86_64 ]; then
        echo "Package not found: ${EXTENSION_DIST_ZIP_X86_64}"
        exit 1
    fi

    for region in "${REGIONS[@]}"; do
      publish_layer $EXTENSION_DIST_ZIP_X86_64 $region provided x86_64 provided
    done
}

function publish-layer-arm64 {
    if [ ! -f $EXTENSION_DIST_ZIP_ARM64 ]; then
        echo "Package not found: ${EXTENSION_DIST_ZIP_ARM64}"
        exit 1
    fi

    for region in "${REGIONS[@]}"; do
      publish_layer $EXTENSION_DIST_ZIP_ARM64 $region provided arm64 provided
    done
}

function publish-staging {
    build-layer-x86
    build-layer-arm64

    arn_x86=$(publish_staging_layer "$EXTENSION_DIST_ZIP_X86_64" provided x86_64)
    echo "arn_x86=${arn_x86}" >> "${GITHUB_OUTPUT:-/dev/stderr}"

    arn_arm64=$(publish_staging_layer "$EXTENSION_DIST_ZIP_ARM64" provided arm64)
    echo "arn_arm64=${arn_arm64}" >> "${GITHUB_OUTPUT:-/dev/stderr}"
}

function cleanup-staging {
    for arn in "${ARN_X86:-}" "${ARN_ARM64:-}"; do
        [[ -z "$arn" ]] && continue
        delete_staging_layer "$(echo "$arn" | cut -d: -f8)" "$(echo "$arn" | cut -d: -f9)"
    done
}

case "${1:-publish}" in
  "publish-staging")  publish-staging ;;
  "cleanup-staging")  cleanup-staging ;;
  *)
    build-layer-x86
    publish-layer-x86
    publish_docker_ecr $EXTENSION_DIST_ZIP_X86_64 extension x86_64

    build-layer-arm64
    publish-layer-arm64
    publish_docker_ecr $EXTENSION_DIST_ZIP_ARM64 extension arm64
    ;;
esac
