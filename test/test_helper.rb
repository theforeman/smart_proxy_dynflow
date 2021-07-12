require 'minitest/autorun'

ENV['RACK_ENV'] = 'test'

$LOAD_PATH << File.join(File.dirname(__FILE__), '..', '..', 'lib')
require 'mocha/minitest'
require "rack/test"
require 'smart_proxy_for_testing'

require 'dynflow'
require 'smart_proxy_dynflow'
require 'smart_proxy_dynflow/testing'

Proxy::Dynflow::Plugin.load_test_settings({})

logdir = File.join(File.dirname(__FILE__), '..', '..', 'logs')
FileUtils.mkdir_p(logdir) unless File.exist?(logdir)

WORLD = Proxy::Dynflow::Testing.create_world
Proxy::Dynflow::Core.instance.world = WORLD
