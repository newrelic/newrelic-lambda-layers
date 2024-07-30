#!/usr/bin/env bash

set -Eeuo pipefail

BUILD_DIR=python
DIST_DIR=dist

PY38_DIST_ARM64=$DIST_DIR/python38.arm64.zip
PY39_DIST_ARM64=$DIST_DIR/python39.arm64.zip
PY310_DIST_ARM64=$DIST_DIR/python310.arm64.zip
PY311_DIST_ARM64=$DIST_DIR/python311.arm64.zip
PY312_DIST_ARM64=$DIST_DIR/python312.arm64.zip

PY38_DIST_X86_64=$DIST_DIR/python38.x86_64.zip
PY39_DIST_X86_64=$DIST_DIR/python39.x86_64.zip
PY310_DIST_X86_64=$DIST_DIR/python310.x86_64.zip
PY311_DIST_X86_64=$DIST_DIR/python311.x86_64.zip
PY312_DIST_X86_64=$DIST_DIR/python312.x86_64.zip


source ../libBuild.sh

function usage {
    echo "./publish-layers.sh [python3.8|python3.9|python3.10|python3.11|python3.12]"
}


function build-python38-arm64 {
    echo "Building New Relic layer for python3.8 (arm64)"
    rm -rf $BUILD_DIR $PY38_DIST_ARM64
    mkdir -p $DIST_DIR
    pip install --no-cache-dir -qU newrelic -t $BUILD_DIR/lib/python3.8/site-packages
    cp newrelic_lambda_wrapper.py $BUILD_DIR/lib/python3.8/site-packages/newrelic_lambda_wrapper.py
    cp -r newrelic_lambda $BUILD_DIR/lib/python3.8/site-packages/newrelic_lambda
    find $BUILD_DIR -name '__pycache__' -exec rm -rf {} +
    download_extension arm64
    zip -rq $PY38_DIST_ARM64 $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    echo "Build complete: ${PY38_DIST_ARM64}"
}

function build-python38-x86 {
    echo "Building New Relic layer for python3.8 (x86_64)"
    rm -rf $BUILD_DIR $PY38_DIST_X86_64
    mkdir -p $DIST_DIR
    pip install --no-cache-dir -qU newrelic -t $BUILD_DIR/lib/python3.8/site-packages
    cp newrelic_lambda_wrapper.py $BUILD_DIR/lib/python3.8/site-packages/newrelic_lambda_wrapper.py
    cp -r newrelic_lambda $BUILD_DIR/lib/python3.8/site-packages/newrelic_lambda
    find $BUILD_DIR -name '__pycache__' -exec rm -rf {} +
    download_extension x86_64
    zip -rq $PY38_DIST_X86_64 $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    echo "Build complete: ${PY38_DIST_X86_64}"
}

function publish-python38-arm64 {
    if [ ! -f $PY38_DIST_ARM64 ]; then
        echo "Package not found: ${PY38_DIST_ARM64}"
        exit 1
    fi

    for region in "${REGIONS_ARM[@]}"; do
      publish_layer $PY38_DIST_ARM64 $region python3.8 arm64
    done
}

function publish-python38-x86 {
    if [ ! -f $PY38_DIST_X86_64 ]; then
        echo "Package not found: ${PY38_DIST_X86_64}"
        exit 1
    fi

    for region in "${REGIONS_X86[@]}"; do
      publish_layer $PY38_DIST_X86_64 $region python3.8 x86_64
    done
}

function build-python39-arm64 {
    echo "Building New Relic layer for python3.9 (arm64)"
    rm -rf $BUILD_DIR $PY39_DIST_ARM64
    mkdir -p $DIST_DIR
    pip install --no-cache-dir -qU newrelic -t $BUILD_DIR/lib/python3.9/site-packages
    cp newrelic_lambda_wrapper.py $BUILD_DIR/lib/python3.9/site-packages/newrelic_lambda_wrapper.py
    cp -r newrelic_lambda $BUILD_DIR/lib/python3.9/site-packages/newrelic_lambda
    find $BUILD_DIR -name '__pycache__' -exec rm -rf {} +
    download_extension arm64
    zip -rq $PY39_DIST_ARM64 $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    echo "Build complete: ${PY39_DIST_ARM64}"
}

function build-python39-x86 {
    echo "Building New Relic layer for python3.9 (x86_64)"
    rm -rf $BUILD_DIR $PY39_DIST_X86_64
    mkdir -p $DIST_DIR
    pip install --no-cache-dir -qU newrelic -t $BUILD_DIR/lib/python3.9/site-packages
    cp newrelic_lambda_wrapper.py $BUILD_DIR/lib/python3.9/site-packages/newrelic_lambda_wrapper.py
    cp -r newrelic_lambda $BUILD_DIR/lib/python3.9/site-packages/newrelic_lambda
    find $BUILD_DIR -name '__pycache__' -exec rm -rf {} +
    download_extension x86_64
    zip -rq $PY39_DIST_X86_64 $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    echo "Build complete: ${PY39_DIST_X86_64}"
}

function publish-python39-arm64 {
    if [ ! -f $PY39_DIST_ARM64 ]; then
        echo "Package not found: ${PY39_DIST_ARM64}"
        exit 1
    fi

    for region in "${REGIONS_ARM[@]}"; do
      publish_layer $PY39_DIST_ARM64 $region python3.9 arm64
    done
}

function publish-python39-x86 {
    if [ ! -f $PY39_DIST_X86_64 ]; then
        echo "Package not found: ${PY39_DIST_X86_64}"
        exit 1
    fi

    for region in "${REGIONS_X86[@]}"; do
      publish_layer $PY39_DIST_X86_64 $region python3.9 x86_64
    done
}

function build-python310-arm64 {
    echo "Building New Relic layer for python3.10 (arm64)"
    rm -rf $BUILD_DIR $PY310_DIST_ARM64
    mkdir -p $DIST_DIR
    pip install --no-cache-dir -qU newrelic -t $BUILD_DIR/lib/python3.10/site-packages
    cp newrelic_lambda_wrapper.py $BUILD_DIR/lib/python3.10/site-packages/newrelic_lambda_wrapper.py
    cp -r newrelic_lambda $BUILD_DIR/lib/python3.10/site-packages/newrelic_lambda
    find $BUILD_DIR -name '__pycache__' -exec rm -rf {} +
    download_extension arm64
    zip -rq $PY310_DIST_ARM64 $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    echo "Build complete: ${PY310_DIST_ARM64}"
}

function build-python310-x86 {
    echo "Building New Relic layer for python3.10 (x86_64)"
    rm -rf $BUILD_DIR $PY310_DIST_X86_64
    mkdir -p $DIST_DIR
    pip install --no-cache-dir -qU newrelic -t $BUILD_DIR/lib/python3.10/site-packages
    cp newrelic_lambda_wrapper.py $BUILD_DIR/lib/python3.10/site-packages/newrelic_lambda_wrapper.py
    cp -r newrelic_lambda $BUILD_DIR/lib/python3.10/site-packages/newrelic_lambda
    find $BUILD_DIR -name '__pycache__' -exec rm -rf {} +
    download_extension x86_64
    zip -rq $PY310_DIST_X86_64 $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    echo "Build complete: ${PY310_DIST_X86_64}"
}

function publish-python310-arm64 {
    if [ ! -f $PY310_DIST_ARM64 ]; then
        echo "Package not found: ${PY310_DIST_ARM64}"
        exit 1
    fi

    for region in "${REGIONS_ARM[@]}"; do
      publish_layer $PY310_DIST_ARM64 $region python3.10 arm64
    done
}

function publish-python310-x86 {
    if [ ! -f $PY310_DIST_X86_64 ]; then
        echo "Package not found: ${PY310_DIST_X86_64}"
        exit 1
    fi

    for region in "${REGIONS_X86[@]}"; do
      publish_layer $PY310_DIST_X86_64 $region python3.10 x86_64
    done
}

function build-python311-arm64 {
    echo "Building New Relic layer for python3.11 (arm64)"
    rm -rf $BUILD_DIR $PY311_DIST_ARM64
    mkdir -p $DIST_DIR
    pip install --no-cache-dir -qU newrelic -t $BUILD_DIR/lib/python3.11/site-packages
    cp newrelic_lambda_wrapper.py $BUILD_DIR/lib/python3.11/site-packages/newrelic_lambda_wrapper.py
    cp -r newrelic_lambda $BUILD_DIR/lib/python3.11/site-packages/newrelic_lambda
    find $BUILD_DIR -name '__pycache__' -exec rm -rf {} +
    download_extension arm64
    zip -rq $PY311_DIST_ARM64 $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    echo "Build complete: ${PY311_DIST_ARM64}"
}

function build-python311-x86 {
    echo "Building New Relic layer for python3.11 (x86_64)"
    rm -rf $BUILD_DIR $PY311_DIST_X86_64
    mkdir -p $DIST_DIR
    pip install --no-cache-dir -qU newrelic -t $BUILD_DIR/lib/python3.11/site-packages
    cp newrelic_lambda_wrapper.py $BUILD_DIR/lib/python3.11/site-packages/newrelic_lambda_wrapper.py
    cp -r newrelic_lambda $BUILD_DIR/lib/python3.11/site-packages/newrelic_lambda
    find $BUILD_DIR -name '__pycache__' -exec rm -rf {} +
    download_extension x86_64
    zip -rq $PY311_DIST_X86_64 $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    echo "Build complete: ${PY311_DIST_X86_64}"
}

function publish-python311-arm64 {
    if [ ! -f $PY311_DIST_ARM64 ]; then
        echo "Package not found: ${PY311_DIST_ARM64}"
        exit 1
    fi

    for region in "${REGIONS_ARM[@]}"; do
      publish_layer $PY311_DIST_ARM64 $region python3.11 arm64
    done
}

function publish-python311-x86 {
    if [ ! -f $PY311_DIST_X86_64 ]; then
        echo "Package not found: ${PY311_DIST_X86_64}"
        exit 1
    fi

    for region in "${REGIONS_X86[@]}"; do
      publish_layer $PY311_DIST_X86_64 $region python3.11 x86_64
    done
}

function build-python312-arm64 {
    echo "Building New Relic layer for python3.12 (arm64)"
    rm -rf $BUILD_DIR $PY312_DIST_ARM64
    mkdir -p $DIST_DIR
    pip install --no-cache-dir -qU newrelic -t $BUILD_DIR/lib/python3.12/site-packages
    cp newrelic_lambda_wrapper.py $BUILD_DIR/lib/python3.12/site-packages/newrelic_lambda_wrapper.py
    cp -r newrelic_lambda $BUILD_DIR/lib/python3.12/site-packages/newrelic_lambda
    find $BUILD_DIR -name '__pycache__' -exec rm -rf {} +
    download_extension arm64
    zip -rq $PY312_DIST_ARM64 $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    echo "Build complete: ${PY312_DIST_ARM64}"
}

function build-python312-x86 {
    echo "Building New Relic layer for python3.12 (x86_64)"
    rm -rf $BUILD_DIR $PY312_DIST_X86_64
    mkdir -p $DIST_DIR
    pip install --no-cache-dir -qU newrelic -t $BUILD_DIR/lib/python3.12/site-packages
    cp newrelic_lambda_wrapper.py $BUILD_DIR/lib/python3.12/site-packages/newrelic_lambda_wrapper.py
    cp -r newrelic_lambda $BUILD_DIR/lib/python3.12/site-packages/newrelic_lambda
    find $BUILD_DIR -name '__pycache__' -exec rm -rf {} +
    download_extension x86_64
    zip -rq $PY312_DIST_X86_64 $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    echo "Build complete: ${PY312_DIST_X86_64}"
}

function publish-python312-arm64 {
    if [ ! -f $PY312_DIST_ARM64 ]; then
        echo "Package not found: ${PY312_DIST_ARM64}"
        exit 1
    fi

    for region in "${REGIONS_ARM[@]}"; do
      publish_layer $PY312_DIST_ARM64 $region python3.12 arm64
    done
}

function publish-python312-x86 {
    if [ ! -f $PY312_DIST_X86_64 ]; then
        echo "Package not found: ${PY312_DIST_X86_64}"
        exit 1
    fi

    for region in "${REGIONS_X86[@]}"; do
      publish_layer $PY312_DIST_X86_64 $region python3.12 x86_64
    done
}

case "$1" in
    "python3.8")
        build-python38-arm64
        publish-python38-arm64
        publish_docker_ecr $PY38_DIST_ARM64 python3.8 arm64
        build-python38-x86
        publish-python38-x86
        publish_docker_ecr $PY38_DIST_X86_64 python3.8 x86_64
        ;;
    "python3.9")
        build-python39-arm64
        publish-python39-arm64
        publish_docker_ecr $PY39_DIST_ARM64 python3.9 arm64
        build-python39-x86
        publish-python39-x86
        publish_docker_ecr $PY39_DIST_X86_64 python3.9 x86_64
        ;;
    "python3.10")
        build-python310-arm64
        publish-python310-arm64
        publish_docker_ecr $PY310_DIST_ARM64 python3.10 arm64
        build-python310-x86
        publish-python310-x86
        publish_docker_ecr $PY310_DIST_X86_64 python3.10 x86_64
        ;;
    "python3.11")
        build-python311-arm64
        publish-python311-arm64
        publish_docker_ecr $PY311_DIST_ARM64 python3.11 arm64
        build-python311-x86
        publish-python311-x86
        publish_docker_ecr $PY311_DIST_X86_64 python3.11 x86_64
        ;;
    "python3.12")
        build-python312-arm64
        publish-python312-arm64
        publish_docker_ecr $PY312_DIST_ARM64 python3.12 arm64
        build-python312-x86
        publish-python312-x86
        publish_docker_ecr $PY312_DIST_X86_64 python3.12 x86_64
        ;;
    *)
        usage
        ;;
esac
