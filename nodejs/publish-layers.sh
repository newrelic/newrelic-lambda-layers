#!/usr/bin/env bash

set -Eeuo pipefail

BUILD_DIR=nodejs
BUCKET_PREFIX=nr-layers
DIST_DIR=dist

NJS12X_DIST_ARM64=$DIST_DIR/nodejs12x.arm64.zip
NJS14X_DIST_ARM64=$DIST_DIR/nodejs14x.arm64.zip

NJS12X_DIST_X86_64=$DIST_DIR/nodejs12x.x86_64.zip
NJS14X_DIST_X86_64=$DIST_DIR/nodejs14x.x86_64.zip

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
	echo "./publish-layers.sh [nodejs12.x|nodejs14.x]"
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

function build-nodejs12x-arm64 {
	echo "Building new relic layer for nodejs12.x (arm64)"
	rm -rf $BUILD_DIR $NJS12X_DIST_ARM64
	mkdir -p $DIST_DIR
	npm install --prefix $BUILD_DIR newrelic@latest
	mkdir -p $BUILD_DIR/node_modules/newrelic-lambda-wrapper
	cp index.js $BUILD_DIR/node_modules/newrelic-lambda-wrapper
	download-extension-arm64
	zip -rq $NJS12X_DIST_ARM64 $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
	rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
	echo "Build complete: ${NJS12X_DIST_ARM64}"
}

function build-nodejs12x-x86 {
	echo "Building new relic layer for nodejs12.x (x86_64)"
	rm -rf $BUILD_DIR $NJS12X_DIST_X86_64
	mkdir -p $DIST_DIR
	npm install --prefix $BUILD_DIR newrelic@latest
	mkdir -p $BUILD_DIR/node_modules/newrelic-lambda-wrapper
	cp index.js $BUILD_DIR/node_modules/newrelic-lambda-wrapper
	download-extension-x86
	zip -rq $NJS12X_DIST_X86_64 $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
	rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
	echo "Build complete: ${NJS12X_DIST_X86_64}"
}

function publish-nodejs12x-arm64 {
	if [ ! -f $NJS12X_DIST_ARM64 ]; then
		echo "Package not found: ${NJS12X_DIST_ARM64}"
		exit 1
	fi

	njs12x_hash=$(md5sum $NJS12X_DIST_ARM64 | awk '{ print $1 }')
	njs12x_s3key="nr-nodejs12.x/${njs12x_hash}.arm64.zip"

	for region in "${REGIONS_ARCH[@]}"; do
		bucket_name="${BUCKET_PREFIX}-${region}"

		echo "Uploading ${NJS12X_DIST_ARM64} to s3://${bucket_name}/${njs12x_s3key}"
		aws --region "$region" s3 cp $NJS12X_DIST_ARM64 "s3://${bucket_name}/${njs12x_s3key}"

		echo "Publishing nodejs12.x layer to ${region}"
		njs12x_version=$(aws lambda publish-layer-version \
			--layer-name NewRelicNodeJS12XARM64 \
			--content "S3Bucket=${bucket_name},S3Key=${njs12x_s3key}" \
			--description "New Relic Layer for Node.js 12.x (arm64)" \
			--license-info "Apache-2.0" \
			--compatible-runtimes "nodejs12.x" \
			--compatible-architectures "arm64" \
			--region "$region" \
			--output text \
			--query Version)
		echo "published nodejs12.x layer version ${njs12x_version} to ${region}"

		echo "Setting public permissions for nodejs12.x layer version ${njs12x_version} in ${region}"
		aws lambda add-layer-version-permission \
			--layer-name NewRelicNodeJS12XARM64 \
			--version-number "$njs12x_version" \
			--statement-id public \
			--action lambda:GetLayerVersion \
			--principal "*" \
			--region "$region"
		echo "Public permissions set for nodejs12.x layer version ${njs12x_version} in region ${region}"
	done
}

function publish-nodejs12x-x86 {
	if [ ! -f $NJS12X_DIST_X86_64 ]; then
		echo "Package not found: ${NJS12X_DIST_X86_64}"
		exit 1
	fi

	njs12x_hash=$(md5sum $NJS12X_DIST_X86_64 | awk '{ print $1 }')
	njs12x_s3key="nr-nodejs12.x/${njs12x_hash}.x86_64.zip"

	for region in "${REGIONS_ARCH[@]}"; do
		bucket_name="${BUCKET_PREFIX}-${region}"

		echo "Uploading ${NJS12X_DIST_X86_64} to s3://${bucket_name}/${njs12x_s3key}"
		aws --region "$region" s3 cp $NJS12X_DIST_X86_64 "s3://${bucket_name}/${njs12x_s3key}"

		echo "Publishing nodejs12.x layer to ${region}"
		njs12x_version=$(aws lambda publish-layer-version \
			--layer-name NewRelicNodeJS12X \
			--content "S3Bucket=${bucket_name},S3Key=${njs12x_s3key}" \
			--description "New Relic Layer for Node.js 12.x (x86_64)" \
			--license-info "Apache-2.0" \
			--compatible-runtimes "nodejs12.x" \
			--compatible-architectures "x86_64" \
			--region "$region" \
			--output text \
			--query Version)
		echo "published nodejs12.x layer version ${njs12x_version} to ${region}"

		echo "Setting public permissions for nodejs12.x layer version ${njs12x_version} in ${region}"
		aws lambda add-layer-version-permission \
			--layer-name NewRelicNodeJS12X \
			--version-number "$njs12x_version" \
			--statement-id public \
			--action lambda:GetLayerVersion \
			--principal "*" \
			--region "$region"
		echo "Public permissions set for nodejs12.x layer version ${njs12x_version} in region ${region}"
	done

	# TODO: Remove this once all regions support --compatible-architectures
	for region in "${REGIONS_NO_ARCH[@]}"; do
		bucket_name="${BUCKET_PREFIX}-${region}"

		echo "Uploading ${NJS12X_DIST_X86_64} to s3://${bucket_name}/${njs12x_s3key}"
		aws --region "$region" s3 cp $NJS12X_DIST_X86_64 "s3://${bucket_name}/${njs12x_s3key}"

		echo "Publishing nodejs12.x layer to ${region}"
		njs12x_version=$(aws lambda publish-layer-version \
			--layer-name NewRelicNodeJS12X \
			--content "S3Bucket=${bucket_name},S3Key=${njs12x_s3key}" \
			--description "New Relic Layer for Node.js 12.x (x86_64)" \
			--license-info "Apache-2.0" \
			--compatible-runtimes "nodejs12.x" \
			--region "$region" \
			--output text \
			--query Version)
		echo "published nodejs12.x layer version ${njs12x_version} to ${region}"

		echo "Setting public permissions for nodejs12.x layer version ${njs12x_version} in ${region}"
		aws lambda add-layer-version-permission \
			--layer-name NewRelicNodeJS12X \
			--version-number "$njs12x_version" \
			--statement-id public \
			--action lambda:GetLayerVersion \
			--principal "*" \
			--region "$region"
		echo "Public permissions set for nodejs12.x layer version ${njs12x_version} in region ${region}"
	done
}

function build-nodejs14x-arm64 {
	echo "Building new relic layer for nodejs14.x (arm64)"
	rm -rf $BUILD_DIR $NJS14X_DIST_ARM64
	mkdir -p $DIST_DIR
	npm install --prefix $BUILD_DIR newrelic@latest
	mkdir -p $BUILD_DIR/node_modules/newrelic-lambda-wrapper
	cp index.js $BUILD_DIR/node_modules/newrelic-lambda-wrapper
	download-extension-arm64
	zip -rq $NJS14X_DIST_ARM64 $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
	rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
	echo "Build complete: ${NJS14X_DIST_ARM64}"
}

function build-nodejs14x-x86 {
	echo "Building new relic layer for nodejs14.x (x86_64)"
	rm -rf $BUILD_DIR $NJS14X_DIST_X86_64
	mkdir -p $DIST_DIR
	npm install --prefix $BUILD_DIR newrelic@latest
	mkdir -p $BUILD_DIR/node_modules/newrelic-lambda-wrapper
	cp index.js $BUILD_DIR/node_modules/newrelic-lambda-wrapper
	download-extension-x86
	zip -rq $NJS14X_DIST_X86_64 $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
	rm -rf $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
	echo "Build complete: ${NJS14X_DIST_X86_64}"
}

function publish-nodejs14x-arm64 {
	if [ ! -f $NJS14X_DIST_ARM64 ]; then
		echo "Package not found: ${NJS14X_DIST_ARM64}"
		exit 1
	fi

	njs14x_hash=$(md5sum $NJS14X_DIST_ARM64 | awk '{ print $1 }')
	njs14x_s3key="nr-nodejs14.x/${njs14x_hash}.arm64.zip"

	for region in "${REGIONS_ARCH[@]}"; do
		bucket_name="${BUCKET_PREFIX}-${region}"

		echo "Uploading ${NJS14X_DIST_ARM64} to s3://${bucket_name}/${njs14x_s3key}"
		aws --region "$region" s3 cp $NJS14X_DIST_ARM64 "s3://${bucket_name}/${njs14x_s3key}"

		echo "Publishing nodejs14.x layer to ${region}"
		njs14x_version=$(aws lambda publish-layer-version \
			--layer-name NewRelicNodeJS14XARM64 \
			--content "S3Bucket=${bucket_name},S3Key=${njs14x_s3key}" \
			--description "New Relic Layer for Node.js 14.x (arm64)" \
			--license-info "Apache-2.0" \
			--compatible-runtimes "nodejs14.x" \
			--compatible-architectures "arm64" \
			--region "$region" \
			--output text \
			--query Version)
		echo "published nodejs14.x layer version ${njs14x_version} to ${region}"

		echo "Setting public permissions for nodejs14.x layer version ${njs14x_version} in ${region}"
		aws lambda add-layer-version-permission \
			--layer-name NewRelicNodeJS14XARM64 \
			--version-number "$njs14x_version" \
			--statement-id public \
			--action lambda:GetLayerVersion \
			--principal "*" \
			--region "$region"
		echo "Public permissions set for nodejs14.x layer version ${njs14x_version} in region ${region}"
	done
}

function publish-nodejs14x-x86 {
	if [ ! -f $NJS14X_DIST_X86_64 ]; then
		echo "Package not found: ${NJS14X_DIST_X86_64}"
		exit 1
	fi

	njs14x_hash=$(md5sum $NJS14X_DIST_X86_64 | awk '{ print $1 }')
	njs14x_s3key="nr-nodejs14.x/${njs14x_hash}.x86_64.zip"

	for region in "${REGIONS_ARCH[@]}"; do
		bucket_name="${BUCKET_PREFIX}-${region}"

		echo "Uploading ${NJS14X_DIST_X86_64} to s3://${bucket_name}/${njs14x_s3key}"
		aws --region "$region" s3 cp $NJS14X_DIST_X86_64 "s3://${bucket_name}/${njs14x_s3key}"

		echo "Publishing nodejs14.x layer to ${region}"
		njs14x_version=$(aws lambda publish-layer-version \
			--layer-name NewRelicNodeJS14X \
			--content "S3Bucket=${bucket_name},S3Key=${njs14x_s3key}" \
			--description "New Relic Layer for Node.js 14.x (x86_64)" \
			--license-info "Apache-2.0" \
			--compatible-runtimes "nodejs14.x" \
			--compatible-architectures "x86_64" \
			--region "$region" \
			--output text \
			--query Version)
		echo "published nodejs14.x layer version ${njs14x_version} to ${region}"

		echo "Setting public permissions for nodejs14.x layer version ${njs14x_version} in ${region}"
		aws lambda add-layer-version-permission \
			--layer-name NewRelicNodeJS14X \
			--version-number "$njs14x_version" \
			--statement-id public \
			--action lambda:GetLayerVersion \
			--principal "*" \
			--region "$region"
		echo "Public permissions set for nodejs14.x layer version ${njs14x_version} in region ${region}"
	done

	# TODO: Remove this once all regions support --compatible-architectures
	for region in "${REGIONS_NO_ARCH[@]}"; do
		bucket_name="${BUCKET_PREFIX}-${region}"

		echo "Uploading ${NJS14X_DIST_X86_64} to s3://${bucket_name}/${njs14x_s3key}"
		aws --region "$region" s3 cp $NJS14X_DIST_X86_64 "s3://${bucket_name}/${njs14x_s3key}"

		echo "Publishing nodejs14.x layer to ${region}"
		njs14x_version=$(aws lambda publish-layer-version \
			--layer-name NewRelicNodeJS14X \
			--content "S3Bucket=${bucket_name},S3Key=${njs14x_s3key}" \
			--description "New Relic Layer for Node.js 14.x (x86_64)" \
			--license-info "Apache-2.0" \
			--compatible-runtimes "nodejs14.x" \
			--region "$region" \
			--output text \
			--query Version)
		echo "published nodejs14.x layer version ${njs14x_version} to ${region}"

		echo "Setting public permissions for nodejs14.x layer version ${njs14x_version} in ${region}"
		aws lambda add-layer-version-permission \
			--layer-name NewRelicNodeJS14X \
			--version-number "$njs14x_version" \
			--statement-id public \
			--action lambda:GetLayerVersion \
			--principal "*" \
			--region "$region"
		echo "Public permissions set for nodejs14.x layer version ${njs14x_version} in region ${region}"
	done
}

case "$1" in
"build-nodejs12x")
	build-nodejs12x-arm64
	build-nodejs12x-x86
	;;
"publish-nodejs12x")
	publish-nodejs12x-arm64
	publish-nodejs12x-x86
	;;
"build-nodejs14x")
	build-nodejs14x-arm64
	build-nodejs14x-x86
	;;
"publish-nodejs14x")
	publish-nodejs14x-arm64
	publish-nodejs14x-x86
	;;
"nodejs12x")
	$0 build-nodejs12.x
	$0 publish-nodejs12.x
	;;
"nodejs14x")
	$0 build-nodejs14x
	$0 publish-nodejs14x
	;;
*)
	usage
	;;
esac
