#!/usr/bin/env bash

set -Eeuo pipefail

BUILD_DIR=python
BUCKET_PREFIX=nr-layers
DIST_DIR=dist

PY38_DIST_ARM64=$DIST_DIR/python38.arm64.zip
PY39_DIST_ARM64=$DIST_DIR/python39.arm64.zip

PY36_DIST_X86_64=$DIST_DIR/python36.x86_64.zip
PY37_DIST_X86_64=$DIST_DIR/python37.x86_64.zip
PY38_DIST_X86_64=$DIST_DIR/python38.x86_64.zip
PY39_DIST_X86_64=$DIST_DIR/python39.x86_64.zip

EXTENSION_DIST_DIR=extensions
EXTENSION_DIST_URL_ARM64=https://github.com/newrelic/newrelic-lambda-extension/releases/download/v2.0.5/newrelic-lambda-extension.arm64.zip
EXTENSION_DIST_URL_X86_64=https://github.com/newrelic/newrelic-lambda-extension/releases/download/v2.0.5/newrelic-lambda-extension.x86_64.zip
EXTENSION_DIST_ZIP=extension.zip
EXTENSION_DIST_PREVIEW_FILE=preview-extensions-ggqizro707

# Regions that support arm64 architecture
REGIONS_ARCH=(
  ap-northeast-1
  ap-south-1
  ap-southeast-1
  ap-southeast-2
  eu-central-1
  eu-west-1
  eu-west-2
  us-east-1
  us-east-2
  us-west-2
)

# Regions that don't yet support arm64 architecture
REGIONS_NO_ARCH=(
  ap-northeast-2
  ca-central-1
  eu-north-1
  eu-west-3
  sa-east-1
  us-west-1
)


function usage {
    echo "./publish-layers.sh [python3.6|python3.7|python3.8|python3.9]"
}

function download-extension-arm64 {
    rm -rf $EXTENSION_DIST_DIR $EXTENSION_DIST_ZIP
    curl -L $EXTENSION_DIST_URL_ARM64 -o $EXTENSION_DIST_ZIP
    unzip $EXTENSION_DIST_ZIP -d .
    rm -f $EXTENSION_DIST_ZIP
}

function download-extension-x86 {
    rm -rf $EXTENSION_DIST_DIR $EXTENSION_DIST_ZIP
    curl -L $EXTENSION_DIST_URL_X86_64 -o $EXTENSION_DIST_ZIP
    unzip $EXTENSION_DIST_ZIP -d .
    rm -f $EXTENSION_DIST_ZIP
}

function build-python36-x86 {
echo "Building New Relic layer for python3.6 (x86_64)"
    rm -rf $BUILD_DIR $PY36_DIST_X86_64
    mkdir -p $DIST_DIR
    pip install --no-cache-dir -qU newrelic newrelic-lambda -t $BUILD_DIR/lib/python3.6/site-packages
    cp newrelic_lambda_wrapper.py $BUILD_DIR/lib/python3.6/site-packages/newrelic_lambda_wrapper.py
    find $BUILD_DIR -name '__pycache__' -exec rm -rf {} +
    download-extension-x86
    zip -rq $PY36_DIST_X86_64 $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    echo "Build complete: ${PY36_DIST_X86_64}"
}

function publish-python36-x86 {
    if [ ! -f $PY36_DIST_X86_64 ]; then
        echo "Package not found: ${PY36_DIST_X86_64}"
        exit 1
    fi

    py36_hash=$(md5sum $PY36_DIST_X86_64 | awk '{ print $1 }')
    py36_s3key="nr-python3.6/${py36_hash}.x86_64.zip"

    for region in "${REGIONS_ARCH[@]}"; do
        bucket_name="${BUCKET_PREFIX}-${region}"

        echo "Uploading ${PY36_DIST_X86_64} to s3://${bucket_name}/${py36_s3key}"
        aws --region $region s3 cp $PY36_DIST_X86_64 "s3://${bucket_name}/${py36_s3key}"

        echo "Publishing python3.6 layer to ${region}"
        py36_version=$(aws lambda publish-layer-version \
            --layer-name NewRelicPython36 \
            --content "S3Bucket=${bucket_name},S3Key=${py36_s3key}" \
            --description "New Relic Layer for Python 3.6 (x86_64)" \
            --license-info "Apache-2.0" \
            --compatible-runtimes python3.6 \
            --compatible-architectures "x86_64" \
            --region $region \
            --output text \
            --query Version)
        echo "published python3.6 layer version ${py36_version} to ${region}"

        echo "Setting public permissions for python3.6 layer version ${py36_version} in ${region}"
        aws lambda add-layer-version-permission \
          --layer-name NewRelicPython36 \
          --version-number $py36_version \
          --statement-id public \
          --action lambda:GetLayerVersion \
          --principal "*" \
          --region $region
        echo "Public permissions set for python3.6 layer version ${py36_version} in region ${region}"
    done

    # TODO: Remove once all regions support --comptaible-architectures
    for region in "${REGIONS_NO_ARCH[@]}"; do
        bucket_name="${BUCKET_PREFIX}-${region}"

        echo "Uploading ${PY36_DIST_X86_64} to s3://${bucket_name}/${py36_s3key}"
        aws --region $region s3 cp $PY36_DIST_X86_64 "s3://${bucket_name}/${py36_s3key}"

        echo "Publishing python3.6 layer to ${region}"
        py36_version=$(aws lambda publish-layer-version \
            --layer-name NewRelicPython36 \
            --content "S3Bucket=${bucket_name},S3Key=${py36_s3key}" \
            --description "New Relic Layer for Python 3.6 (x86_64)" \
            --license-info "Apache-2.0" \
            --compatible-runtimes python3.6 \
            --region $region \
            --output text \
            --query Version)
        echo "published python3.6 layer version ${py36_version} to ${region}"

        echo "Setting public permissions for python3.6 layer version ${py36_version} in ${region}"
        aws lambda add-layer-version-permission \
          --layer-name NewRelicPython36 \
          --version-number $py36_version \
          --statement-id public \
          --action lambda:GetLayerVersion \
          --principal "*" \
          --region $region
        echo "Public permissions set for python3.6 layer version ${py36_version} in region ${region}"
    done
}

function build-python37-x86 {
echo "Building New Relic layer for python3.7 (x86_64)"
    rm -rf $BUILD_DIR $PY37_DIST_X86_64
    mkdir -p $DIST_DIR
    pip install --no-cache-dir -qU newrelic newrelic-lambda -t $BUILD_DIR/lib/python3.7/site-packages
    cp newrelic_lambda_wrapper.py $BUILD_DIR/lib/python3.7/site-packages/newrelic_lambda_wrapper.py
    find $BUILD_DIR -name '__pycache__' -exec rm -rf {} +
    download-extension-x86
    zip -rq $PY37_DIST_X86_64 $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    echo "Build complete: ${PY37_DIST_X86_64}"
}

function publish-python37-x86 {
    if [ ! -f $PY37_DIST_X86_64 ]; then
        echo "Package not found: ${PY37_DIST_X86_64}"
        exit 1
    fi

    py37_hash=$(md5sum $PY37_DIST_X86_64 | awk '{ print $1 }')
    py37_s3key="nr-python3.7/${py37_hash}.x86_64.zip"

    for region in "${REGIONS_ARCH[@]}"; do
        bucket_name="${BUCKET_PREFIX}-${region}"

        echo "Uploading ${PY37_DIST_X86_64} to s3://${bucket_name}/${py37_s3key}"
        aws --region $region s3 cp $PY37_DIST_X86_64 "s3://${bucket_name}/${py37_s3key}"

        echo "Publishing python3.7 layer to ${region}"
        py37_version=$(aws lambda publish-layer-version \
            --layer-name NewRelicPython37 \
            --content "S3Bucket=${bucket_name},S3Key=${py37_s3key}" \
            --description "New Relic Layer for Python 3.7 (x86_64)" \
            --license-info "Apache-2.0" \
            --compatible-runtimes python3.7 \
            --compatible-architectures "x86_64" \
            --region $region \
            --output text \
            --query Version)
        echo "published python3.7 layer version ${py37_version} to ${region}"

        echo "Setting public permissions for python3.7 layer version ${py37_version} in ${region}"
        aws lambda add-layer-version-permission \
          --layer-name NewRelicPython37 \
          --version-number $py37_version \
          --statement-id public \
          --action lambda:GetLayerVersion \
          --principal "*" \
          --region $region
        echo "Public permissions set for python3.7 layer version ${py37_version} in region ${region}"
    done

    # TODO: Remove once all regions support --compatible-architectures
    for region in "${REGIONS_NO_ARCH[@]}"; do
        bucket_name="${BUCKET_PREFIX}-${region}"

        echo "Uploading ${PY37_DIST_X86_64} to s3://${bucket_name}/${py37_s3key}"
        aws --region $region s3 cp $PY37_DIST_X86_64 "s3://${bucket_name}/${py37_s3key}"

        echo "Publishing python3.7 layer to ${region}"
        py37_version=$(aws lambda publish-layer-version \
            --layer-name NewRelicPython37 \
            --content "S3Bucket=${bucket_name},S3Key=${py37_s3key}" \
            --description "New Relic Layer for Python 3.7 (x86_64)" \
            --license-info "Apache-2.0" \
            --compatible-runtimes python3.7 \
            --region $region \
            --output text \
            --query Version)
        echo "published python3.7 layer version ${py37_version} to ${region}"

        echo "Setting public permissions for python3.7 layer version ${py37_version} in ${region}"
        aws lambda add-layer-version-permission \
          --layer-name NewRelicPython37 \
          --version-number $py37_version \
          --statement-id public \
          --action lambda:GetLayerVersion \
          --principal "*" \
          --region $region
        echo "Public permissions set for python3.7 layer version ${py37_version} in region ${region}"
    done
}

function build-python38-arm64 {
echo "Building New Relic layer for python3.8 (arm64)"
    rm -rf $BUILD_DIR $PY38_DIST_ARM64
    mkdir -p $DIST_DIR
    pip install --no-cache-dir -qU newrelic newrelic-lambda -t $BUILD_DIR/lib/python3.8/site-packages
    cp newrelic_lambda_wrapper.py $BUILD_DIR/lib/python3.8/site-packages/newrelic_lambda_wrapper.py
    find $BUILD_DIR -name '__pycache__' -exec rm -rf {} +
    download-extension-arm64
    zip -rq $PY38_DIST_ARM64 $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    echo "Build complete: ${PY38_DIST_ARM64}"
}

function build-python38-x86 {
echo "Building New Relic layer for python3.8 (x86_64)"
    rm -rf $BUILD_DIR $PY38_DIST_X86_64
    mkdir -p $DIST_DIR
    pip install --no-cache-dir -qU newrelic newrelic-lambda -t $BUILD_DIR/lib/python3.8/site-packages
    cp newrelic_lambda_wrapper.py $BUILD_DIR/lib/python3.8/site-packages/newrelic_lambda_wrapper.py
    find $BUILD_DIR -name '__pycache__' -exec rm -rf {} +
    download-extension-x86
    zip -rq $PY38_DIST_X86_64 $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    echo "Build complete: ${PY38_DIST_X86_64}"
}

function publish-python38-arm64 {
    if [ ! -f $PY38_DIST_ARM64 ]; then
        echo "Package not found: ${PY38_DIST_ARM64}"
        exit 1
    fi

    py38_hash=$(md5sum $PY38_DIST_ARM64 | awk '{ print $1 }')
    py38_s3key="nr-python3.8/${py38_hash}.arm64.zip"

    for region in "${REGIONS_ARCH[@]}"; do
        bucket_name="${BUCKET_PREFIX}-${region}"

        echo "Uploading ${PY38_DIST_ARM64} to s3://${bucket_name}/${py38_s3key}"
        aws --region $region s3 cp $PY38_DIST_ARM64 "s3://${bucket_name}/${py38_s3key}"

        echo "Publishing python3.8 layer to ${region}"
        py38_version=$(aws lambda publish-layer-version \
            --layer-name NewRelicPython38ARM64 \
            --content "S3Bucket=${bucket_name},S3Key=${py38_s3key}" \
            --description "New Relic Layer for Python 3.8" \
            --license-info "Apache-2.0" \
            --compatible-runtimes python3.8 \
            --compatible-architectures "arm64" \
            --region $region \
            --output text \
            --query Version)
        echo "published python3.8 layer version ${py38_version} to ${region}"

        echo "Setting public permissions for python3.8 layer version ${py38_version} in ${region}"
        aws lambda add-layer-version-permission \
          --layer-name NewRelicPython38ARM64 \
          --version-number $py38_version \
          --statement-id public \
          --action lambda:GetLayerVersion \
          --principal "*" \
          --region $region
        echo "Public permissions set for python3.8 layer version ${py38_version} in region ${region}"
    done
}

function publish-python38-x86 {
    if [ ! -f $PY38_DIST_X86_64 ]; then
        echo "Package not found: ${PY38_DIST_X86_64}"
        exit 1
    fi

    py38_hash=$(md5sum $PY38_DIST_X86_64 | awk '{ print $1 }')
    py38_s3key="nr-python3.8/${py38_hash}.x86_64.zip"

    for region in "${REGIONS_ARCH[@]}"; do
        bucket_name="${BUCKET_PREFIX}-${region}"

        echo "Uploading ${PY38_DIST_X86_64} to s3://${bucket_name}/${py38_s3key}"
        aws --region $region s3 cp $PY38_DIST_X86_64 "s3://${bucket_name}/${py38_s3key}"

        echo "Publishing python3.8 layer to ${region}"
        py38_version=$(aws lambda publish-layer-version \
            --layer-name NewRelicPython38 \
            --content "S3Bucket=${bucket_name},S3Key=${py38_s3key}" \
            --description "New Relic Layer for Python 3.8 (x86_64)" \
            --license-info "Apache-2.0" \
            --compatible-runtimes python3.8 \
            --compatible-architectures "x86_64" \
            --region $region \
            --output text \
            --query Version)
        echo "published python3.8 layer version ${py38_version} to ${region}"

        echo "Setting public permissions for python3.8 layer version ${py38_version} in ${region}"
        aws lambda add-layer-version-permission \
          --layer-name NewRelicPython38 \
          --version-number $py38_version \
          --statement-id public \
          --action lambda:GetLayerVersion \
          --principal "*" \
          --region $region
        echo "Public permissions set for python3.8 layer version ${py38_version} in region ${region}"
    done
}

function build-python39-arm64 {
echo "Building New Relic layer for python3.9 (arm64)"
    rm -rf $BUILD_DIR $PY39_DIST_ARM64
    mkdir -p $DIST_DIR
    pip install --no-cache-dir -qU newrelic newrelic-lambda -t $BUILD_DIR/lib/python3.9/site-packages
    cp newrelic_lambda_wrapper.py $BUILD_DIR/lib/python3.9/site-packages/newrelic_lambda_wrapper.py
    find $BUILD_DIR -name '__pycache__' -exec rm -rf {} +
    download-extension-arm64
    zip -rq $PY39_DIST_ARM64 $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    echo "Build complete: ${PY39_DIST_ARM64}"
}

function build-python39-x86 {
    echo "Building New Relic layer for python3.9 (x86_64)"
    rm -rf $BUILD_DIR $PY39_DIST_X86_64
    mkdir -p $DIST_DIR
    pip install --no-cache-dir -qU newrelic newrelic-lambda -t $BUILD_DIR/lib/python3.9/site-packages
    cp newrelic_lambda_wrapper.py $BUILD_DIR/lib/python3.9/site-packages/newrelic_lambda_wrapper.py
    find $BUILD_DIR -name '__pycache__' -exec rm -rf {} +
    download-extension-x86
    zip -rq $PY39_DIST_X86_64 $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    echo "Build complete: ${PY39_DIST_X86_64}"
}

function publish-python39-arm64 {
    if [ ! -f $PY39_DIST_ARM64 ]; then
        echo "Package not found: ${PY39_DIST_ARM64}"
        exit 1
    fi

    py39_hash=$(md5sum $PY39_DIST_ARM64 | awk '{ print $1 }')
    py39_s3key="nr-python3.9/${py39_hash}.arm64.zip"

    for region in "${REGIONS_ARCH[@]}"; do
        bucket_name="${BUCKET_PREFIX}-${region}"

        echo "Uploading ${PY39_DIST_ARM64} to s3://${bucket_name}/${py39_s3key}"
        aws --region $region s3 cp $PY39_DIST_ARM64 "s3://${bucket_name}/${py39_s3key}"

        echo "Publishing python3.9 layer to ${region}"
        py39_version=$(aws lambda publish-layer-version \
            --layer-name NewRelicPython39ARM64 \
            --content "S3Bucket=${bucket_name},S3Key=${py39_s3key}" \
            --description "New Relic Layer for Python 3.9 (arm64)" \
            --license-info "Apache-2.0" \
            --compatible-runtimes python3.9 \
            --compatible-architectures "arm64" \
            --region $region \
            --output text \
            --query Version)
        echo "published python3.9 layer version ${py39_version} to ${region}"

        echo "Setting public permissions for python3.9 layer version ${py39_version} in ${region}"
        aws lambda add-layer-version-permission \
          --layer-name NewRelicPython39ARM64 \
          --version-number $py39_version \
          --statement-id public \
          --action lambda:GetLayerVersion \
          --principal "*" \
          --region $region
        echo "Public permissions set for python3.9 layer version ${py39_version} in region ${region}"
    done
}

function publish-python39-x86 {
    if [ ! -f $PY39_DIST_X86_64 ]; then
        echo "Package not found: ${PY39_DIST_X86_64}"
        exit 1
    fi

    py39_hash=$(md5sum $PY39_DIST_X86_64 | awk '{ print $1 }')
    py39_s3key="nr-python3.9/${py39_hash}.x86_64.zip"

    for region in "${REGIONS_ARCH[@]}"; do
        bucket_name="${BUCKET_PREFIX}-${region}"

        echo "Uploading ${PY39_DIST_X86_64} to s3://${bucket_name}/${py39_s3key}"
        aws --region $region s3 cp $PY39_DIST_X86_64 "s3://${bucket_name}/${py39_s3key}"

        echo "Publishing python3.9 layer to ${region}"
        py39_version=$(aws lambda publish-layer-version \
            --layer-name NewRelicPython39 \
            --content "S3Bucket=${bucket_name},S3Key=${py39_s3key}" \
            --description "New Relic Layer for Python 3.9" \
            --license-info "Apache-2.0" \
            --compatible-runtimes python3.9 \
            --compatible-architectures "x86_64" \
            --region $region \
            --output text \
            --query Version)
        echo "published python3.9 layer version ${py39_version} to ${region}"

        echo "Setting public permissions for python3.9 layer version ${py39_version} in ${region}"
        aws lambda add-layer-version-permission \
          --layer-name NewRelicPython39 \
          --version-number $py39_version \
          --statement-id public \
          --action lambda:GetLayerVersion \
          --principal "*" \
          --region $region
        echo "Public permissions set for python3.9 layer version ${py39_version} in region ${region}"
    done

    # TODO: Remove when all regions support --compatible-architectures
    for region in "${REGIONS_NO_ARCH[@]}"; do
        bucket_name="${BUCKET_PREFIX}-${region}"

        echo "Uploading ${PY39_DIST_X86_64} to s3://${bucket_name}/${py39_s3key}"
        aws --region $region s3 cp $PY39_DIST_X86_64 "s3://${bucket_name}/${py39_s3key}"

        echo "Publishing python3.9 layer to ${region}"
        py39_version=$(aws lambda publish-layer-version \
            --layer-name NewRelicPython39 \
            --content "S3Bucket=${bucket_name},S3Key=${py39_s3key}" \
            --description "New Relic Layer for Python 3.9" \
            --license-info "Apache-2.0" \
            --compatible-runtimes python3.9 \
            --region $region \
            --output text \
            --query Version)
        echo "published python3.9 layer version ${py39_version} to ${region}"

        echo "Setting public permissions for python3.9 layer version ${py39_version} in ${region}"
        aws lambda add-layer-version-permission \
          --layer-name NewRelicPython39 \
          --version-number $py39_version \
          --statement-id public \
          --action lambda:GetLayerVersion \
          --principal "*" \
          --region $region
        echo "Public permissions set for python3.9 layer version ${py39_version} in region ${region}"
    done
}

case "$1" in
    "python3.6")
        build-python36-x86
        publish-python36-x86
        ;;
    "python3.7")
        build-python37-x86
        publish-python37-x86
        ;;
    "python3.8")
        build-python38-arm64
        publish-python38-arm64
        build-python38-x86
        publish-python38-x86
        ;;
    "python3.9")
        build-python39-arm64
        publish-python39-arm64
        build-python39-x86
        publish-python39-x86
        ;;
    *)
        usage
        ;;
esac
