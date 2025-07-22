#!/usr/bin/env bash

set -Eeuo pipefail

BUILD_DIR=python
DIST_DIR=dist
NEWRELIC_AGENT_VERSION=""
VERSION_REGEX="v?([0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+_python"
PY38_DIST_ARM64=$DIST_DIR/python38.arm64.zip
PY39_DIST_ARM64=$DIST_DIR/python39.arm64.zip
PY310_DIST_ARM64=$DIST_DIR/python310.arm64.zip
PY311_DIST_ARM64=$DIST_DIR/python311.arm64.zip
PY312_DIST_ARM64=$DIST_DIR/python312.arm64.zip
PY313_DIST_ARM64=$DIST_DIR/python313.arm64.zip

PY38_DIST_X86_64=$DIST_DIR/python38.x86_64.zip
PY39_DIST_X86_64=$DIST_DIR/python39.x86_64.zip
PY310_DIST_X86_64=$DIST_DIR/python310.x86_64.zip
PY311_DIST_X86_64=$DIST_DIR/python311.x86_64.zip
PY312_DIST_X86_64=$DIST_DIR/python312.x86_64.zip
PY313_DIST_X86_64=$DIST_DIR/python313.x86_64.zip

source ../libBuild.sh

function usage {
    echo "./publish-layers.sh [python3.9|python3.10|python3.11|python3.12|python3.13]"
}

function build_python_layer {
    local python_version=$1
    local arch=$2
    ZIP=$DIST_DIR/python${python_version//./}.${arch}.zip
    echo "zip file: ${ZIP}"
    echo "Building New Relic layer for python${python_version} (${arch})"
    rm -rf $BUILD_DIR $ZIP
    mkdir -p $DIST_DIR

    # Determine agent version from git tag
    if [[ -z "${GITHUB_REF_NAME}" ]]; then
        echo "Unable to determine agent version, GITHUB_REF_NAME environment variable not set." >&2
        exit 1;
    elif [[ "${GITHUB_REF_NAME}" =~ ${VERSION_REGEX} ]]; then
        # Extract the version number from the GITHUB_REF_NAME using regex
        NEWRELIC_AGENT_VERSION="${BASH_REMATCH[1]}"
        echo "Detected NEWRELIC_AGENT_VERSION: ${NEWRELIC_AGENT_VERSION}"
    else
        echo "Unable to determine agent version, GITHUB_REF_NAME environment variable did not match regex. GITHUB_REF_NAME: ${GITHUB_REF_NAME}" >&2
        exit 1;
    fi

    pip install --no-cache-dir -qU "newrelic==${NEWRELIC_AGENT_VERSION}" newrelic-lambda -t $BUILD_DIR/lib/python${python_version}/site-packages
    cp newrelic_lambda_wrapper.py "$BUILD_DIR/lib/python${python_version}/site-packages/newrelic_lambda_wrapper.py"
    find $BUILD_DIR -name '__pycache__' -exec rm -rf {} +
    
    download_extension $arch
    zip -rq $ZIP $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE

    echo "Build complete: ${ZIP}"
}


function publish_python_layer {
    local python_version=$1
    local arch=$2
    ZIP=$DIST_DIR/python${python_version//./}.${arch}.zip

    if [ ! -f ${ZIP} ]; then
        echo "Package not found: ${ZIP}"
        exit 1
    fi

    if [[ "${arch}" == "arm64" ]]; then
        REGIONS=("${REGIONS_ARM[@]}");
    else
        REGIONS=("${REGIONS_X86[@]}");
    fi

    for region in "${REGIONS[@]}"; do
        echo "Publishing layer for python${python_version} (${arch}) to region ${region}"
        publish_layer ${ZIP} $region python${python_version} ${arch} $NEWRELIC_AGENT_VERSION
    done
}


case "$1" in
    "python3.9")
        build_python_layer 3.9 arm64
        publish_python_layer 3.9 arm64
        publish_docker_ecr $PY39_DIST_ARM64 python3.9 arm64
        build_python_layer 3.9 x86_64
        publish_python_layer 3.9 x86_64
        publish_docker_ecr $PY39_DIST_X86_64 python3.9 x86_64
        ;;
    "python3.10")
        build_python_layer 3.10 arm64
        publish_python_layer 3.10 arm64
        publish_docker_ecr $PY310_DIST_ARM64 python3.10 arm64
        build_python_layer 3.10 x86_64
        publish_python_layer 3.10 x86_64
        publish_docker_ecr $PY310_DIST_X86_64 python3.10 x86_64
        ;;
    "python3.11")
        build_python_layer 3.11 arm64
        publish_python_layer 3.11 arm64
        publish_docker_ecr $PY311_DIST_ARM64 python3.11 arm64
        build_python_layer 3.11 x86_64
        publish_python_layer 3.11 x86_64
        publish_docker_ecr $PY311_DIST_X86_64 python3.11 x86_64
        ;;
    "python3.12")
        build_python_layer 3.12 arm64
        publish_python_layer 3.12 arm64
        publish_docker_ecr $PY312_DIST_ARM64 python3.12 arm64
        build_python_layer 3.12 x86_64
        publish_python_layer 3.12 x86_64
        publish_docker_ecr $PY312_DIST_X86_64 python3.12 x86_64
        ;;
    "python3.13")
        build_python_layer 3.13 arm64
        publish_python_layer 3.13 arm64
        publish_docker_ecr $PY313_DIST_ARM64 python3.13 arm64
        build_python_layer 3.13 x86_64
        publish_python_layer 3.13 x86_64
        publish_docker_ecr $PY313_DIST_X86_64 python3.13 x86_64
        ;;
    *)
        usage
        ;;
esac
