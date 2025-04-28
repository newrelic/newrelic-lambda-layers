# frozen_string_literal: true

require 'fileutils'
require 'minitest/autorun'
require 'minitest/pride'
require 'net/http'

# LambdaWrapperIntegrationTest - tests to confirm the successful New Relic
#                                wrapping of unaltered customer Lambda
#                                functions via a complete integration process
#                                that includes a customer function, the
#                                wrapper script, the New Relic Ruby agent,
#                                and the 'serverless' Node.js module behaving
#                                as an AWS Lambda service
class LambdaWrapperIntegrationTest < Minitest::Test
  METADATA_PATTERN = /"agent_language":"ruby"/
  SERVERLESS_ROOT = 'test/support'
  SERVERLESS_OUTPUT_FILE = 'serverless_log'
  SERVERLESS_CMD = "cd #{SERVERLESS_ROOT} && node_modules/serverless/bin/serverless.js " \
                   "offline start >#{SERVERLESS_OUTPUT_FILE} 2>&1".freeze
  SERVERLESS_URI = URI('http://localhost:3000/dev')

  def setup
    remove_serverless_output_file
    @serverless_pid = nil
    @serverless_thread = Thread.new { @serverless_pid = Process.spawn(SERVERLESS_CMD) }
    puts 'Giving the serverless process time to start...'
    sleep 10
  end

  def teardown
    child_pid = `pgrep -P #{@serverless_pid} | head -1`.chomp
    Process.kill('KILL', @serverless_pid) if @serverless_pid
    Process.kill('KILL', child_pid.to_i) if child_pid.match?(/^\d+$/)
    @serverless_thread&.kill
    remove_serverless_output_file
  end

  def remove_serverless_output_file
    FileUtils.rm_f(serverless_output_file_path)
  end

  def serverless_output_file_path
    File.join(SERVERLESS_ROOT, SERVERLESS_OUTPUT_FILE)
  end

  # serverless.yml should be configured to point to the wrapper
  # with an env var that points to the customer function to be wrapped
  def test_wrapped_customer_function
    response = Net::HTTP.get(SERVERLESS_URI)

    # confirm that the customer's handler output has been returned
    assert_equal 'handled', response

    # confirm that the New Relic agent has generated one or more payloads
    # from having wrapped the customer function
    data = File.read(serverless_output_file_path).split("\n")
    nr_payload = data.detect { |line| line.start_with?('[') }
    refute_nil nr_payload

    assert_match METADATA_PATTERN, nr_payload
  end
end
