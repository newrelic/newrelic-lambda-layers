# Java Agent Lambda Layer

Deployment scripts for deploying a lambda layer that attatches the New Relic Java Agent with serverless mode enabled.

## How to build & publish locally

First make sure you are in the java-agent directory. Run `cd java-agent`.

### Updating versions.sh (Skip if using a local agent jar)
First go into `versions.sh` and check the Java Agent version. Make sure it is the correct one you will use as you will download it from the downloads site.

For example, to use agent version `9.1.0`, set this in `versions.sh`:
```
NEWRELIC_AGENT_VERSION=9.1.0
```

### Build your layer locally

If you are downloading the agent from downloads site, run `./build-layers.sh`. 
If you are using a locally built agent Jar, run `./build-layers.sh /path/to/agent/jar` where `/path/to/agent/jar` is your path to the agent jar.

You will see a `/dist` directory created with zip files for each lambda layer deployed:

- java-agent.x86_64.zip
- java-agent.arm64.zip
- java-agent-slim.x86_64.zip
- java-agent-slim.arm64.zip
  
You can manually upload them to your AWS console and deploy them into your lambda provided they are using a supported Java Version.

### Publish your layer locally

The `publish-layers.sh` script builds and publishes your lambda layers to your AWS account.

To publish your lambda layers, you need to follow the steps in the [local testing guide](https://newrelic.atlassian.net/wiki/spaces/APM/pages/5337088128/New+Relic+Lambda+Layers+-+Local+Testing+Guide) to set up your AWS account and the libBuild.sh script. **Make sure your AWS account has the correct IAM permissions needed to follow these steps as well.**

If you are publishing using the agent from downloads site, run `./publish-layers.sh`. 
If you are publishing using a locally built agent Jar, run `./publish-layers.sh /path/to/agent/jar` where `/path/to/agent/jar` is your path to the agent jar.

**Important:** You may have to comment out sections of the publish scripts that deploy to an architecture unsupported on your machine. For example, X86_64 machines may have to comment out sections that deploy arm64 layers. Vice versa with ARM64 machines.

You will then see the following deployed lambda layers in your AWS console:
- NewRelicAgentJava
- NewRelicAgentJavaARM64
- NewRelicAgentJava-slim
- NewRelicAgentJavaARM64-slim
