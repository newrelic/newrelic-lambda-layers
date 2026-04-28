#!/usr/bin/env bash

set -Eeuo pipefail

BUILD_DIR=python
DIST_DIR=${DIST_DIR:-dist}
NEWRELIC_AGENT_VERSION=""
VERSION_REGEX="v?([0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+_python"
PY39_DIST_ARM64=$DIST_DIR/python39.arm64.zip
PY310_DIST_ARM64=$DIST_DIR/python310.arm64.zip
PY311_DIST_ARM64=$DIST_DIR/python311.arm64.zip
PY312_DIST_ARM64=$DIST_DIR/python312.arm64.zip
PY313_DIST_ARM64=$DIST_DIR/python313.arm64.zip
PY314_DIST_ARM64=$DIST_DIR/python314.arm64.zip
PY_DIST_ARM64=$DIST_DIR/python.arm64.zip

PY39_DIST_X86_64=$DIST_DIR/python39.x86_64.zip
PY310_DIST_X86_64=$DIST_DIR/python310.x86_64.zip
PY311_DIST_X86_64=$DIST_DIR/python311.x86_64.zip
PY312_DIST_X86_64=$DIST_DIR/python312.x86_64.zip
PY313_DIST_X86_64=$DIST_DIR/python313.x86_64.zip
PY314_DIST_X86_64=$DIST_DIR/python314.x86_64.zip
PY_DIST_X86_64=$DIST_DIR/python.x86_64.zip

source ../libBuild.sh

function usage {
    echo "./publish-layers.sh [python3.9|python3.10|python3.11|python3.12|python3.13|python3.14]"
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
        REGIONS=("${REGIONS[@]}");
    else
        REGIONS=("${REGIONS[@]}");
    fi

    run_region_loop "$ZIP" "python${python_version}" "${arch}" "$NEWRELIC_AGENT_VERSION"
}


function build_universal_python_layer {
    local arch=$1
    ZIP=$DIST_DIR/python.${arch}.zip
    echo "zip file: ${ZIP}"
    echo "Building universal New Relic layer for Python (${arch})"
    rm -rf $BUILD_DIR $ZIP
    mkdir -p $DIST_DIR

    # Determine agent version from git tag
    if [[ -z "${GITHUB_REF_NAME}" ]]; then
        echo "Unable to determine agent version, GITHUB_REF_NAME environment variable not set." >&2
        exit 1;
    elif [[ "${GITHUB_REF_NAME}" =~ ${VERSION_REGEX} ]]; then
        NEWRELIC_AGENT_VERSION="${BASH_REMATCH[1]}"
        echo "Detected NEWRELIC_AGENT_VERSION: ${NEWRELIC_AGENT_VERSION}"
    else
        echo "Unable to determine agent version, GITHUB_REF_NAME environment variable did not match regex. GITHUB_REF_NAME: ${GITHUB_REF_NAME}" >&2
        exit 1;
    fi

    # Modifying path as per https://docs.aws.amazon.com/lambda/latest/dg/packaging-layers.html
    pip install --no-cache-dir -qU "newrelic==${NEWRELIC_AGENT_VERSION}" newrelic-lambda -t $BUILD_DIR
    cp newrelic_lambda_wrapper.py "$BUILD_DIR/newrelic_lambda_wrapper.py"
    find $BUILD_DIR -name '__pycache__' -exec rm -rf {} +

    download_extension $arch
    zip -rq $ZIP $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE

    echo "Build complete: ${ZIP}"
}


function publish_universal_python_layer {
    local arch=$1
    ZIP=$DIST_DIR/python.${arch}.zip

    if [ ! -f ${ZIP} ]; then
        echo "Package not found: ${ZIP}"
        exit 1
    fi

    run_region_loop "$ZIP" python "${arch}" "$NEWRELIC_AGENT_VERSION"
}


case "$1" in
    "build-universal-python")
        build_universal_python_layer arm64
        build_universal_python_layer x86_64
        ;;
    "publish-universal-python")
        publish_universal_python_layer arm64
        publish_universal_python_layer x86_64
        ;;
    "build-publish-universal-python-ecr-image")
        build_universal_python_layer arm64
        publish_docker_ecr $PY_DIST_ARM64 python arm64
        build_universal_python_layer x86_64
        publish_docker_ecr $PY_DIST_X86_64 python x86_64
        ;;
    "python")
        layer_rc=0
        build_universal_python_layer arm64
        publish_universal_python_layer arm64 || layer_rc=$?
        publish_ecr_safe $PY_DIST_ARM64 python arm64
        build_universal_python_layer x86_64
        publish_universal_python_layer x86_64 || layer_rc=$?
        publish_ecr_safe $PY_DIST_X86_64 python x86_64
        finalize_ecr_results "python-universal"
        [[ $layer_rc -eq 0 ]] || exit $layer_rc
        ;;
    "python3.9")
        layer_rc=0
        build_python_layer 3.9 arm64
        publish_python_layer 3.9 arm64 || layer_rc=$?
        publish_ecr_safe $PY39_DIST_ARM64 python3.9 arm64
        build_python_layer 3.9 x86_64
        publish_python_layer 3.9 x86_64 || layer_rc=$?
        publish_ecr_safe $PY39_DIST_X86_64 python3.9 x86_64
        finalize_ecr_results "python3.9"
        [[ $layer_rc -eq 0 ]] || exit $layer_rc
        ;;
    "python3.10")
        layer_rc=0
        build_python_layer 3.10 arm64
        publish_python_layer 3.10 arm64 || layer_rc=$?
        publish_ecr_safe $PY310_DIST_ARM64 python3.10 arm64
        build_python_layer 3.10 x86_64
        publish_python_layer 3.10 x86_64 || layer_rc=$?
        publish_ecr_safe $PY310_DIST_X86_64 python3.10 x86_64
        finalize_ecr_results "python3.10"
        [[ $layer_rc -eq 0 ]] || exit $layer_rc
        ;;
    "python3.11")
        layer_rc=0
        build_python_layer 3.11 arm64
        publish_python_layer 3.11 arm64 || layer_rc=$?
        publish_ecr_safe $PY311_DIST_ARM64 python3.11 arm64
        build_python_layer 3.11 x86_64
        publish_python_layer 3.11 x86_64 || layer_rc=$?
        publish_ecr_safe $PY311_DIST_X86_64 python3.11 x86_64
        finalize_ecr_results "python3.11"
        [[ $layer_rc -eq 0 ]] || exit $layer_rc
        ;;
    "python3.12")
        layer_rc=0
        build_python_layer 3.12 arm64
        publish_python_layer 3.12 arm64 || layer_rc=$?
        publish_ecr_safe $PY312_DIST_ARM64 python3.12 arm64
        build_python_layer 3.12 x86_64
        publish_python_layer 3.12 x86_64 || layer_rc=$?
        publish_ecr_safe $PY312_DIST_X86_64 python3.12 x86_64
        finalize_ecr_results "python3.12"
        [[ $layer_rc -eq 0 ]] || exit $layer_rc
        ;;
    "python3.13")
        layer_rc=0
        build_python_layer 3.13 arm64
        publish_python_layer 3.13 arm64 || layer_rc=$?
        publish_ecr_safe $PY313_DIST_ARM64 python3.13 arm64
        build_python_layer 3.13 x86_64
        publish_python_layer 3.13 x86_64 || layer_rc=$?
        publish_ecr_safe $PY313_DIST_X86_64 python3.13 x86_64
        finalize_ecr_results "python3.13"
        [[ $layer_rc -eq 0 ]] || exit $layer_rc
        ;;
    "python3.14")
        layer_rc=0
        build_python_layer 3.14 arm64
        publish_python_layer 3.14 arm64 || layer_rc=$?
        publish_ecr_safe $PY314_DIST_ARM64 python3.14 arm64
        build_python_layer 3.14 x86_64
        publish_python_layer 3.14 x86_64 || layer_rc=$?
        publish_ecr_safe $PY314_DIST_X86_64 python3.14 x86_64
        finalize_ecr_results "python3.14"
        [[ $layer_rc -eq 0 ]] || exit $layer_rc
        ;;
    "publish-staging-python3.14")
        build_python_layer 3.14 arm64
        build_python_layer 3.14 x86_64
        arn_arm64=$(publish_staging_layer "$PY314_DIST_ARM64" python3.14 arm64 "$NEWRELIC_AGENT_VERSION")
        echo "arn_arm64=${arn_arm64}" >> "${GITHUB_OUTPUT:-/dev/stderr}"
        arn_x86=$(publish_staging_layer "$PY314_DIST_X86_64" python3.14 x86_64 "$NEWRELIC_AGENT_VERSION")
        echo "arn_x86=${arn_x86}" >> "${GITHUB_OUTPUT:-/dev/stderr}"
        ;;
    "cleanup-staging-python3.14")
        for arn in "${ARN_X86:-}" "${ARN_ARM64:-}"; do
            [[ -z "$arn" ]] && continue
            delete_staging_layer "$(echo "$arn" | cut -d: -f8)" "$(echo "$arn" | cut -d: -f9)"
        done
        ;;
    *)
        usage
        ;;
esac
