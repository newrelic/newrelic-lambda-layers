#!/usr/bin/env bash

set -Eeuo pipefail

BUILD_DIR=build
BUCKET_PREFIX=nr-layers

GRADLE_ARCHIVE=$BUILD_DIR/distributions/NewRelicJavaLayer.zip

DIST_DIR=dist
JAVA8_DIST_ARM64=$DIST_DIR/java8.arm64.zip
JAVA8_DIST_X86_64=$DIST_DIR/java8.x86_64.zip
JAVA11_DIST_ARM64=$DIST_DIR/java11.arm64.zip
JAVA11_DIST_X86_64=$DIST_DIR/java11.x86_64.zip

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

function usage {
	echo "./publish-layers.sh [java8al2, java11]"
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

function build-arm() {
  platform=$1
  javaVersion=$2
  target=$3

	echo "Building New Relic layer for ${platform}"
	rm -rf $BUILD_DIR $target
	download-extension-arm64
	./gradlew packageLayer -P javaVersion=$javaVersion
	mkdir -p $DIST_DIR
	cp $GRADLE_ARCHIVE $target
	rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
	echo "Build complete"
}

function build-x86() {
  platform=$1
  javaVersion=$2
  target=$3

	echo "Building New Relic layer for ${platform}"
	rm -rf $BUILD_DIR $target
	download-extension-x86
	./gradlew packageLayer -P javaVersion=$javaVersion
	mkdir -p $DIST_DIR
	cp $GRADLE_ARCHIVE $target
	rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
	echo "Build complete"
}

function build-java8al2-arm64 {
  build-arm "java8.al2 (arm64)" 8 $JAVA8_DIST_ARM64
}

function build-java8al2-x86 {
  build-x86 "java8.al2 (x86_64)" 8 $JAVA8_DIST_X86_64
}

function publish-java8al2-arm64 {
	if [ ! -f  $JAVA8_DIST_ARM64 ]; then
		echo "Package not found"
		exit 1
	fi

	java_hash=$(md5sum $JAVA8_DIST_ARM64 | awk '{ print $1 }')
	java_s3key="java-8/${java_hash}.arm64.zip"

	for region in "${REGIONS_ARCH[@]}"; do
		bucket_name="${BUCKET_PREFIX}-${region}"

		echo "Uploading ${JAVA8_DIST_ARM64} to s3://${bucket_name}/${java_s3key}"
		aws --region "$region" s3 cp $JAVA8_DIST_ARM64 "s3://${bucket_name}/${java_s3key}"

		echo "Publishing java8.al2 layer to ${region}"
		java_version=$(aws lambda publish-layer-version \
			--layer-name NewRelicJava8ARM64 \
			--content "S3Bucket=${bucket_name},S3Key=${java_s3key}" \
			--description "New Relic Layer for java8.al2 (arm64)" \
			--license-info "Apache-2.0" \
			--compatible-runtimes java8.al2 \
			--compatible-architectures "arm64" \
			--region "$region" \
			--output text \
			--query Version)
		echo "Published java8.al2 layer version ${java_version} to ${region}"

		echo "Setting public permissions for java8.al2 layer version ${java_version} in ${region}"
		aws lambda add-layer-version-permission \
			--layer-name NewRelicJava8ARM64 \
			--version-number "$java_version" \
			--statement-id public \
			--action lambda:GetLayerVersion \
			--principal "*" \
			--region "$region"
		echo "Public permissions set for java8.al2 layer version ${java_version} in region ${region}"
	done
}

function publish-java8al2-x86 {
	if [ ! -f $JAVA8_DIST_X86_64 ]; then
		echo "Package not found"
		exit 1
	fi

	java_hash=$(md5sum $JAVA8_DIST_X86_64 | awk '{ print $1 }')
	java_s3key="java-8/${java_hash}.x86_64.zip"

	for region in "${REGIONS_ARCH[@]}"; do
		bucket_name="${BUCKET_PREFIX}-${region}"

		echo "Uploading ${JAVA8_DIST_X86_64} to s3://${bucket_name}/${java_s3key}"
		aws --region "$region" s3 cp $JAVA8_DIST_X86_64 "s3://${bucket_name}/${java_s3key}"

		echo "Publishing java8.al2 layer to ${region}"
		java_version=$(aws lambda publish-layer-version \
			--layer-name NewRelicJava8 \
			--content "S3Bucket=${bucket_name},S3Key=${java_s3key}" \
			--description "New Relic Layer for java8.al2 (x86_64)" \
			--license-info "Apache-2.0" \
			--compatible-runtimes java8.al2 \
			--compatible-architectures "x86_64" \
			--region "$region" \
			--output text \
			--query Version)
		echo "Published java8.al2 layer version ${java_version} to ${region}"

		echo "Setting public permissions for java8.al2 layer version ${java_version} in ${region}"
		aws lambda add-layer-version-permission \
			--layer-name NewRelicJava8 \
			--version-number "$java_version" \
			--statement-id public \
			--action lambda:GetLayerVersion \
			--principal "*" \
			--region "$region"
		echo "Public permissions set for java8.al2 layer version ${java_version} in region ${region}"
	done

	# TODO: Remove once all regions support --compatible-architectures
	for region in "${REGIONS_NO_ARCH[@]}"; do
		bucket_name="${BUCKET_PREFIX}-${region}"

		echo "Uploading ${JAVA8_DIST_X86_64} to s3://${bucket_name}/${java_s3key}"
		aws --region "$region" s3 cp $JAVA8_DIST_X86_64 "s3://${bucket_name}/${java_s3key}"

		echo "Publishing java8.al2 layer to ${region}"
		java_version=$(aws lambda publish-layer-version \
			--layer-name NewRelicJava8 \
			--content "S3Bucket=${bucket_name},S3Key=${java_s3key}" \
			--description "New Relic Layer for java8.al2 (x86_64)" \
			--license-info "Apache-2.0" \
			--compatible-runtimes java8.al2 \
			--region "$region" \
			--output text \
			--query Version)
		echo "Published java8.al2 layer version ${java_version} to ${region}"

		echo "Setting public permissions for java8.al2 layer version ${java_version} in ${region}"
		aws lambda add-layer-version-permission \
			--layer-name NewRelicJava8 \
			--version-number "$java_version" \
			--statement-id public \
			--action lambda:GetLayerVersion \
			--principal "*" \
			--region "$region"
		echo "Public permissions set for java8.al2 layer version ${java_version} in region ${region}"
	done
}

function build-java11-arm64 {
  build-arm "java11 (arm64)" 11 $JAVA11_DIST_ARM64
}

function build-java11-x86 {
  build-x86 "java11 (x86_64)" 11 $JAVA11_DIST_X86_64
}

function publish-java11-arm64 {
	if [ ! -f $JAVA11_DIST_ARM64 ]; then
		echo "Package not found"
		exit 1
	fi

	java_hash=$(md5sum $JAVA11_DIST_ARM64 | awk '{ print $1 }')
	java_s3key="java-11/${java_hash}.arm64.zip"

	for region in "${REGIONS_ARCH[@]}"; do
		bucket_name="${BUCKET_PREFIX}-${region}"

		echo "Uploading ${JAVA11_DIST_ARM64} to s3://${bucket_name}/${java_s3key}"
		aws --region "$region" s3 cp $JAVA11_DIST_ARM64 "s3://${bucket_name}/${java_s3key}"

		echo "Publishing java 11 layer to ${region}"
		java_version=$(aws lambda publish-layer-version \
			--layer-name NewRelicJava11ARM64 \
			--content "S3Bucket=${bucket_name},S3Key=${java_s3key}" \
			--description "New Relic Layer for Java 11 (arm64)" \
			--license-info "Apache-2.0" \
			--compatible-runtimes java11 \
			--compatible-architectures "arm64" \
			--region "$region" \
			--output text \
			--query Version)
		echo "Published java 11 layer version ${java_version} to ${region}"

		echo "Setting public permissions for java 11 layer version ${java_version} in ${region}"
		aws lambda add-layer-version-permission \
			--layer-name NewRelicJava11ARM64 \
			--version-number "$java_version" \
			--statement-id public \
			--action lambda:GetLayerVersion \
			--principal "*" \
			--region "$region"
		echo "Public permissions set for java 11 layer version ${java_version} in region ${region}"
	done
}

function publish-java11-x86 {
	if [ ! -f $JAVA11_DIST_X86_64 ]; then
		echo "Package not found"
		exit 1
	fi

	java_hash=$(md5sum $JAVA11_DIST_X86_64 | awk '{ print $1 }')
	java_s3key="java-11/${java_hash}.x86_64.zip"

	for region in "${REGIONS_ARCH[@]}"; do
		bucket_name="${BUCKET_PREFIX}-${region}"

		echo "Uploading ${JAVA11_DIST_X86_64} to s3://${bucket_name}/${java_s3key}"
		aws --region "$region" s3 cp $JAVA11_DIST_X86_64 "s3://${bucket_name}/${java_s3key}"

		echo "Publishing java 11 layer to ${region}"
		java_version=$(aws lambda publish-layer-version \
			--layer-name NewRelicJava11 \
			--content "S3Bucket=${bucket_name},S3Key=${java_s3key}" \
			--description "New Relic Layer for Java 11 (x86_64)" \
			--license-info "Apache-2.0" \
			--compatible-runtimes java11 \
			--compatible-architectures "x86_64" \
			--region "$region" \
			--output text \
			--query Version)
		echo "Published java 11 layer version ${java_version} to ${region}"

		echo "Setting public permissions for java 11 layer version ${java_version} in ${region}"
		aws lambda add-layer-version-permission \
			--layer-name NewRelicJava11 \
			--version-number "$java_version" \
			--statement-id public \
			--action lambda:GetLayerVersion \
			--principal "*" \
			--region "$region"
		echo "Public permissions set for java 11 layer version ${java_version} in region ${region}"
	done

	# TODO: Remove once all regions support --compatible-architectures
	for region in "${REGIONS_NO_ARCH[@]}"; do
		bucket_name="${BUCKET_PREFIX}-${region}"

		echo "Uploading ${JAVA11_DIST_X86_64} to s3://${bucket_name}/${java_s3key}"
		aws --region "$region" s3 cp $JAVA11_DIST_X86_64 "s3://${bucket_name}/${java_s3key}"

		echo "Publishing java 11 layer to ${region}"
		java_version=$(aws lambda publish-layer-version \
			--layer-name NewRelicJava11 \
			--content "S3Bucket=${bucket_name},S3Key=${java_s3key}" \
			--description "New Relic Layer for Java 11 (x86_64)" \
			--license-info "Apache-2.0" \
			--compatible-runtimes java11 \
			--region "$region" \
			--output text \
			--query Version)
		echo "Published java 11 layer version ${java_version} to ${region}"

		echo "Setting public permissions for java 11 layer version ${java_version} in ${region}"
		aws lambda add-layer-version-permission \
			--layer-name NewRelicJava11 \
			--version-number "$java_version" \
			--statement-id public \
			--action lambda:GetLayerVersion \
			--principal "*" \
			--region "$region"
		echo "Public permissions set for java 11 layer version ${java_version} in region ${region}"
	done
}

case "$1" in
"build-java8al2")
	build-java8al2-arm64
	build-java8al2-x86
	;;
"publish-java8al2")
	publish-java8al2-arm64
	publish-java8al2-x86
	;;
"build-java11")
	build-java11-arm64
	build-java11-x86
	;;
"publish-java11")
	publish-java11-arm64
	publish-java11-x86
	;;
"java8al2")
	$0 build-java8al2
	$0 publish-java8al2
	;;
"java11")
	$0 build-java11
	$0 publish-java11
	;;
*)
	usage
	;;
esac
