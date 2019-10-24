#!/bin/bash -ex

BUILD_DIR=nodejs
BUCKET_PREFIX=nr-layers
DIST_DIR=dist
NJS810_DIST=$DIST_DIR/nodejs810.zip
NJS10X_DIST=$DIST_DIR/nodejs10x.zip

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

function usage {
    echo "./publish-layers.sh [nodejs8.10|nodejs10.x]"
}

function build-nodejs810 {
    echo "Building New Relic layer for nodejs8.10"
    rm -rf $BUILD_DIR $NJS810_DIST
    mkdir -p $DIST_DIR
    npm install --prefix $BUILD_DIR newrelic@latest @newrelic/aws-sdk@latest
    mkdir -p $BUILD_DIR/node_modules/newrelic-lambda-wrapper
    cp index.js $BUILD_DIR/node_modules/newrelic-lambda-wrapper
    zip -rq $NJS810_DIST $BUILD_DIR
    rm -rf $BUILD_DIR
    echo "Build complete: ${NJS810_DIST}"
}

function publish-nodejs810 {
    if [ ! -f $NJS810_DIST ]; then
        echo "Package not found: ${NJS810_DIST}"
        exit 1
    fi

    njs810_hash=$(md5sum $NJS810_DIST | awk '{ print $1 }')
    njs810_s3key="nr-nodejs8.10/${njs810_hash}.zip"

    for region in "${REGIONS[@]}"; do
        bucket_name="${BUCKET_PREFIX}-${region}"

        echo "Uploading ${NJS810_DIST} to s3://${bucket_name}/${njs810_s3key}"
        aws --region $region s3 cp $NJS810_DIST "s3://${bucket_name}/${njs810_s3key}"

        echo "Publishing nodejs8.10 layer to ${region}"
        njs810_version=$(aws lambda publish-layer-version \
            --layer-name NewRelicNodeJS810 \
            --content "S3Bucket=${bucket_name},S3Key=${njs810_s3key}" \
            --description "New Relic Layer for Node.js 8.10" \
            --compatible-runtimes nodejs8.10 \
            --region $region \
            --output text \
            --query Version)
        echo "Published nodejs8.10 layer version ${njs810_version} to ${region}"

        echo "Setting public permissions for nodejs8.10 layer version ${njs810_version} in ${region}"
        aws lambda add-layer-version-permission \
          --layer-name NewRelicNodeJS810 \
          --version-number $njs810_version \
          --statement-id public \
          --action lambda:GetLayerVersion \
          --principal "*" \
          --region $region
        echo "Public permissions set for nodejs8.10 layer version ${njs810_version} in region ${region}"
    done
}

function build-nodejs10x {
    echo "Building new relic layer for nodejs10.x"
    rm -rf $BUILD_DIR $NJS10X_DIST
    mkdir -p $DIST_DIR
    npm install --prefix $BUILD_DIR newrelic@latest @newrelic/aws-sdk@latest
    mkdir -p $BUILD_DIR/node_modules/newrelic-lambda-wrapper
    cp index.js $BUILD_DIR/node_modules/newrelic-lambda-wrapper
    zip -rq $NJS10X_DIST $BUILD_DIR
    rm -rf $BUILD_DIR
    echo "Build complete: ${NJS10X_DIST}"
}

function publish-nodejs10x {
    if [ ! -f $NJS10X_DIST ]; then
        echo "Package not found: ${NJS10X_DIST}"
        exit 1
    fi

    njs10x_hash=$(md5sum $NJS10X_DIST | awk '{ print $1 }')
    njs10x_s3key="nr-nodejs10.x/${njs10x_hash}.zip"

    for region in "${REGIONS[@]}"; do
        bucket_name="${BUCKET_PREFIX}-${region}"

        echo "Uploading ${NJS10X_DIST} to s3://${bucket_name}/${njs10x_s3key}"
        aws --region $region s3 cp $NJS10X_DIST "s3://${bucket_name}/${njs10x_s3key}"

        echo "Publishing nodejs10.x layer to ${region}"
        njs10x_version=$(aws lambda publish-layer-version \
            --layer-name NewRelicNodeJS10X \
            --content "S3Bucket=${bucket_name},S3Key=${njs10x_s3key}" \
            --description "New Relic Layer for Node.js 10.x" \
            --compatible-runtimes nodejs10.x \
            --region $region \
            --output text \
            --query Version)
        echo "published nodejs10.x layer version ${njs10x_version} to ${region}"

        echo "Setting public permissions for nodejs10.x layer version ${njs10x_version} in ${region}"
        aws lambda add-layer-version-permission \
          --layer-name NewRelicNodeJS10X \
          --version-number $njs10x_version \
          --statement-id public \
          --action lambda:GetLayerVersion \
          --principal "*" \
          --region $region
        echo "Public permissions set for nodejs10.x layer version ${njs10x_version} in region ${region}"
    done
}

case "$1" in
    "nodejs8.10")
        build-nodejs810
        #publish-nodejs810
        ;;
    "nodejs10.x")
        build-nodejs10x
        #publish-nodejs10x
        ;;
    *)
        usage
        ;;
esac
