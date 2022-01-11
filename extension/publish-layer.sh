#!/usr/bin/env bash

set -Eeuo pipefail

BUCKET_PREFIX=nr-layers

EXTENSION_DIST_URL_ARM64=https://github.com/newrelic/newrelic-lambda-extension/releases/download/v2.0.6/newrelic-lambda-extension.arm64.zip
EXTENSION_DIST_URL_X86_64=https://github.com/newrelic/newrelic-lambda-extension/releases/download/v2.0.6/newrelic-lambda-extension.x86_64.zip

EXTENSION_DIST_ZIP_ARM64=extension.arm64.zip
EXTENSION_DIST_ZIP_X86_64=extension.x86_64.zip

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
	af-south-1
	ap-northeast-2
	ap-northeast-3
	ca-central-1
	eu-north-1
	eu-south-1
	eu-west-3
	me-south-1
	sa-east-1
	us-west-1
)

function build-layer-x86 {
    echo "Building New Relic Lambda Extension Layer (x86_64)"
    rm -f $EXTENSION_DIST_ZIP_X86_64

    curl -L $EXTENSION_DIST_URL_X86_64 -o $EXTENSION_DIST_ZIP_X86_64
    echo "Build complete: ${EXTENSION_DIST_ZIP_X86_64}"
}

function build-layer-arm64 {
    echo "Building New Relic Lambda Extension Layer (arm64)"
    rm -f $EXTENSION_DIST_ZIP_ARM64

    curl -L $EXTENSION_DIST_URL_ARM64 -o $EXTENSION_DIST_ZIP_ARM64

    echo "Build complete: ${EXTENSION_DIST_ZIP_ARM64}"
}

function publish-layer-x86 {
    if [ ! -f $EXTENSION_DIST_ZIP_X86_64 ]; then
        echo "Package not found: ${EXTENSION_DIST_ZIP_X86_64}"
        exit 1
    fi

    layer_hash=$(md5sum $EXTENSION_DIST_ZIP_X86_64 | awk '{ print $1 }')
    layer_s3key="nr-extension/${layer_hash}.x86_64.zip"

    for region in "${REGIONS_ARCH[@]}"; do
        bucket_name="${BUCKET_PREFIX}-${region}"

        echo "Uploading ${EXTENSION_DIST_ZIP_X86_64} to s3://${bucket_name}/${layer_s3key}"
        aws --region $region s3 cp $EXTENSION_DIST_ZIP_X86_64 "s3://${bucket_name}/${layer_s3key}"

        echo "Publishing extension layer to ${region}"
        layer_version=$(aws lambda publish-layer-version \
            --layer-name NewRelicLambdaExtension \
            --content "S3Bucket=${bucket_name},S3Key=${layer_s3key}" \
            --description "New Relic Lambda Extension Layer (x86_64)" \
            --license-info "Apache-2.0" \
            --compatible-runtimes "dotnetcore3.1" "provided" "provided.al2" \
            --compatible-architectures "x86_64" \
            --region $region \
            --output text \
            --query Version)
        echo "Published layer version ${layer_version} to ${region}"

        echo "Setting public permissions for layer version ${layer_version} in ${region}"
        aws lambda add-layer-version-permission \
          --layer-name NewRelicLambdaExtension \
          --version-number $layer_version \
          --statement-id public \
          --action lambda:GetLayerVersion \
          --principal "*" \
          --region $region
        echo "Public permissions set for layer version ${layer_version} in region ${region}"
    done

    # TODO: Remove this once all regions support --compatible-architectures
    for region in "${REGIONS_NO_ARCH[@]}"; do
        bucket_name="${BUCKET_PREFIX}-${region}"

        echo "Uploading ${EXTENSION_DIST_ZIP_X86_64} to s3://${bucket_name}/${layer_s3key}"
        aws --region $region s3 cp $EXTENSION_DIST_ZIP_X86_64 "s3://${bucket_name}/${layer_s3key}"

        echo "Publishing extension layer to ${region}"
        layer_version=$(aws lambda publish-layer-version \
            --layer-name NewRelicLambdaExtension \
            --content "S3Bucket=${bucket_name},S3Key=${layer_s3key}" \
            --description "New Relic Lambda Extension Layer (x86_64)" \
            --license-info "Apache-2.0" \
            --compatible-runtimes "dotnetcore3.1" "provided" "provided.al2" \
            --region $region \
            --output text \
            --query Version)
        echo "Published layer version ${layer_version} to ${region}"

        echo "Setting public permissions for layer version ${layer_version} in ${region}"
        aws lambda add-layer-version-permission \
          --layer-name NewRelicLambdaExtension \
          --version-number $layer_version \
          --statement-id public \
          --action lambda:GetLayerVersion \
          --principal "*" \
          --region $region
        echo "Public permissions set for layer version ${layer_version} in region ${region}"
    done
}

function publish-layer-arm64 {
    if [ ! -f $EXTENSION_DIST_ZIP_ARM64 ]; then
        echo "Package not found: ${EXTENSION_DIST_ZIP_ARM64}"
        exit 1
    fi

    layer_hash=$(md5sum $EXTENSION_DIST_ZIP_ARM64 | awk '{ print $1 }')
    layer_s3key="nr-extension/${layer_hash}.arm64.zip"

    for region in "${REGIONS_ARCH[@]}"; do
        bucket_name="${BUCKET_PREFIX}-${region}"

        echo "Uploading ${EXTENSION_DIST_ZIP_ARM64} to s3://${bucket_name}/${layer_s3key}"
        aws --region $region s3 cp $EXTENSION_DIST_ZIP_ARM64 "s3://${bucket_name}/${layer_s3key}"

        echo "Publishing extension layer to ${region}"
        layer_version=$(aws lambda publish-layer-version \
            --layer-name NewRelicLambdaExtensionARM64 \
            --content "S3Bucket=${bucket_name},S3Key=${layer_s3key}" \
            --description "New Relic Lambda Extension Layer (arm64)" \
            --license-info "Apache-2.0" \
            --compatible-runtimes "dotnetcore3.1" "provided" "provided.al2" \
            --compatible-architectures "arm64" \
            --region $region \
            --output text \
            --query Version)
        echo "Published layer version ${layer_version} to ${region}"

        echo "Setting public permissions for layer version ${layer_version} in ${region}"
        aws lambda add-layer-version-permission \
          --layer-name NewRelicLambdaExtensionARM64 \
          --version-number $layer_version \
          --statement-id public \
          --action lambda:GetLayerVersion \
          --principal "*" \
          --region $region
        echo "Public permissions set for layer version ${layer_version} in region ${region}"
    done
}

build-layer-x86
publish-layer-x86

build-layer-arm64
publish-layer-arm64
