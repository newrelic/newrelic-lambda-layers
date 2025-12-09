#!/usr/bin/env bash

set -Eeuo pipefail

REGIONS=(
  sa-east-1
  me-central-1
  me-south-1
  eu-central-2
  eu-north-1
  eu-south-2
  eu-west-3
  eu-south-1
  eu-west-2
  eu-west-1
  eu-central-1
  ca-central-1
  ap-northeast-1
  ap-southeast-2
  ap-southeast-1
  ap-northeast-2
  ap-northeast-3
  ap-south-1
  ap-south-2
  ap-southeast-4
  ap-southeast-3
  af-south-1
  us-east-1
	us-east-2
	us-west-1
	us-west-2
)

EXTENSION_DIST_DIR=extensions
EXTENSION_DIST_ZIP=extension.zip
EXTENSION_DIST_PREVIEW_FILE=preview-extensions-ggqizro707

EXTENSION_VERSION=2.3.24

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
    "python3.13")
      rt_part="Python313"
      ;;
    "python3.14")
      rt_part="Python314"
      ;;
    "nodejs20.x")
      rt_part="NodeJS20X"
      ;;
    "nodejs22.x")
      rt_part="NodeJS22X"
      ;;
    "nodejs24.x")
      rt_part="NodeJS24X"
      ;;
    "ruby3.2")
      rt_part="Ruby32"
      ;;
    "ruby3.3")
      rt_part="Ruby33"
      ;;
    "ruby3.4")
      rt_part="Ruby34"
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
    "python3.13")
      name="nr-python3.13"
      ;;
    "python3.14")
      name="nr-python3.14"
      ;;
    "nodejs20.x")
      name="nr-nodejs20.x"
      ;;
    "nodejs22.x")
      name="nr-nodejs22.x"
      ;;
    "nodejs24.x")
      name="nr-nodejs24.x"
      ;;
    "ruby3.3")
      name="nr-ruby3.3"
      ;;
    "ruby3.4")
      name="nr-ruby3.4"
      ;;
    "dotnet")
      name="nr-dotnet"
      ;;
    esac

    echo $name
}

function agent_name_str() {
    local runtime=$1
    local agent_name
   
    case $runtime in
        "provided")
            agent_name="provided"
            ;;
        "dotnet")
            agent_name="Dotnet"
            ;;
        "nodejs20.x"|"nodejs22.x"|"nodejs24.x")
            agent_name="Node"
            ;;
        "ruby3.2"|"ruby3.3"|"ruby3.4")
            agent_name="Ruby"
            ;;
        "java8.al2"|"java11"|"java17"|"java21")
            agent_name="Java"
            ;;
        "python3.9"|"python3.10"|"python3.11"|"python3.12"|"python3.13"|"python3.14")
            agent_name="Python"
            ;;
        *)
            agent_name="none"
            ;;
    esac

    echo $agent_name
}

function hash_file() {
    if command -v md5sum &> /dev/null ; then
        md5sum $1 | awk '{ print $1 }'
    else
        md5 -q $1
    fi
}

function publish_public_layer {
  layer_name=$1
  bucket_name=$2
  s3_key=$3
  description=$4
  arch_flag=$5
  region=$6
  runtime_name=$7
  compat_list=("${@:8}")


  layer_version=$(aws lambda publish-layer-version \
    --layer-name ${layer_name} \
    --content "S3Bucket=${bucket_name},S3Key=${s3_key}" \
    --description "${description}"\
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


function publish_layer {
    layer_archive=$1
    region=$2
    runtime_name=$3
    arch=$4
    newrelic_agent_version=${5:-"none"}
    slim=${6:-""}
    agent_name=$( agent_name_str $runtime_name )
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

   if [[ ${REGIONS[*]} =~ $region ]];
   then arch_flag="--compatible-architectures $arch"
   else arch_flag=""
   fi

    base_description="New Relic Layer for ${runtime_name} (${arch})"
    extension_info=" with New Relic Extension v${EXTENSION_VERSION}"
    
    if [[ $newrelic_agent_version != "none" ]]; then
        if [[ $agent_name != "provided" ]]; then
            agent_info=" and ${agent_name} agent v${newrelic_agent_version}"
        else
            base_description="New Relic Layer for OS only runtime (${arch})"
            agent_info=""
        fi

        description="${base_description}${extension_info}${agent_info}"
    else
        if [[ $agent_name == "Java" ]]; then
            description="${base_description}${extension_info}"
        else
            description="${base_description}."
        fi
    fi

    echo "Publishing ${runtime_name} layer to ${region}"
    if [[ $slim == "slim" ]]; then
        echo "Publishing ${runtime_name} slim layer to ${region}"
        layer_name="${layer_name}-slim"
        base_description="New Relic slim Layer without opentelemetry for ${runtime_name} (${arch})"
        description="${base_description}${extension_info}${agent_info}"
    fi
    publish_public_layer $layer_name $bucket_name $s3_key "$description" "$arch_flag" "$region" "$runtime_name" "${compat_list[@]}"

}


function publish_docker_ecr {
    layer_archive=$1
    runtime_name=$2
    arch=$3
    slim=${4:-""}

    if [[ ${arch} =~ 'arm64' ]];
    then 
        arch_flag="-arm64"
        platform="linux/arm64"
    else 
        arch_flag=""
        platform="linux/amd64"
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
    slim_flag=""
    if [ "$slim" == "slim" ]; then
        slim_flag="-slim"
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

    echo "docker buildx build --platform ${platform} -t layer-nr-image-${language_flag}-${version_flag}${arch_flag}${slim}:latest \
    -f Dockerfile.ecrImage \
    --build-arg layer_zip=${layer_archive} \
    --build-arg file_without_dist=${file_without_dist} \
    ."

    docker buildx build --platform ${platform} -t layer-nr-image-${language_flag}-${version_flag}${arch_flag}${slim}:latest \
    -f Dockerfile.ecrImage \
    --build-arg layer_zip=${layer_archive} \
    --build-arg file_without_dist=${file_without_dist} \
    .

    echo "docker tag layer-nr-image-${language_flag}-${version_flag}${arch_flag}${slim}:latest public.ecr.aws/${repository}/newrelic-lambda-layers-${language_flag}${slim_flag}:${version_flag}${arch_flag}"
    docker tag layer-nr-image-${language_flag}-${version_flag}${arch_flag}${slim}:latest public.ecr.aws/${repository}/newrelic-lambda-layers-${language_flag}${slim_flag}:${version_flag}${arch_flag}
    echo "docker push public.ecr.aws/${repository}/newrelic-lambda-layers-${language_flag}${slim_flag}:${version_flag}${arch_flag}"
    docker push public.ecr.aws/${repository}/newrelic-lambda-layers-${language_flag}${slim_flag}:${version_flag}${arch_flag}

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
