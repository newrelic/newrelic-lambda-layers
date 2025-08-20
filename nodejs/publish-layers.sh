#!/usr/bin/env bash

set -Eeuo pipefail

BUILD_DIR=nodejs
DIST_DIR=dist

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
  npm install --prefix $BUILD_DIR newrelic@latest
  if [ "$slim" == "slim" ]; then
    echo "Slim build, removing opentelemetry dependencies"
    rm -rf $BUILD_DIR/node_modules/@opentelemetry
    create_otel_stub_package() {
    local package_name=$1
    local package_dir="$BUILD_DIR/node_modules/@opentelemetry/$package_name"
    
    mkdir -p "$package_dir"
    
    # Create package.json
    cat > "$package_dir/package.json" << EOF
{
  "name": "@opentelemetry/$package_name",
  "version": "1.0.0-stub",
  "description": "Stub implementation to prevent OTEL dependency errors",
  "main": "index.js",
  "types": "index.d.ts"
}
EOF
    
    cp otel-stub-package.js "$package_dir/index.js"
    cp otel-stub-types.d.ts "$package_dir/index.d.ts"
  }
  create_otel_stub_package "api"
  create_otel_stub_package "api-logs"
  create_otel_stub_package "sdk-trace-base"
  create_otel_stub_package "core"
  create_otel_stub_package "resources"
  create_otel_stub_package "semantic-conventions"
  create_otel_stub_package "sdk-metrics"
  create_otel_stub_package "sdk-logs"
  create_otel_stub_package "exporter-metrics-otlp-http"
  create_otel_stub_package "exporter-metrics-otlp-proto"
  create_otel_stub_package "otlp-exporter-base"
  create_otel_stub_package "otlp-transformer"
  
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

  for region in "${REGIONS[@]}"; do
    publish_layer $ZIP $region nodejs${node_version}.x ${arch} $NEWRELIC_AGENT_VERSION $slim
  done
}

case "$1" in
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
"build-publish-20-ecr-image")
  build_wrapper 20 arm64 
	publish_docker_ecr $DIST_DIR/nodejs20x.arm64.zip nodejs20.x arm64
  build_wrapper 20 x86_64 
	publish_docker_ecr $DIST_DIR/nodejs20x.x86_64.zip nodejs20.x x86_64
	;;
"build-publish-22-ecr-image")
  build_wrapper 22 arm64 
	publish_docker_ecr $DIST_DIR/nodejs22x.arm64.zip nodejs22.x arm64
  build_wrapper 22 x86_64 
	publish_docker_ecr $DIST_DIR/nodejs22x.x86_64.zip nodejs22.x x86_64
	;;
"nodejs20")
  $0 build-20
  $0 publish-20
  ;;
"nodejs22")
  $0 build-22
  $0 publish-22
  ;;
*)
	usage
	;;
esac