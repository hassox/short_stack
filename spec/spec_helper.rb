$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'short_stack'
require 'spec'
require 'spec/autorun'
require 'rack/test'
require 'pancake/test/matchers'

Spec::Runner.configure do |config|
  config.include(Rack::Test::Methods)
  config.include(Pancake::Test::Matchers)
  config.include(Pancake::Test::Helpers)
end
