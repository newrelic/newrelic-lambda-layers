# frozen_string_literal: true

require 'minitest/autorun'
require 'minitest/pride'

# LambdaWrapperParsingTest - The tests defined by this class do not involve
#                            the New Relic Ruby agent. Instead, they test the
#                            wrapper script's handler string parsing
#                            functionality to ensure that all supported
#                            formats work well and that all unhappy paths to
#                            exceptions are verified as working.
#
# NOTE: Simply loading the wrapper script causes it to parse the handler string
#       from an environment variable and memoize it. This is by design so that
#       everything is loaded and ready prior to an actual customer invocation
#       of their wrapped method. That means that these tests have to repeatedly
#       reset the ENV hash and `load` the wrapper script over and over again,
#       which unfortunately leads to Ruby warnings about constants and methods
#       being redefined.
class LambdaWrapperUnitTest < Minitest::Test
  def test_handler_string_parse_works_for_toplevel_methods
    expected_method_name = 'my_handler'
    expected_path = '/opt/my_company/lambda'
    handler_string = "#{expected_path}.#{expected_method_name}"

    method_name, namespace = wrapper_parse(handler_string, expected_path)

    assert_equal expected_method_name, method_name
    refute namespace
  end

  def test_handler_string_parse_works_for_namespaced_methods
    expected_path = '/var/custom/serverless.rb'
    expected_method_name = 'handler'
    expected_namespace = 'MyCompany::MyClass'
    handler_string = "#{expected_path}.#{expected_namespace}.#{expected_method_name}"

    method_name, namespace = wrapper_parse(handler_string, expected_path)

    assert_equal expected_method_name, method_name
    assert_equal expected_namespace, namespace
  end

  def test_handler_string_parse_works_when_dots_exist_in_the_path
    expected_path = '/v.ar/custo.m/server.less.rb'
    expected_method_name = 'handler'
    expected_namespace = 'MyCompany::MyClass'
    handler_string = "#{expected_path}.#{expected_namespace}.#{expected_method_name}"

    method_name, namespace = wrapper_parse(handler_string, expected_path)

    assert_equal expected_method_name, method_name
    assert_equal expected_namespace, namespace
  end

  def test_handler_string_parse_raises_if_the_env_var_is_missing
    reset_wrapper

    assert_raises(RuntimeError, /Environment variable/) do
      load "#{File.dirname(__FILE__)}/../newrelic_lambda_wrapper.rb"
    end
  end

  def test_handler_string_parse_raises_if_the_handler_string_is_not_formatted_correctly
    assert_raises(RuntimeError, /expected to be in/) do
      wrapper_parse('dotless', '/dev/null') # rubocop:disable Style/FileNull
    end
  end

  def test_handler_string_parse_raises_if_the_handler_string_has_a_bad_path_value
    assert_raises(RuntimeError, /does not exist or is not readable/) do
      wrapper_parse('/a/bad/path.handler', '/a/bad/path', stub_path: false)
    end
  end

  private

  def wrapper_parse(handler_string, expected_path, stub_path: true)
    reset_wrapper

    oenv = ENV.to_hash

    ENV['NEW_RELIC_LAMBDA_HANDLER'] = handler_string

    load_wrapper(expected_path, stub_path)

    NewRelicLambdaWrapper.instance_variable_get :@method_name_and_namespace
  ensure
    ENV.replace oenv
  end

  def reset_wrapper
    if defined?(NewRelicLambdaWrapper) && NewRelicLambdaWrapper.instance_variable_get(:@method_name_and_namespace)
      NewRelicLambdaWrapper.remove_instance_variable :@method_name_and_namespace
    end
  end

  def load_wrapper(expected_path, stub_path)
    return stubbed_wrapper_load(expected_path) if stub_path

    load "#{File.dirname(__FILE__)}/../newrelic_lambda_wrapper.rb"
  end

  def stubbed_wrapper_load(path)
    path = "#{path}.rb" unless path.end_with?('.rb')
    File.stub :exist?, true, [path] do
      File.stub :readable?, true, [path] do
        Object.stub :require_relative, nil, [path] do
          load "#{File.dirname(__FILE__)}/../newrelic_lambda_wrapper.rb"
        end
      end
    end
  end
end
