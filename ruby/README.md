# New Relic AWS Lambda layer for wrapping Ruby Lambda functions

## Overview

This 'ruby' subdirectory contains content for building and publishing a
New Relic's AWS Lambda layer for use with Ruby Lambda functions.

The layer will include the latest stable version of the New Relic Ruby agent gem,
`newrelic_rpm`, the latest New Relic Lambda
[extension](https://github.com/newrelic/newrelic-lambda-extension),
and the lightweight `newrelic_lambda_wrapper.rb` that wraps untouched customer
Lambda functions for observability.

A layer is created for every region, architecture, and Ruby runtime combination.

NOTE that as of February 2024, AWS Lambda supports Ruby v3.2 only


## Layer building and publishing

With Ruby 3.2's `bundle` binary in your path:

```shell
./publish_layers.sh ruby3.2
```


## Developer instructions

- Clone the repository and change to the 'ruby' directory
- Run `bin/setup`
- Run `bundle exec rake test` to run the unit tests

NOTES:

- To test Ruby agent changes that are available locally or on GitHub, alter
  `Gemfile` accordingly.
- `Gemfile.lock` is Git ignored so that the latest stable agent version is
  always fetched
- For alignment with the Node.js and Python content in this repository, the
  [Serverless](https://www.serverless.com/) Node.js module and the
  [serverless-offline](https://github.com/dherault/serverless-offline) plugin
  are used for simulated AWS Lambda testing.
- All Serverless related content can be found at `test/support`
- A simple representation of a customer Lambda function is available at
  `test/support/src/handler.rb`.
- The customer Lambda function is referenced via the `NEW_RELIC_LAMBDA_HANDLER`
  environment variable defined in `test/support/serverless.yml. That variable
  is formatted as `<PATH_TO_RUBY_FILE>.<LAMBDA_HANDLER_RUBY_METHOD_NAME>`,
  with the path part of the string optionally including the `.rb` file extension
  part of the path.
- While it is recommended that the system building new layers be set up to run
  the same Ruby version as the layer is targetting, a simple `mv` hack currently
  exists in `publish-layers.sh` that would allow say an instance of Ruby 3.3 to
  build a Ruby 3.2 layer.
