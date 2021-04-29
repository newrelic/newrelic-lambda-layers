#!/usr/bin/env bash

set -Eeuo pipefail

BUCKET_PREFIX=nr-layers

EXTENSION_DIST_DIR=extensions
EXTENSION_DIST_URL=https://github.com/newrelic/newrelic-lambda-extension/releases/download/v1.2.4/newrelic-lambda-extension.zip
EXTENSION_DIST_ZIP=extension.zip

REGIONS=(
  ap-northeast-1
  ap-northeast-2
  ap-south-1
  ap-southeast-1
  ap-southeast-2
  ca-central-1
  eu-central-1
  eu-west-1
  eu-west-2
  eu-west-3
  sa-east-1
  us-east-1
  us-east-2
  us-west-1
  us-west-2
)

function build-layer {
    echo "Building New Relic Lambda Extension Layer"
    rm -rf $EXTENSION_DIST_DIR $EXTENSION_DIST_ZIP
    curl -L $EXTENSION_DIST_URL -o $EXTENSION_DIST_ZIP
    echo "Build complete: ${EXTENSION_DIST_ZIP}"
}

function publish-layer {
    if [ ! -f $EXTENSION_DIST_ZIP ]; then
        echo "Package not found: ${EXTENSION_DIST_ZIP}"
        exit 1
    fi

    layer_hash=$(md5sum $EXTENSION_DIST_ZIP | awk '{ print $1 }')
    layer_s3key="nr-extension/${layer_hash}.zip"

    for region in "${REGIONS[@]}"; do
        bucket_name="${BUCKET_PREFIX}-${region}"

        echo "Uploading ${EXTENSION_DIST_ZIP} to s3://${bucket_name}/${layer_s3key}"
        aws --region $region s3 cp $EXTENSION_DIST_ZIP "s3://${bucket_name}/${layer_s3key}"

        echo "Publishing extension layer to ${region}"
        layer_version=$(aws lambda publish-layer-version \
            --layer-name NewRelicLambdaExtension \
            --content "S3Bucket=${bucket_name},S3Key=${layer_s3key}" \
            --description "New Relic Lambda Extension Layer" \
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

build-layer
publish-layer
