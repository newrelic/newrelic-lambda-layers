# frozen_string_literal: true

require 'newrelic_rpm'

ENV['NEW_RELIC_DISTRIBUTED_TRACING_ENABLED'] ||= 'true'
ENV['NEW_RELIC_APP_NAME'] ||= ENV.fetch('AWS_LAMBDA_FUNCTION_NAME', '')
ENV['NEW_RELIC_TRUSTED_ACCOUNT_KEY'] = ENV.fetch('NEW_RELIC_ACCOUNT_ID', '')

HANDLER_VAR = 'NEW_RELIC_LAMBDA_HANDLER'

def path_and_method_name(handler_string)
  # the path can contain periods, use #rpartition instead of #split
  path, _, method_name = handler_string.rpartition('.')
  raise 'Unable to determine a method!' if method_name.nil? || method_name.empty?
  raise 'Unable to determine a handler path!' if path.nil? || path.empty?

  [path, method_name]
rescue StandardError => e
  raise "Failed to parse the '#{HANDLER_VAR}' env var which is expected to be in '<path>.<method>' format! - #{e}"
end

def require_source_file(path)
  path = "#{path}.rb" unless path.end_with?('.rb')
  path = "#{Dir.pwd}/#{path}" unless path.start_with?('/')
  raise "Path '#{path}' does not exist or is not readable" unless File.exist?(path) && File.readable?(path)

  require_relative path
end

# prep the customer's handler function only once at cold start (first invocation) time only
def method_name
  @method_name ||= begin
    handler_string = ENV.fetch(HANDLER_VAR, nil)
    raise "Environment value '#{HANDLER_VAR}' is not set!" unless handler_string

    path, method_name = path_and_method_name(handler_string)
    require_source_file(path)

    method_name
  end
rescue StandardError => e
  raise "Failed to prep the Lambda function to be wrapped - #{e}"
end

def handler(event = nil, context = nil)
  NewRelic::Agent.agent.serverless_handler.lambda_handler(method_name:, event:, context:)
end
