require 'minitest/autorun'

ENV['RACK_ENV'] = 'test'

$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
require "mocha/setup"
require "rack/test"

require 'dynflow'
require 'smart_proxy_dynflow_core'
require 'smart_proxy_dynflow_core/testing'

SmartProxyDynflowCore::Settings.instance.log_file = nil
SmartProxyDynflowCore::Settings.instance.standalone = true
WORLD = SmartProxyDynflowCore::Dynflow::Testing.create_world
SmartProxyDynflowCore::Core.instance.world = WORLD

logdir = File.join(File.dirname(__FILE__), '..', 'logs')
FileUtils.mkdir_p(logdir) unless File.exist?(logdir)
