[![Community Plus header](https://github.com/newrelic/opensource-website/raw/main/src/images/categories/Community_Plus.png)](https://opensource.newrelic.com/oss-category/#community-plus)

# New Relic Lambda Layers

This repository contains source code and utilities to build and publish New Relic's public AWS Lambda layers.

Most users should use our published layers which are chosen automatically via the [CLI tool](https://github.com/newrelic/newrelic-lambda-cli). Those layers are published to be public and are available [here](https://layers.newrelic-external.com/).

This tool is released for users seeking to deploy their own copies of the New Relic Lambda Layers into their accounts, or to modify and publish their own customized wrapper layers.

## Requirements:

* aws-cli
* bash shell

The AWS cli must be configured, please refer to its [documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html).

## Publishing Layers:
To publish the layer, modify the runtime according to the options provided in the `.publish-layers.sh` script. Then, run the following command in your shell:

```
cd python
./publish-layers.sh python3.12 
cd ..
```

```
cd nodejs
./publish-layers.sh nodejs20 
cd ..
```

```
cd ruby
./publish-layers.sh ruby3.3 
cd ..
```

```
cd java
./publish-layers.sh java21
cd ..
```

```
cd dotnet
./publish-layers.sh
cd ..
```

```
cd extension
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
  * Node: 
    * CommonJS: `newrelic-lambda-wrapper.handler`
    * ESM: `newrelic-esm-lambda-wrapper.handler`
  * Ruby: `newrelic_lambda_wrapper.handler`
  * Java:
    * RequestHandler implementation: `com.newrelic.java.HandlerWrapper::handleRequest`
    * RequestStreamHandlerWrapper implementation: `com.newrelic.java.HandlerWrapper::handleStreamsRequest`
  * .NET: This step is not required.
4. Add these environment variables to your Lambda console:
  * NEW_RELIC_ACCOUNT_ID: Your New Relic account ID
  * NEW_RELIC_LAMBDA_HANDLER: Path to your initial handler.
  * NEW_RELIC_USE_ESM: For Node.js handlers using ES Modules, set to `true`.
  * CORECLR_ENABLE_PROFILING (.NET only): 1
  * CORECLR_PROFILER (.NET only): {36032161-FFC0-4B61-B559-F6C5D41BAE5A}
  * CORECLR_NEWRELIC_HOME (.NET only): /opt/lib/newrelic-dotnet-agent
  * CORECLR_PROFILER_PATH (.NET only): /opt/lib/newrelic-dotnet-agent/libNewRelicProfiler.so

Refer to the [New Relic AWS Lambda Monitoring Documentation](https://docs.newrelic.com/docs/serverless-function-monitoring/aws-lambda-monitoring/get-started/enable-new-relic-monitoring-aws-lambda) for instructions on completing your configuration by linking your AWS Account and Cloudwatch Log Streams to New Relic.

## Support for ES Modules (Node.js)

AWS announced support for Node 18 as a Lambda runtime in late 2022, introducing `aws-sdk` version 3 for Node 18 only. This version of `aws-sdk` patches `NODE_PATH`, so ESM-supporting functions using `import` and top-level `await` should work as expected with Lambda Layer releases `v9.8.1.1` and above (Numerical layer versions vary by region and runtime). To configure the layer to leverage `import`, add this environment variable to use our ESM loader: `NODE_OPTIONS: --experimental-loader newrelic/esm-loader.mjs`. **Note**: The function handler should also use `newrelic-esm-lambda-wrapper.handler`.

### Note on performance for ES Module functions

In order to wrap ESM functions without a code change, our wrapper awaits the completion of a dynamic import. If your ESM function depends on a large number of dependency and file imports, you may see long cold start times as a result. As a workaround, we recommend instrumenting manually, following the instructions below.

### Manual instrumentation for ES Modules

First import the New Relic Node agent into your handler file:

```javascript
import newrelic from 'newrelic'
```

Then wrap your handler function using the `.setLambdaHandler` method: 
```javascript
export const handler = newrelic.setLambdaHandler(async (event, context) => {
    // TODO implement
    return {
        statusCode: 200,
        body: JSON.stringify('Hello from Lambda!')
    }
})
```

### Note on legacy `NEW_RELIC_USE_ESM` environment variable
Prior to Lambda Layer releases `v12.16.0`, the wrapper for CommonJS and ESM were the same. If you wanted to wrap a ESM lambda handler you had to set `NEW_RELIC_USE_ESM` to `true`. This functionality still exists but has been deprecated.  If you have a ESM lambda handler set the function handler to point to `newrelic-esm-lambda-wrapper.handler`.  We will be removing `NEW_RELIC_USE_ESM` at a future date. 

## Support

Should you need assistance with New Relic products, you are in good hands with several support channels.

If the issue has been confirmed as a bug or is a feature request, please file a GitHub issue.

**Support Channels**

* [New Relic Documentation](https://docs.newrelic.com/docs/serverless-function-monitoring/aws-lambda-monitoring/get-started/monitoring-aws-lambda-serverless-monitoring/): Comprehensive guidance for using our platform
* [New Relic Community](https://discuss.newrelic.com/tags/c/full-stack-observability/serverless/): The best place to engage in troubleshooting questions
* [New Relic Developer](https://developer.newrelic.com/): Resources for building a custom observability applications
* [New Relic University](https://learn.newrelic.com/): A range of online training for New Relic users of every level
* [New Relic Technical Support](https://support.newrelic.com/) 24/7/365 ticketed support. Read more about our [Technical Support Offerings](https://docs.newrelic.com/docs/licenses/license-information/general-usage-licenses/support-plan).

## Privacy
At New Relic we take your privacy and the security of your information seriously, and are committed to protecting your information. We must emphasize the importance of not sharing personal data in public forums, and ask all users to scrub logs and diagnostic information for sensitive information, whether personal, proprietary, or otherwise.

We define “Personal Data” as any information relating to an identified or identifiable individual, including, for example, your name, phone number, post code or zip code, Device ID, IP address and email address.

Please review [New Relic’s General Data Privacy Notice](https://newrelic.com/termsandconditions/privacy) for more information.

## Contribute

We encourage your contributions to improve the New Relic Lambda layers! Keep in mind when you submit your pull request, you'll need to sign the CLA via the click-through using CLA-Assistant. You only have to sign the CLA one time per project.

If you have any questions, or to execute our corporate CLA, required if your contribution is on behalf of a company,  please drop us an email at opensource@newrelic.com.

**A note about vulnerabilities**

As noted in our [security policy](../../security/policy), New Relic is committed to the privacy and security of our customers and their data. We believe that providing coordinated disclosure by security researchers and engaging with the security community are important means to achieve our security goals.

If you believe you have found a security vulnerability in this project or any of New Relic's products or websites, we welcome and greatly appreciate you reporting it to New Relic through [HackerOne](https://hackerone.com/newrelic).

If you would like to contribute to this project, review [these guidelines](./CONTRIBUTING.md).

To [all contributors](https://github.com/newrelic/newrelic-lambda-layers/graphs/contributors), we thank you!  Without your contribution, this project would not be what it is today.

## License

The New Relic Lambda layers are licensed under the [Apache 2.0](http://apache.org/licenses/LICENSE-2.0.txt) License.

The New Relic Lambda layers also use source code from third-party libraries. You can find full details on which libraries are used and the terms under which they are licensed in [the third-party notices document](https://github.com/newrelic/newrelic-lambda-layers/blob/main/THIRD_PARTY_NOTICES.md).
