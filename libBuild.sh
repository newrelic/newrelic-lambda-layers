#!/usr/bin/env bash

set -Eeuo pipefail

# Regions that support arm64 architecture
REGIONS_ARM=(
	af-south-1
	ap-northeast-1
	ap-northeast-2
	ap-northeast-3
	ap-south-1
	ap-southeast-1
	ap-southeast-2
	ap-southeast-3
	ca-central-1
	eu-central-1
	eu-north-1
	eu-south-1
	eu-west-1
	eu-west-2
	eu-west-3
	me-south-1
	sa-east-1
	us-east-1
	us-east-2
	us-west-1
	us-west-2
)

REGIONS_X86=(
  af-south-1
  ap-northeast-1
  ap-northeast-2
  ap-northeast-3
  ap-south-1
  ap-south-2
  ap-southeast-1
  ap-southeast-2
  ap-southeast-3
  ap-southeast-4
  ca-central-1
  eu-central-1
  eu-central-2
  eu-north-1
  eu-south-1
  eu-south-2
  eu-west-1
  eu-west-2
  eu-west-3
  me-central-1
  me-south-1
  sa-east-1
  us-east-1
  us-east-2
  us-west-1
  us-west-2
)

EXTENSION_DIST_DIR=extensions
EXTENSION_DIST_ZIP=extension.zip
EXTENSION_DIST_PREVIEW_FILE=preview-extensions-ggqizro707

EXTENSION_VERSION=2.3.13

function list_all_regions {
    aws ec2 describe-regions \
      --all-regions \
      --query "Regions[].{Name:RegionName}" \
      --output text | sort
}

function fetch_extension {
    arch=$1

    url="https://github.com/newrelic/newrelic-lambda-extension/releases/download/v${EXTENSION_VERSION}/newrelic-lambda-extension.${arch}.zip"
    rm -rf $EXTENSION_DIST_DIR $EXTENSION_DIST_ZIP
    curl -L $url -o $EXTENSION_DIST_ZIP
}

function download_extension {
    fetch_extension $@

    unzip $EXTENSION_DIST_ZIP -d .
    rm -f $EXTENSION_DIST_ZIP
}

function layer_name_str() {
    rt_part="LambdaExtension"
    arch_part=""

    case $1 in
    "java8.al2")
      rt_part="Java8"
      ;;
    "java11")
      rt_part="Java11"
      ;;
    "java17")
      rt_part="Java17"
      ;;
    "java21")
      rt_part="Java21"
      ;;
    "python3.7")
      rt_part="Python37"
      ;;
    "python3.8")
      rt_part="Python38"
      ;;
    "python3.9")
      rt_part="Python39"
      ;;
    "python3.10")
      rt_part="Python310"
      ;;
    "python3.11")
      rt_part="Python311"
      ;;
    "python3.12")
      rt_part="Python312"
      ;;
    "nodejs18.x")
      rt_part="NodeJS18X"
      ;;
    "nodejs20.x")
      rt_part="NodeJS20X"
      ;;
    "ruby3.2")
      rt_part="Ruby32"
      ;;
    "ruby3.3")
      rt_part="Ruby33"
      ;;
    "dotnet")
      rt_part="Dotnet"
      ;;
    esac

    case $2 in
    "arm64")
      arch_part="ARM64"
      ;;
    "x86_64")
      arch_part=""
      ;;
    esac

    echo "NewRelic${rt_part}${arch_part}"
}

function s3_prefix() {
    name="nr-extension"

    case $1 in
    "java8.al2")
      name="java-8"
      ;;
    "java11")
      name="java-11"
      ;;
    "python3.7")
      name="nr-python3.7"
      ;;
    "python3.8")
      name="nr-python3.8"
      ;;
    "python3.9")
      name="nr-python3.9"
      ;;
    "python3.10")
      name="nr-python3.10"
      ;;
    "python3.11")
      name="nr-python3.11"
      ;;
    "python3.12")
      name="nr-python3.12"
      ;;
    "nodejs18.x")
      name="nr-nodejs18.x"
      ;;
    "nodejs20.x")
      name="nr-nodejs20.x"
      ;;
    "ruby3.3")
      name="nr-ruby3.3"
      ;;
    "dotnet")
      name="nr-dotnet"
      ;;
    esac

    echo $name
}

function hash_file() {
    if command -v md5sum &> /dev/null ; then
        md5sum $1 | awk '{ print $1 }'
    else
        md5 -q $1
    fi
}

function publish_layer {
    layer_archive=$1
    region=$2
    runtime_name=$3
    arch=$4

    layer_name=$( layer_name_str $runtime_name $arch )

    hash=$( hash_file $layer_archive | awk '{ print $1 }' )

    bucket_name="nr-layers-${region}"
    s3_key="$( s3_prefix $runtime_name )/${hash}.${arch}.zip"

    compat_list=( $runtime_name )
    if [[ $runtime_name == "provided" ]]
    then compat_list=("provided" "provided.al2" "provided.al2023" "dotnetcore3.1")
    fi

    if [[ $runtime_name == "dotnet" ]]
    then compat_list=("dotnet6" "dotnet8")
    fi

    echo "Uploading ${layer_archive} to s3://${bucket_name}/${s3_key}"
    aws --region "$region" s3 cp $layer_archive "s3://${bucket_name}/${s3_key}"

   if [[ ${REGIONS_ARM[*]} =~ $region ]];
   then arch_flag="--compatible-architectures $arch"
   else arch_flag=""
   fi

    echo "Publishing ${runtime_name} layer to ${region}"
    layer_version=$(aws lambda publish-layer-version \
      --layer-name ${layer_name} \
      --content "S3Bucket=${bucket_name},S3Key=${s3_key}" \
      --description "New Relic Layer for ${runtime_name} (${arch})" \
      --license-info "Apache-2.0" $arch_flag \
      --compatible-runtimes ${compat_list[*]} \
      --region "$region" \
      --output text \
      --query Version)
    echo "Published ${runtime_name} layer version ${layer_version} to ${region}"

    echo "Setting public permissions for ${runtime_name} layer version ${layer_version} in ${region}"
    aws lambda add-layer-version-permission \
      --layer-name ${layer_name} \
      --version-number "$layer_version" \
      --statement-id public \
      --action lambda:GetLayerVersion \
      --principal "*" \
      --region "$region"
    echo "Public permissions set for ${runtime_name} layer version ${layer_version} in region ${region}"

}


function publish_docker_ecr {
    layer_archive=$1
    runtime_name=$2
    arch=$3

    if [[ ${arch} =~ 'arm64' ]];
    then arch_flag="-arm64"
    else arch_flag=""
    fi

    version_flag=$(echo "$runtime_name" | sed 's/[^0-9]//g')
    language_flag=$(echo "$runtime_name" | sed 's/[0-9].*//')

    if [[ ${runtime_name} =~ 'extension' ]]; then
    version_flag=$EXTENSION_VERSION
    language_flag="lambdaextension"
    fi
    
    if [[ ${runtime_name} =~ 'dotnet' ]]; then
    version_flag=""
    arch_flag=${arch}
    fi

    # Remove 'dist/' prefix
    if [[ $layer_archive == dist/* ]]; then
      file_without_dist="${layer_archive#dist/}"
      echo "File without 'dist/': $file_without_dist"
    else
      file_without_dist=$layer_archive
      echo "File does not start with 'dist/': $file_without_dist"
    fi

    # public ecr repository name 
    # maintainer can use this("q6k3q1g1") repo name for testing 
    repository="x6n7b2o2"

    # copy dockerfile
    cp ../Dockerfile.ecrImage .

    echo "Running : aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/${repository}"
    aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/${repository}

    echo "docker build -t layer-nr-image-${language_flag}-${version_flag}${arch_flag}:latest \
    -f Dockerfile.ecrImage \
    --build-arg layer_zip=${layer_archive} \
    --build-arg file_without_dist=${file_without_dist} \
    ."

    docker build -t layer-nr-image-${language_flag}-${version_flag}${arch_flag}:latest \
    -f Dockerfile.ecrImage \
    --build-arg layer_zip=${layer_archive} \
    --build-arg file_without_dist=${file_without_dist} \
    .

    echo "docker tag layer-nr-image-${language_flag}-${version_flag}${arch_flag}:latest public.ecr.aws/${repository}/newrelic-lambda-layers-${language_flag}:${version_flag}${arch_flag}"
    docker tag layer-nr-image-${language_flag}-${version_flag}${arch_flag}:latest public.ecr.aws/${repository}/newrelic-lambda-layers-${language_flag}:${version_flag}${arch_flag}
    echo "docker push public.ecr.aws/${repository}/newrelic-lambda-layers-${language_flag}:${version_flag}${arch_flag}"
    docker push public.ecr.aws/${repository}/newrelic-lambda-layers-${language_flag}:${version_flag}${arch_flag}

    # delete dockerfile
    rm -rf Dockerfile.ecrImage
}

function publish_docker_hub {
  layer_archive=$1
  runtime_name=$2
  arch=$3
  if [[ ${arch} =~ 'arm64' ]];
  then arch_flag="-arm64"
  else arch_flag=""
  fi
  version_flag=$(echo "$runtime_name" | sed 's/[^0-9]//g')
  language_flag=$(echo "$runtime_name" | sed 's/[0-9].*//')
  # Remove 'dist/' prefix
  if [[ $layer_archive == dist/* ]]; then
    file_without_dist="${layer_archive#dist/}"
    echo "File without 'dist/': $file_without_dist"
  else
    file_without_dist=$layer_archive
    echo "File does not start with 'dist/': $file_without_dist"
  fi

  # copy dockerfile
  cp ../Dockerfile.ecrImage .
  echo "docker build -t ${language_flag}-${version_flag}${arch_flag}:latest \
  -f Dockerfile.ecrImage \
  --build-arg layer_zip=${layer_archive} \
  --build-arg file_without_dist=${file_without_dist} \
  ."
  docker build -t ${language_flag}-${version_flag}${arch_flag}:latest \
  -f Dockerfile.ecrImage \
  --build-arg layer_zip=${layer_archive} \
  --build-arg file_without_dist=${file_without_dist} \
  .
  echo "docker tag ${language_flag}-${version_flag}${arch_flag}:latest newrelic/newrelic-lambda-layers:${language_flag}-${version_flag}${arch_flag}"
  docker tag ${language_flag}-${version_flag}${arch_flag}:latest newrelic/newrelic-lambda-layers:${language_flag}-${version_flag}${arch_flag}
  echo "docker push newrelic/newrelic-lambda-layers:${language_flag}-${version_flag}${arch_flag}"
  docker push newrelic/newrelic-lambda-layers:${language_flag}-${version_flag}${arch_flag}
}
