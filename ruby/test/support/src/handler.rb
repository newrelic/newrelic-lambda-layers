# frozen_string_literal: true

require 'json'

def handler(event:, context:)
  puts 'Running handler'
  { statusCode: 200, body: 'handled' }
end
