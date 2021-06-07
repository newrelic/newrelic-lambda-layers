#!/usr/bin/env bash

set -Eeuo pipefail

BUILD_DIR=build
BUCKET_PREFIX=nr-layers
JAVA_JAR=java/lib/NewRelicJavaLayer.jar
JAVA_ZIP_DIR=$BUILD_DIR/java/lib/
JAVA_DIST=distributions/NewRelicJavaLayer.zip

EXTENSION_DIST_DIR=extensions
EXTENSION_DIST_URL=https://github.com/newrelic/newrelic-lambda-extension/releases/download/v2.0.1/newrelic-lambda-extension.zip
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
    echo "./publish-layers.sh [java8, java11]"
}

function download-extension {
    rm -rf $EXTENSION_DIST_DIR $EXTENSION_DIST_ZIP
    curl -L $EXTENSION_DIST_URL -o $EXTENSION_DIST_ZIP
    unzip $EXTENSION_DIST_ZIP -d .
    rm -f $EXTENSION_DIST_ZIP
}

 function build-java8.al2 {
     echo "Building New Relic layer for java8.al2"
     rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
     ./gradlew build -P javaVersion=8
     ./gradlew packageFat
     mkdir -p $JAVA_ZIP_DIR
     ./gradlew copyLibs
     cd build
     download-extension
     zip $JAVA_DIST $JAVA_JAR $EXTENSION_DIST_PREVIEW_FILE "${EXTENSION_DIST_DIR}/newrelic-lambda-extension"
     rm -rf $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
     echo "Build complete"
 }

 function publish-java8.al2 {
     if [ ! -f "distributions/NewRelicJavaLayer.zip" ]; then
         echo "Package not found"
         exit 1
     fi

     java_hash=$(md5sum $JAVA_DIST | awk '{ print $1 }')
     java_s3key="java-8/${java_hash}.zip"

     for region in "${REGIONS[@]}"; do
         bucket_name="${BUCKET_PREFIX}-${region}"

         echo "Uploading ${JAVA_DIST} to s3://${bucket_name}/${java_s3key}"
         aws --region $region s3 cp $JAVA_DIST "s3://${bucket_name}/${java_s3key}"

         echo "Publishing java8.al2 layer to ${region}"
         java_version=$(aws lambda publish-layer-version \
             --layer-name NewRelicJava8 \
             --content "S3Bucket=${bucket_name},S3Key=${java_s3key}" \
             --description "New Relic Layer for java8.al2" \
             --license-info "Apache-2.0" \
             --compatible-runtimes java8.al2 \
             --region $region \
             --output text \
             --query Version)
         echo "Published java8.al2 layer version ${java_version} to ${region}"

         echo "Setting public permissions for java8.al2 layer version ${java_version} in ${region}"
         aws lambda add-layer-version-permission \
           --layer-name NewRelicJava8 \
           --version-number $java_version \
           --statement-id public \
           --action lambda:GetLayerVersion \
           --principal "*" \
           --region $region
         echo "Public permissions set for java8.al2 layer version ${java_version} in region ${region}"
     done
 }

function build-java11 {
    echo "Building New Relic layer for java 11"
    rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    ./gradlew build -P javaVersion=11
    ./gradlew packageFat
    mkdir -p $JAVA_ZIP_DIR
    ./gradlew copyLibs
    cd build
    download-extension
    zip $JAVA_DIST $JAVA_JAR $EXTENSION_DIST_PREVIEW_FILE "${EXTENSION_DIST_DIR}/newrelic-lambda-extension"
    rm -rf $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
    echo "Build complete"
}

function publish-java11 {
    if [ ! -f "distributions/NewRelicJavaLayer.zip" ]; then
        echo "Package not found"
        exit 1
    fi

    java_hash=$(md5sum $JAVA_DIST | awk '{ print $1 }')
    java_s3key="java-11/${java_hash}.zip"

    for region in "${REGIONS[@]}"; do
        bucket_name="${BUCKET_PREFIX}-${region}"

        echo "Uploading ${JAVA_DIST} to s3://${bucket_name}/${java_s3key}"
        aws --region $region s3 cp $JAVA_DIST "s3://${bucket_name}/${java_s3key}"

        echo "Publishing java 11 layer to ${region}"
        java_version=$(aws lambda publish-layer-version \
            --layer-name NewRelicJava11 \
            --content "S3Bucket=${bucket_name},S3Key=${java_s3key}" \
            --description "New Relic Layer for Java 11" \
            --license-info "Apache-2.0" \
            --compatible-runtimes java11 \
            --region $region \
            --output text \
            --query Version)
        echo "Published java 11 layer version ${java_version} to ${region}"

        echo "Setting public permissions for java 11 layer version ${java_version} in ${region}"
        aws lambda add-layer-version-permission \
          --layer-name NewRelicJava11 \
          --version-number $java_version \
          --statement-id public \
          --action lambda:GetLayerVersion \
          --principal "*" \
          --region $region
        echo "Public permissions set for java 11 layer version ${java_version} in region ${region}"
    done
}

case "$1" in
    "java8.al2")
        build-java8.al2
        publish-java8.al2
        ;;
    "java11")
        build-java11
        publish-java11
        ;;
    *)
        usage
        ;;
esac
