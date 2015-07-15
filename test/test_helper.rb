require 'minitest/autorun'
$: << File.join(File.dirname(__FILE__), '..', 'lib')
require "mocha/setup"
require "rack/test"
require 'smart_proxy_for_testing'

require 'smart_proxy_dynflow'
require 'smart_proxy_dynflow/testing'

WORLD = Proxy::Dynflow::Testing.create_world

logdir = File.join(File.dirname(__FILE__), '..', 'logs')
FileUtils.mkdir_p(logdir) unless File.exists?(logdir)
