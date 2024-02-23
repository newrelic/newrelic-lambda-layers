# frozen_string_literal: true

require 'json'

def handler(_event, _context)
  puts 'Running handler'
  { statusCode: 200, body: 'handled' }
end
