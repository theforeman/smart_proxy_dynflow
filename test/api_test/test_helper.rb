require 'minitest/autorun'

ENV['RACK_ENV'] = 'test'

$LOAD_PATH << File.join(File.dirname(__FILE__), '..', '..', 'lib')
require "mocha/setup"
require "rack/test"
require 'smart_proxy_for_testing'

require 'smart_proxy_dynflow'

Proxy::Dynflow::Plugin.load_test_settings({})

logdir = File.join(File.dirname(__FILE__), '..', '..', 'logs')
FileUtils.mkdir_p(logdir) unless File.exist?(logdir)
