#!/usr/bin/env bash

set -Eeuo pipefail

BUILD_DIR=nodejs
BUCKET_PREFIX=nr-layers
DIST_DIR=dist
NJS12X_DIST=$DIST_DIR/nodejs12x.zip
NJS14X_DIST=$DIST_DIR/nodejs14x.zip

EXTENSION_DIST_DIR=extensions
EXTENSION_DIST_URL=https://github.com/newrelic/newrelic-lambda-extension/releases/download/v2.0.4/newrelic-lambda-extension.zip
EXTENSION_DIST_ZIP=extension.zip
EXTENSION_DIST_PREVIEW_FILE=preview-extensions-ggqizro707

REGIONS=(
  ap-northeast-1
  ap-northeast-2
  ap-south-1
  ap-southeast-1
  ap-southeast-2
  ca-central-1
  eu-central-1
  eu-north-1
  eu-west-1
  eu-west-2
  eu-west-3
  sa-east-1
  us-east-1
  us-east-2
  us-west-1
  us-west-2
)

function usage {
    echo "./publish-layers.sh [nodejs12.x|nodejs14.x]"
}

function download-extension {
    rm -rf $EXTENSION_DIST_DIR $EXTENSION_DIST_ZIP
    curl -L $EXTENSION_DIST_URL -o $EXTENSION_DIST_ZIP
    unzip $EXTENSION_DIST_ZIP -d .
    rm -f $EXTENSION_DIST_ZIP
}

function build-nodejs12x {
    echo "Building new relic layer for nodejs12.x"
    rm -rf $BUILD_DIR $NJS12X_DIST
    mkdir -p $DIST_DIR
    npm install --prefix $BUILD_DIR newrelic@latest @newrelic/aws-sdk@latest
    mkdir -p $BUILD_DIR/node_modules/newrelic-lambda-wrapper
    cp index.js $BUILD_DIR/node_modules/newrelic-lambda-wrapper
    download-extension
    zip -rq $NJS12X_DIST $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    echo "Build complete: ${NJS12X_DIST}"
}

function publish-nodejs12x {
    if [ ! -f $NJS12X_DIST ]; then
        echo "Package not found: ${NJS12X_DIST}"
        exit 1
    fi

    njs12x_hash=$(md5sum $NJS12X_DIST | awk '{ print $1 }')
    njs12x_s3key="nr-nodejs12.x/${njs12x_hash}.zip"

    for region in "${REGIONS[@]}"; do
        bucket_name="${BUCKET_PREFIX}-${region}"

        echo "Uploading ${NJS12X_DIST} to s3://${bucket_name}/${njs12x_s3key}"
        aws --region $region s3 cp $NJS12X_DIST "s3://${bucket_name}/${njs12x_s3key}"

        echo "Publishing nodejs12.x layer to ${region}"
        njs12x_version=$(aws lambda publish-layer-version \
            --layer-name NewRelicNodeJS12X \
            --content "S3Bucket=${bucket_name},S3Key=${njs12x_s3key}" \
            --description "New Relic Layer for Node.js 12.x" \
            --license-info "Apache-2.0" \
            --compatible-runtimes nodejs12.x \
            --region $region \
            --output text \
            --query Version)
        echo "published nodejs12.x layer version ${njs12x_version} to ${region}"

        echo "Setting public permissions for nodejs12.x layer version ${njs12x_version} in ${region}"
        aws lambda add-layer-version-permission \
          --layer-name NewRelicNodeJS12X \
          --version-number $njs12x_version \
          --statement-id public \
          --action lambda:GetLayerVersion \
          --principal "*" \
          --region $region
        echo "Public permissions set for nodejs12.x layer version ${njs12x_version} in region ${region}"
    done
}

function build-nodejs14x {
    echo "Building new relic layer for nodejs14.x"
    rm -rf $BUILD_DIR $NJS14X_DIST
    mkdir -p $DIST_DIR
    npm install --prefix $BUILD_DIR newrelic@latest @newrelic/aws-sdk@latest
    mkdir -p $BUILD_DIR/node_modules/newrelic-lambda-wrapper
    cp index.js $BUILD_DIR/node_modules/newrelic-lambda-wrapper
    download-extension
    zip -rq $NJS14X_DIST $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    echo "Build complete: ${NJS14X_DIST}"
}

function publish-nodejs14x {
    if [ ! -f $NJS14X_DIST ]; then
        echo "Package not found: ${NJS14X_DIST}"
        exit 1
    fi

    njs14x_hash=$(md5sum $NJS14X_DIST | awk '{ print $1 }')
    njs14x_s3key="nr-nodejs14.x/${njs14x_hash}.zip"

    for region in "${REGIONS[@]}"; do
        bucket_name="${BUCKET_PREFIX}-${region}"

        echo "Uploading ${NJS14X_DIST} to s3://${bucket_name}/${njs14x_s3key}"
        aws --region $region s3 cp $NJS14X_DIST "s3://${bucket_name}/${njs14x_s3key}"

        echo "Publishing nodejs14.x layer to ${region}"
        njs14x_version=$(aws lambda publish-layer-version \
            --layer-name NewRelicNodeJS14X \
            --content "S3Bucket=${bucket_name},S3Key=${njs14x_s3key}" \
            --description "New Relic Layer for Node.js 14.x" \
            --license-info "Apache-2.0" \
            --compatible-runtimes nodejs14.x \
            --region $region \
            --output text \
            --query Version)
        echo "published nodejs14.x layer version ${njs14x_version} to ${region}"

        echo "Setting public permissions for nodejs14.x layer version ${njs14x_version} in ${region}"
        aws lambda add-layer-version-permission \
          --layer-name NewRelicNodeJS14X \
          --version-number $njs14x_version \
          --statement-id public \
          --action lambda:GetLayerVersion \
          --principal "*" \
          --region $region
        echo "Public permissions set for nodejs14.x layer version ${njs14x_version} in region ${region}"
    done
}

case "$1" in
    "nodejs12.x")
        build-nodejs12x
        publish-nodejs12x
        ;;
    "nodejs14.x")
        build-nodejs14x
        publish-nodejs14x
        ;;
    *)
        usage
        ;;
esac
