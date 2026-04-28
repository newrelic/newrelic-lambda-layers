#!/usr/bin/env bash

set -Eeuo pipefail

BUILD_DIR=nodejs
DIST_DIR=${DIST_DIR:-dist}

source ../libBuild.sh

function usage {
  	echo "./publish-layers.sh [build-20|build-22|publish-20|publish-22]"
}

function make_package_json {
cat <<EOM >fake-package.json
{
  "name": "newrelic-esm-lambda-wrapper",
  "type": "module"
}
EOM
}

function build_universal_wrapper {
  arch=$1
  slim=${2:-""}
  echo "Building universal new relic layer for nodejs (${arch})"
  ZIP=$DIST_DIR/nodejs.${arch}.zip
  if [ "$slim" == "slim" ]; then
    ZIP=$DIST_DIR/nodejs.${arch}.slim.zip
  fi
  rm -rf $BUILD_DIR $ZIP
  mkdir -p $DIST_DIR
  npm install --install-strategy=nested --prefix $BUILD_DIR newrelic@latest
  if [ "$slim" == "slim" ]; then
    echo "Slim build, removing opentelemetry dependencies"
    rm -rf $BUILD_DIR/node_modules/newrelic/node_modules/@opentelemetry
  fi
  NEWRELIC_AGENT_VERSION=$(npm list newrelic --prefix $BUILD_DIR | grep newrelic@ | awk -F '@' '{print $2}')
  touch $DIST_DIR/nr-env
  echo "NEWRELIC_AGENT_VERSION=$NEWRELIC_AGENT_VERSION" > $DIST_DIR/nr-env
	mkdir -p $BUILD_DIR/node_modules/newrelic-lambda-wrapper
  cp index.js $BUILD_DIR/node_modules/newrelic-lambda-wrapper
	mkdir -p $BUILD_DIR/node_modules/newrelic-esm-lambda-wrapper
  cp esm.mjs $BUILD_DIR/node_modules/newrelic-esm-lambda-wrapper/index.js
  make_package_json
  cp fake-package.json $BUILD_DIR/node_modules/newrelic-esm-lambda-wrapper/package.json
  download_extension $arch
	zip -rq $ZIP $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
	rm -rf fake-package.json $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
	echo "Build complete: ${ZIP}"
}

function publish_universal_wrapper {
  arch=$1
  slim=${2:-""}
  ZIP=$DIST_DIR/nodejs.${arch}.zip
  if [ "$slim" == "slim" ]; then
    echo "Publishing universal slim build for nodejs (${arch})"
    ZIP=$DIST_DIR/nodejs.${arch}.slim.zip
  fi
  source $DIST_DIR/nr-env
  if [ ! -f $ZIP ]; then
    echo "Package not found: ${ZIP}"
    exit 1
  fi

  run_region_loop "$ZIP" nodejs "${arch}" "$NEWRELIC_AGENT_VERSION" "$slim"
}

function build_wrapper {
  node_version=$1
  arch=$2
  slim=${3:-""}
  echo "Building new relic layer for nodejs${node_version}.x (${arch})"
  ZIP=$DIST_DIR/nodejs${node_version}x.${arch}.zip
  if [ "$slim" == "slim" ]; then
    ZIP=$DIST_DIR/nodejs${node_version}x.${arch}.slim.zip
  fi
  rm -rf $BUILD_DIR $ZIP
  mkdir -p $DIST_DIR
  npm install --install-strategy=nested --prefix $BUILD_DIR newrelic@latest
  if [ "$slim" == "slim" ]; then
    echo "Slim build, removing opentelemetry dependencies"
    rm -rf $BUILD_DIR/node_modules/newrelic/node_modules/@opentelemetry
  fi
  # Profiilng is not supported in lambda functions, we will remove the dep as it is 11mb
  rm -rf $BUILD_DIR/node_modules/newrelic/node_modules/@datadog/pprof
  NEWRELIC_AGENT_VERSION=$(npm list newrelic --prefix $BUILD_DIR | grep newrelic@ | awk -F '@' '{print $2}')
  touch $DIST_DIR/nr-env
  echo "NEWRELIC_AGENT_VERSION=$NEWRELIC_AGENT_VERSION" > $DIST_DIR/nr-env
	mkdir -p $BUILD_DIR/node_modules/newrelic-lambda-wrapper
  cp index.js $BUILD_DIR/node_modules/newrelic-lambda-wrapper
	mkdir -p $BUILD_DIR/node_modules/newrelic-esm-lambda-wrapper
  cp esm.mjs $BUILD_DIR/node_modules/newrelic-esm-lambda-wrapper/index.js
  make_package_json
  cp fake-package.json $BUILD_DIR/node_modules/newrelic-esm-lambda-wrapper/package.json
  download_extension $arch
	zip -rq $ZIP $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
	rm -rf fake-package.json $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE
	echo "Build complete: ${ZIP}"
}

function publish_wrapper {
  node_version=$1
  arch=$2
  slim=${3:-""}
  ZIP=$DIST_DIR/nodejs${node_version}x.${arch}.zip
  if [ "$slim" == "slim" ]; then
    echo "Publishing slim build for nodejs${node_version}.x (${arch})"
    ZIP=$DIST_DIR/nodejs${node_version}x.${arch}.slim.zip
  fi
  source $DIST_DIR/nr-env
  if [ ! -f $ZIP ]; then
    echo "Package not found: ${ZIP}"
    exit 1
  fi

  run_region_loop "$ZIP" "nodejs${node_version}.x" "${arch}" "$NEWRELIC_AGENT_VERSION" "$slim"
}

# Publish staging layers for a given node version (us-east-1, -staging suffix).
# Writes arn_x86/arn_arm64/arn_x86_slim/arn_arm64_slim to $GITHUB_OUTPUT.
function publish_staging_wrapper {
  node_version=$1
  source $DIST_DIR/nr-env

  for arch in x86_64 arm64; do
    ZIP=$DIST_DIR/nodejs${node_version}x.${arch}.zip
    ZIP_SLIM=$DIST_DIR/nodejs${node_version}x.${arch}.slim.zip
    if [ ! -f "$ZIP" ]; then echo "Package not found: ${ZIP}"; exit 1; fi
    if [ ! -f "$ZIP_SLIM" ]; then echo "Package not found: ${ZIP_SLIM}"; exit 1; fi

    arn=$(publish_staging_layer "$ZIP" nodejs${node_version}.x "$arch" "$NEWRELIC_AGENT_VERSION")
    arn_slim=$(publish_staging_layer "$ZIP_SLIM" nodejs${node_version}.x "$arch" "$NEWRELIC_AGENT_VERSION" slim)

    if [[ $arch == "x86_64" ]]; then
      echo "arn_x86=${arn}"           >> "${GITHUB_OUTPUT:-/dev/stderr}"
      echo "arn_x86_slim=${arn_slim}" >> "${GITHUB_OUTPUT:-/dev/stderr}"
    else
      echo "arn_arm64=${arn}"           >> "${GITHUB_OUTPUT:-/dev/stderr}"
      echo "arn_arm64_slim=${arn_slim}" >> "${GITHUB_OUTPUT:-/dev/stderr}"
    fi
  done
}

# Delete the 4 staging layer versions published by publish_staging_wrapper.
# Reads ARNs from env vars: ARN_X86, ARN_ARM64, ARN_X86_SLIM, ARN_ARM64_SLIM.
function cleanup_staging_wrapper {
  for arn in "${ARN_X86:-}" "${ARN_ARM64:-}" "${ARN_X86_SLIM:-}" "${ARN_ARM64_SLIM:-}"; do
    [[ -z "$arn" ]] && continue
    layer_name=$(echo "$arn" | cut -d: -f8)
    version=$(echo "$arn"    | cut -d: -f9)
    delete_staging_layer "$layer_name" "$version"
  done
}

case "$1" in
"build-universal")
  build_universal_wrapper arm64
  build_universal_wrapper x86_64
  build_universal_wrapper arm64 slim
  build_universal_wrapper x86_64 slim
	;;
"publish-universal")
  publish_universal_wrapper arm64
  publish_universal_wrapper x86_64
  publish_universal_wrapper arm64 slim
  publish_universal_wrapper x86_64 slim
	;;
"build-publish-universal-ecr-image")
  build_universal_wrapper arm64
	publish_ecr_safe $DIST_DIR/nodejs.arm64.zip nodejs arm64
  build_universal_wrapper arm64 slim
	publish_ecr_safe $DIST_DIR/nodejs.arm64.slim.zip nodejs arm64 slim
  build_universal_wrapper x86_64
	publish_ecr_safe $DIST_DIR/nodejs.x86_64.zip nodejs x86_64
  build_universal_wrapper x86_64 slim
	publish_ecr_safe $DIST_DIR/nodejs.x86_64.slim.zip nodejs x86_64 slim
  finalize_ecr_results "nodejs-universal"
	;;
"nodejs")
  $0 build-universal
  $0 publish-universal
  ;;
"build_wrapper")
  build_wrapper $2 $3 $4
  ;;
"publish_wrapper")
  publish_wrapper $2 $3
  ;;
"build-20")
  build_wrapper 20 arm64 
  build_wrapper 20 x86_64 
  build_wrapper 20 arm64 slim
  build_wrapper 20 x86_64 slim
	;;
"publish-20")
  publish_wrapper 20 arm64
  publish_wrapper 20 x86_64 
  publish_wrapper 20 arm64 slim
  publish_wrapper 20 x86_64 slim
	;;
"build-22")
  build_wrapper 22 arm64 
  build_wrapper 22 x86_64 
  build_wrapper 22 arm64 slim
  build_wrapper 22 x86_64 slim
	;;
"publish-22")
  publish_wrapper 22 arm64
  publish_wrapper 22 x86_64 
  publish_wrapper 22 arm64 slim
  publish_wrapper 22 x86_64 slim
	;;
"build-24")
  build_wrapper 24 arm64 
  build_wrapper 24 x86_64 
  build_wrapper 24 arm64 slim
  build_wrapper 24 x86_64 slim
	;;
"publish-24")
  publish_wrapper 24 arm64
  publish_wrapper 24 x86_64 
  publish_wrapper 24 arm64 slim
  publish_wrapper 24 x86_64 slim
	;;
"build-publish-20-ecr-image")
  build_wrapper 20 arm64
	publish_ecr_safe $DIST_DIR/nodejs20x.arm64.zip nodejs20.x arm64
  build_wrapper 20 arm64 slim
	publish_ecr_safe $DIST_DIR/nodejs20x.arm64.slim.zip nodejs20.x arm64 slim
  build_wrapper 20 x86_64
	publish_ecr_safe $DIST_DIR/nodejs20x.x86_64.zip nodejs20.x x86_64
  build_wrapper 20 x86_64 slim
	publish_ecr_safe $DIST_DIR/nodejs20x.x86_64.slim.zip nodejs20.x x86_64 slim
  finalize_ecr_results "nodejs20.x"
	;;
"build-publish-22-ecr-image")
  build_wrapper 22 arm64
	publish_ecr_safe $DIST_DIR/nodejs22x.arm64.zip nodejs22.x arm64
  build_wrapper 22 arm64 slim
	publish_ecr_safe $DIST_DIR/nodejs22x.arm64.slim.zip nodejs22.x arm64 slim
  build_wrapper 22 x86_64
	publish_ecr_safe $DIST_DIR/nodejs22x.x86_64.zip nodejs22.x x86_64
  build_wrapper 22 x86_64 slim
	publish_ecr_safe $DIST_DIR/nodejs22x.x86_64.slim.zip nodejs22.x x86_64 slim
  finalize_ecr_results "nodejs22.x"
	;;
"build-publish-24-ecr-image")
  build_wrapper 24 arm64
	publish_ecr_safe $DIST_DIR/nodejs24x.arm64.zip nodejs24.x arm64
  build_wrapper 24 arm64 slim
	publish_ecr_safe $DIST_DIR/nodejs24x.arm64.slim.zip nodejs24.x arm64 slim
  build_wrapper 24 x86_64
	publish_ecr_safe $DIST_DIR/nodejs24x.x86_64.zip nodejs24.x x86_64
  build_wrapper 24 x86_64 slim
	publish_ecr_safe $DIST_DIR/nodejs24x.x86_64.slim.zip nodejs24.x x86_64 slim
  finalize_ecr_results "nodejs24.x"
	;;
"nodejs20")
  $0 build-20
  $0 publish-20
  ;;
"nodejs22")
  $0 build-22
  $0 publish-22
  ;;
"nodejs24")
  $0 build-24
  $0 publish-24
  ;;
"publish-staging-20")
  publish_staging_wrapper 20
  ;;
"publish-staging-22")
  publish_staging_wrapper 22
  ;;
"publish-staging-24")
  publish_staging_wrapper 24
  ;;
"cleanup-staging-20")
  cleanup_staging_wrapper
  ;;
"cleanup-staging-22")
  cleanup_staging_wrapper
  ;;
"cleanup-staging-24")
  cleanup_staging_wrapper
  ;;
*)
	usage
	;;
esac
