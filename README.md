[![Community Plus header](https://github.com/newrelic/opensource-website/raw/master/src/images/categories/Community_Plus.png)](https://opensource.newrelic.com/oss-category/#community-plus)

# New Relic Lambda Layers

This repository contains source code and utilities to build and publish New Relic's public AWS Lambda layers.

Most users should use our published layers which are chosen automatically via the [CLI tool](https://github.com/newrelic/newrelic-lambda-cli). Those layers are published to be public and are available [here](https://nr-layers.iopipe.com).

This tool is released for users seeking to deploy their own copies of the New Relic Lambda Layers into their accounts, or to modify and publish their own customized wrapper layers.

## Requirements:

* aws-cli
* bash shell

The AWS cli must be configured, please refer to its [documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html).

## Publishing Layers:

Run the following in your shell:

```
cd python
./publish-layers.sh
cd ..
```

```
cd nodejs;
./publish-layers.sh
cd ..
```

```
cd java;
./publish-layers.sh
cd ..
```

```
cd extension;
./publish-layer.sh
cd ..
```

## Attaching Custom Lambda Layer ARNs

The layers published to your account may be used directly within SAM, Cloudformation Templates, Serverless.yml, or other configuration methods that allow specifying the use of layers by ARN.

New Relic Serverless APM customers are advised to use the [newrelic-lambda-cli tool](https://github.com/newrelic/newrelic-lambda-cli), and this may be used with custom layers as follows by adding the `--layer-arn` flag to the layers install command:

```
newrelic-lambda layers install \
    --function <name or arn> \
    --nr-account-id <new relic account id>
    --layer-arn <YOUR_CUSTOM_LAYER_ARN>
```

## Manual Instrumentation using Layers:

We recommend using the [newrelic-lambda-cli tool](https://github.com/newrelic/newrelic-lambda-cli), but some users find that they need, or prefer to manually configure their functions.

These steps will help you configure the layers correctly:

1. Find the New Relic AWS Lambda Layer ARN that matches your runtime and region.
2. Copy the ARN of the most recent AWS Lambda Layer version and attach it to your function.
  * Using Cloudformation, this refers to adding your layer arn to the Layers property of a [AWS::Lambda::Function resource](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-lambda-function.html).
3. Update your functions handler to point to the newly attached layer in the console for your function:
  * Python: `newrelic_lambda_wrapper.handler`
  * Node: `newrelic-lambda-wrapper.handler`
  * Java:
    * RequestHandler implementation: `com.newrelic.java.HandlerWrapper::handleRequest`
    * RequestStreamHandlerWrapper implementation: `com.newrelic.java.HandlerWrapper::handleStreamsRequest`
4. Add these environment variables to your Lambda console:
  * NEW_RELIC_ACCOUNT_ID: Your New Relic account ID
  * NEW_RELIC_LAMBDA_HANDLER: Path to your initial handler.

Refer to the [New Relic AWS Lambda Monitoring Documentation](https://docs.newrelic.com/docs/serverless-function-monitoring/aws-lambda-monitoring/get-started/enable-new-relic-monitoring-aws-lambda) for instructions on completing your configuration by linking your AWS Account and Cloudwatch Log Streams to New Relic.

## Support for ES Modules (Node.js)

In January 2022, AWS announced support for ECMAScript in Lambda and ECMAScript modules as dependencies. The New Relic Node Agent introduced experimental support for ES Modules in version 9.1.0. Unfortunately, Lambda functions do not yet support loading ES Module dependencies from Lambda Layers, as [`import` specifiers don't resolve with `NODE_PATH`](https://nodejs.org/docs/latest-v16.x/api/esm.html#no-node_path). 

If your Lambda functions are written using ES modules, you can still instrument them with New Relic, but you will need to do the following: 

1. [instrument your function manually](https://docs.newrelic.com/docs/serverless-function-monitoring/aws-lambda-monitoring/enable-lambda-monitoring/enable-serverless-monitoring-aws-lambda-legacy#node) using our [Node Agent](https://github.com/newrelic/node-newrelic/)  
2. On deploying your function, don't set the function handler to our Node wrapper; instead, use your regular handler function, which you've wrapped with `newrelic.setLambdaHandler()`. 
3. Install our Extension-only Lambda Layer for delivering telemetry. Use our [layer discovery website](https://layers.newrelic-external.com/) to find the ARN for your region. Look for either NewRelicLambdaExtension or NewRelicLambdaExtensionARM64 (depending on your function's architecture). 
4. Add your `NEW_RELIC_LICENSE_KEY` as an environment variable.

You may see some warnings from the Extension in CloudWatch logs referring to a non-standard handler; these may be ignored, since you've wrapped manually.
