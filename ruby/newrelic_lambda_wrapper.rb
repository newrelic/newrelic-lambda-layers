# frozen_string_literal: true

ENV['NEW_RELIC_DISTRIBUTED_TRACING_ENABLED'] ||= 'true'
ENV['AWS_LAMBDA_FUNCTION_NAME'] ||= 'lambda_function'
ENV['NEW_RELIC_APP_NAME'] ||= ENV.fetch('AWS_LAMBDA_FUNCTION_NAME', nil)
ENV['NEW_RELIC_TRUSTED_ACCOUNT_KEY'] = ENV.fetch('NEW_RELIC_ACCOUNT_ID', '')

# The customer's Lambda function is configured to point to this file and its
# `handler` method.
#
# The customer's original handler string is expected to be found as the value
# for the 'NEW_RELIC_LAMBDA_HANDLER' environment variable. That string is
# parsed into its individual file path and Ruby method components. The path
# is passed to a `require` call and then the method (along with its optional
# namespace) is handed to the New Relic Ruby agent's `ServerlessHandler` class.
#
# The `ServerlessHandler` class will start a New Relic transaction, invoke the
# customer's method, and observe its execution. Any activity related to
# instrumented Ruby libraries involved by the customer's method, any Ruby logger
# calls, and any exceptions raised will all be reported to New Relic.
#
# The customer's original handler string is in the format of `<path>.<method>`
#   - `path` holds the absolute filesytem path to a Ruby file
#   - `path` can optionally leave off the `.rb` file extension
#   - If Ruby was to `load` the file at `path`, the specified `method` would
#     then be defined
#   - The `method` can be defined at the toplevel namespace or within a
#     module and/or class namespace
#   - The `path` can contain dots (.) in either the directory names or
#     file names
#
#   example 1:
#     handler_string = '/opt/my_company/lambda.my_handler'
#
#     - a file exists at '/opt/my_company/lambda.rb'
#     - lambda.rb has the following content:
#         ```
#         def my_handler(event:, context:); end
#         ```
#
#   example 2:
#     handler_string = '/var/custom/serverless.rb.MyCompany::MyClass.handler'
#
#     - a file exists at '/var/custom/serverless.rb'
#     - serverless.rb has the following content (note the class level method)
#       ```
#       module MyCompany
#         class MyClass
#           def self.handler(event:, context:); end
#         end
#       end
#
class NewRelicLambdaWrapper
  HANDLER_VAR = 'NEW_RELIC_LAMBDA_HANDLER'
  NR_LAYER_GEM_PATH = "/opt/ruby/gems/#{RUBY_VERSION.rpartition('.').first}.0/gems".freeze

  def self.adjust_load_path
    return unless Dir.exist?(NR_LAYER_GEM_PATH)

    Dir.glob(File.join(NR_LAYER_GEM_PATH, '*', 'lib')).each do |gem_lib_dir|
      $LOAD_PATH.push(gem_lib_dir) unless $LOAD_PATH.include?(gem_lib_dir)
    end
  end

  def self.require_ruby_agent
    adjust_load_path
    require 'newrelic_rpm'
  rescue StandardError => e
    raise "#{self.class.name}: failed to require New Relic layer provided gem(s) - #{e}"
  end

  def self.method_name_and_namespace
    @method_name_and_namespace ||= parse_customer_handler_string
  rescue StandardError => e
    raise "#{self.class.name}: failed to prep the Lambda function to be wrapped - #{e}"
  end

  # Parse the handler string into its individual components. Load the Ruby file
  # and return the customer handler method name and its namespace.
  #
  # '/path/to/file.method' -> ['method', nil]
  # '/path/to/file.MyModule::MyClass.method' -> ['method', 'MyModule::MyClass']
  #
  def self.parse_customer_handler_string
    handler_string = ENV.fetch(HANDLER_VAR, nil)
    raise "Environment variable '#{HANDLER_VAR}' is not set!" unless handler_string

    elements = handler_string.split('.')
    ridx = determine_ridx(elements)
    file = elements[0..ridx].join('.')
    method_string = elements[(ridx + 1)..].join('.')

    require_source_file(file)

    method_string.split('.').reverse
  end
  private_class_method :parse_customer_handler_string

  def self.determine_ridx(elements)
    if elements.size == 1
      raise "Failed to parse the '#{HANDLER_VAR}' env var which is expected to be in '<path>.<method>' format!"
    end

    elements.size > 2 ? -3 : -2
  end
  private_class_method :determine_ridx

  def self.require_source_file(path)
    path = "#{path}.rb" unless path.end_with?('.rb')
    path = "#{Dir.pwd}/#{path}" unless path.start_with?('/')
    raise "Path '#{path}' does not exist or is not readable" unless File.exist?(path) && File.readable?(path)

    require_relative path
  end
  private_class_method :require_source_file
end

# warm the memoization cache so that the very first customer method invocation
# isn't made to wait
NewRelicLambdaWrapper.method_name_and_namespace
NewRelicLambdaWrapper.require_ruby_agent

def handler(event:, context:)
  method_name, namespace = NewRelicLambdaWrapper.method_name_and_namespace
  NewRelic::Agent.agent.serverless_handler.invoke_lambda_function_with_new_relic(event:,
                                                                                 context:,
                                                                                 method_name:,
                                                                                 namespace:)
end
