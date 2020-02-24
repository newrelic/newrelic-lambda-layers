#!/bin/bash -x

BUILD_DIR=python
BUCKET_PREFIX=nr-layers
DIST_DIR=dist
PY27_DIST=$DIST_DIR/python27.zip
PY36_DIST=$DIST_DIR/python36.zip
PY37_DIST=dist/python37.zip
PY38_DIST=dist/python38.zip

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
    echo "./publish-layers.sh [python2.7|python3.6|python3.7|python3.8]"
}

function build-python27 {
    echo "Building New Relic layer for python2.7"
    rm -rf $BUILD_DIR $PY27_DIST
    mkdir -p $DIST_DIR
    pip install --no-cache-dir -qU newrelic-lambda -t $BUILD_DIR/lib/python2.7/site-packages
    cp newrelic_lambda_wrapper.py $BUILD_DIR/lib/python2.7/site-packages/newrelic_lambda_wrapper.py
    find $BUILD_DIR -name '*.pyc' -exec rm -f {} +
    zip -rq $PY27_DIST $BUILD_DIR
    rm -rf $BUILD_DIR
    echo "Build complete: ${PY27_DIST}"
}

function publish-python27 {
    if [ ! -f $PY27_DIST ]; then
        echo "Package not found: ${PY27_DIST}"
        exit 1
    fi

    py27_hash=$(md5sum $PY27_DIST | awk '{ print $1 }')
    py27_s3key="nr-python2.7/${py27_hash}.zip"

    for region in "${REGIONS[@]}"; do
        bucket_name="${BUCKET_PREFIX}-${region}"

        echo "Uploading ${PY27_DIST} to s3://${bucket_name}/${py27_s3key}"
        aws --region $region s3 cp $PY27_DIST "s3://${bucket_name}/${py27_s3key}"

        echo "Publishing python2.7 layer to ${region}"
        py27_version=$(aws lambda publish-layer-version \
            --layer-name NewRelicPython27 \
            --content "S3Bucket=${bucket_name},S3Key=${py27_s3key}" \
            --description "New Relic Layer for Python 2.7" \
            --compatible-runtimes python2.7 \
            --region $region \
            --output text \
            --query Version)
        echo "Published python2.7 layer version ${py27_version} to ${region}"

        echo "Setting public permissions for python2.7 layer version ${py27_version} in ${region}"
        aws lambda add-layer-version-permission \
          --layer-name NewRelicPython27 \
          --version-number $py27_version \
          --statement-id public \
          --action lambda:GetLayerVersion \
          --principal "*" \
          --region $region
        echo "Public permissions set for python2.7 layer version ${py27_version} in region ${region}"
    done
}

function build-python36 {
    echo "Building New Relic layer for python3.6"
    rm -rf $BUILD_DIR $PY36_DIST
    mkdir -p $DIST_DIR
    pip install --no-cache-dir -qU newrelic-lambda -t $BUILD_DIR/lib/python3.6/site-packages
    cp newrelic_lambda_wrapper.py $BUILD_DIR/lib/python3.6/site-packages/newrelic_lambda_wrapper.py
    find $BUILD_DIR -name '__pycache__' -exec rm -rf {} +
    zip -rq $PY36_DIST $BUILD_DIR
    rm -rf $BUILD_DIR
    echo "Build complete: ${PY36_DIST}"
}

function publish-python36 {
    if [ ! -f $PY36_DIST ]; then
        echo "Package not found: ${PY36_DIST}"
        exit 1
    fi

    py36_hash=$(md5sum $PY36_DIST | awk '{ print $1 }')
    py36_s3key="nr-python3.6/${py36_hash}.zip"

    for region in "${REGIONS[@]}"; do
        bucket_name="${BUCKET_PREFIX}-${region}"

        echo "Uploading ${PY36_DIST} to s3://${bucket_name}/${py36_s3key}"
        aws --region $region s3 cp $PY36_DIST "s3://${bucket_name}/${py36_s3key}"

        echo "Publishing python3.6 layer to ${region}"
        py36_version=$(aws lambda publish-layer-version \
            --layer-name NewRelicPython36 \
            --content "S3Bucket=${bucket_name},S3Key=${py36_s3key}" \
            --description "New Relic Layer for Python 3.6" \
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

function build-python37 {
    echo "Building New Relic layer for python3.7"
    rm -rf $BUILD_DIR $PY37_DIST
    mkdir -p $DIST_DIR
    pip install --no-cache-dir -qU newrelic-lambda -t $BUILD_DIR/lib/python3.7/site-packages
    cp newrelic_lambda_wrapper.py $BUILD_DIR/lib/python3.7/site-packages/newrelic_lambda_wrapper.py
    find $BUILD_DIR -name '__pycache__' -exec rm -rf {} +
    zip -rq $PY37_DIST $BUILD_DIR
    rm -rf $BUILD_DIR
    echo "Build complete: ${PY37_DIST}"
}

function publish-python37 {
    if [ ! -f $PY37_DIST ]; then
        echo "Package not found: ${PY37_DIST}"
        exit 1
    fi

    py37_hash=$(md5sum $PY37_DIST | awk '{ print $1 }')
    py37_s3key="nr-python3.7/${py37_hash}.zip"

    for region in "${REGIONS[@]}"; do
        bucket_name="${BUCKET_PREFIX}-${region}"

        echo "Uploading ${PY37_DIST} to s3://${bucket_name}/${py37_s3key}"
        aws --region $region s3 cp $PY37_DIST "s3://${bucket_name}/${py37_s3key}"

        echo "Publishing python3.7 layer to ${region}"
        py37_version=$(aws lambda publish-layer-version \
            --layer-name NewRelicPython37 \
            --content "S3Bucket=${bucket_name},S3Key=${py37_s3key}" \
            --description "New Relic Layer for Python 3.7" \
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

function build-python38 {
    echo "Building New Relic layer for python3.8"
    rm -rf $BUILD_DIR $PY38_DIST
    mkdir -p $DIST_DIR
    pip install --no-cache-dir -qU newrelic-lambda -t $BUILD_DIR/lib/python3.8/site-packages
    cp newrelic_lambda_wrapper.py $BUILD_DIR/lib/python3.8/site-packages/newrelic_lambda_wrapper.py
    find $BUILD_DIR -name '__pycache__' -exec rm -rf {} +
    zip -rq $PY38_DIST $BUILD_DIR
    rm -rf $BUILD_DIR
    echo "Build complete: ${PY38_DIST}"
}

function publish-python38 {
    if [ ! -f $PY38_DIST ]; then
        echo "Package not found: ${PY38_DIST}"
        exit 1
    fi

    py38_hash=$(md5sum $PY38_DIST | awk '{ print $1 }')
    py38_s3key="nr-python3.8/${py38_hash}.zip"

    for region in "${REGIONS[@]}"; do
        bucket_name="${BUCKET_PREFIX}-${region}"

        echo "Uploading ${PY38_DIST} to s3://${bucket_name}/${py38_s3key}"
        aws --region $region s3 cp $PY38_DIST "s3://${bucket_name}/${py38_s3key}"

        echo "Publishing python3.8 layer to ${region}"
        py38_version=$(aws lambda publish-layer-version \
            --layer-name NewRelicPython38 \
            --content "S3Bucket=${bucket_name},S3Key=${py38_s3key}" \
            --description "New Relic Layer for Python 3.8" \
            --compatible-runtimes python3.8 \
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

case "$1" in
    "python2.7")
        build-python27
        publish-python27
        ;;
    "python3.6")
        build-python36
        publish-python36
        ;;
    "python3.7")
        build-python37
        publish-python37
        ;;
    "python3.8")
        build-python38
        publish-python38
        ;;
    *)
        usage
        ;;
esac
