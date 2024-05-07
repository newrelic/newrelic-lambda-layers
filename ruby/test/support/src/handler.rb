# frozen_string_literal: true

# An::Example - this class provides a simple example of a customer's
#               Lambda handler to be wrapped by New Relic.
#
#               A method can be defined in Ruby's toplevel (Object) namespace
#               or within a class such as the one used here. When defined
#               within a class, the method is expected to be a class (self.)
#               level method.
#
#               There are no requirements imposed by either AWS or New Relic
#               on top of standard Ruby requirements for module, class, and
#               method naming.
#
#               This example handler method will return a string body that
#               can be inspected by the unit tests to confirm that it reaches
#               the client caller even when wrapped by New Relic.
module An
  class Example
    def self.handler(_event:, _context:)
      puts 'Running handler'
      { statusCode: 200, body: 'handled' }
    end
  end
end
