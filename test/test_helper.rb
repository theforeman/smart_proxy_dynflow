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

def wait_until(iterations: 10, interval: 0.2, msg: nil)
  iterations.times do
    return if yield
    sleep interval
  end
  raise msg || "Failed waiting for something to happen"
end

def load_execution_plan(id)
  Proxy::Dynflow::Core.world.persistence.load_execution_plan(id)
end

module WithPerTestWorld
  def self.included(base)
    base.before :each do
      Proxy::Dynflow::Core.instance.world = Proxy::Dynflow::Testing.create_world
    end

    base.after :each do
      Proxy::Dynflow::Core.instance.world = WORLD
    end
  end
end
