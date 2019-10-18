#!/bin/bash -ex

PY27_DIST=dist/python27.zip
PY36_DIST=dist/python36.zip
PY37_DIST=dist/python37.zip

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
    echo "./publish-layers.sh [python2.7|python3.6|python3.7]"
}

function build-python27 {
    echo "Building nr1 layer for python2.7"
    rm -rf $PY27_DIST python
    mkdir -p dist
    pip install --no-cache-dir -qU newrelic -t python/lib/python2.7/site-packages
	cp newrelic_handler.py python/lib/python2.7/site-packages/newrelic/handler.py
    find python -name '*.pyc' -exec rm -f {} +
    zip -rq $PY27_DIST python
    rm -rf python
    echo "Build complete: ${PY27_DIST}"
}

function publish-python27 {
    if [ ! -f $PY27_DIST ]; then
        echo "Package not found: ${PY27_DIST}"
        exit 1
    fi

    py27_hash=$(md5sum $PY27_DIST | awk '{ print $1 }')
    py27_s3key="nr1-python2.7/${py27_hash}.zip"

    for region in "${REGIONS[@]}"; do
        bucket_name="nr1-layers-${region}"

        echo "Uploading ${PY27_DIST} to s3://${bucket_name}/${py27_s3key}"
        aws --region $region s3 cp $PY27_DIST "s3://${bucket_name}/${py27_s3key}"

        echo "Publishing python2.7 layer to ${region}"
        py27_version=$(aws lambda publish-layer-version \
            --layer-name NR1Python27 \
            --content "S3Bucket=${bucket_name},S3Key=${py27_s3key}" \
            --description "NR1 Layer for Python 2.7" \
            --compatible-runtimes python2.7 \
            --license-info "Apache 2.0" \
            --region $region \
            --output text \
            --query Version)
        echo "Published python2.7 layer version ${py27_version} to ${region}"

        echo "Setting public permissions for python2.7 layer version ${py27_version} in ${region}"
        aws lambda add-layer-version-permission \
          --layer-name NR1Python27 \
          --version-number $py27_version \
          --statement-id public \
          --action lambda:GetLayerVersion \
          --principal "*" \
          --region $region
        echo "Public permissions set for python2.7 layer version ${py27_version} in region ${region}"
    done
}

function build-python36 {
    echo "Building nr1 layer for python3.6"
    rm -rf $PY36_DIST python
    mkdir -p dist
    pip install --no-cache-dir -qU newrelic -t python/lib/python3.6/site-packages
	cp newrelic_handler.py python/lib/python3.6/site-packages/newrelic/handler.py
    find python -name '__pycache__' -exec rm -rf {} +
    zip -rq $PY36_DIST python
    rm -rf python
    echo "Build complete: ${PY36_DIST}"
}

function publish-python36 {
    if [ ! -f $PY36_DIST ]; then
        echo "Package not found: ${PY36_DIST}"
        exit 1
    fi

    py36_hash=$(md5sum $PY36_DIST | awk '{ print $1 }')
    py36_s3key="nr1-python3.6/${py36_hash}.zip"

    for region in "${REGIONS[@]}"; do
        bucket_name="nr1-layers-${region}"

        echo "Uploading ${PY36_DIST} to s3://${bucket_name}/${py36_s3key}"
        aws --region $region s3 cp $PY36_DIST "s3://${bucket_name}/${py36_s3key}"

        echo "Publishing python3.6 layer to ${region}"
        py36_version=$(aws lambda publish-layer-version \
            --layer-name NR1Python36 \
            --content "S3Bucket=${bucket_name},S3Key=${py36_s3key}" \
            --description "NR1 Layer for Python 3.6" \
            --compatible-runtimes python3.6 \
            --license-info "Apache 2.0" \
            --region $region \
            --output text \
            --query Version)
        echo "published python3.6 layer version ${py36_version} to ${region}"

        echo "Setting public permissions for python3.6 layer version ${py36_version} in ${region}"
        aws lambda add-layer-version-permission \
          --layer-name NR1Python36 \
          --version-number $py36_version \
          --statement-id public \
          --action lambda:GetLayerVersion \
          --principal "*" \
          --region $region
        echo "Public permissions set for python3.6 layer version ${py36_version} in region ${region}"
    done
}

function build-python37 {
    echo "Building nr1 layer for python3.7"
    rm -rf $PY37_DIST python
    mkdir -p dist
    pip install --no-cache-dir -qU newrelic -t python/lib/python3.7/site-packages
	cp newrelic_handler.py python/lib/python3.7/site-packages/newrelic/handler.py
    find python -name '__pycache__' -exec rm -rf {} +
    zip -rq $PY37_DIST python
    rm -rf python
    echo "Build complete: ${PY37_DIST}"
}

function publish-python37 {
    if [ ! -f $PY37_DIST ]; then
        echo "Package not found: ${PY37_DIST}"
        exit 1
    fi

    py37_hash=$(md5sum $PY37_DIST | awk '{ print $1 }')
    py37_s3key="nr1-python3.7/${py37_hash}.zip"

    for region in "${REGIONS[@]}"; do
        bucket_name="nr1-layers-${region}"

        echo "Uploading ${PY37_DIST} to s3://${bucket_name}/${py37_s3key}"
        aws --region $region s3 cp $PY37_DIST "s3://${bucket_name}/${py37_s3key}"

        echo "Publishing python3.7 layer to ${region}"
        py36_version=$(aws lambda publish-layer-version \
            --layer-name NR1Python37 \
            --content "S3Bucket=${bucket_name},S3Key=${py37_s3key}" \
            --description "NR1 Layer for Python 3.7" \
            --compatible-runtimes python3.7 \
            --license-info "Apache 2.0" \
            --region $region \
            --output text \
            --query Version)
        echo "published python3.7 layer version ${py37_version} to ${region}"

        echo "Setting public permissions for python3.7 layer version ${py37_version} in ${region}"
        aws lambda add-layer-version-permission \
          --layer-name NR1Python37 \
          --version-number $py37_version \
          --statement-id public \
          --action lambda:GetLayerVersion \
          --principal "*" \
          --region $region
        echo "Public permissions set for python3.7 layer version ${py37_version} in region ${region}"
    done
}

case "$1" in
    "python2.7")
        build-python27
		#publish-python27
        ;;
    "python3.6")
        build-python36
		#publish-python36
        ;;
    "python3.7")
        build-python37
		#publish-python37
        ;;
    *)
        usage
        ;;
esac
