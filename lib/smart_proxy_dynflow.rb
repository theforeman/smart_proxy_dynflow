require 'dynflow'

require 'smart_proxy_dynflow/version'
require 'smart_proxy_dynflow/plugin'
require 'smart_proxy_dynflow/callback'
require 'smart_proxy_dynflow/helpers'

class Proxy::Dynflow
  attr_accessor :world

  def initialize
    @world = create_world
  end

  def create_world(&block)
    config = default_world_config(&block)
    ::Dynflow::World.new(config)
  end

  def persistence_conn_string
    ENV['DYNFLOW_DB_CONN_STRING'] || 'sqlite:/'
  end

  def persistence_adapter
    ::Dynflow::PersistenceAdapters::Sequel.new persistence_conn_string
  end

  def default_world_config
    ::Dynflow::Config.new.tap do |config|
      config.auto_rescue = true
      config.logger_adapter = logger_adapter
      config.persistence_adapter = persistence_adapter
      yield config if block_given?
    end
  end

  def logger_adapter
    ::Dynflow::LoggerAdapters::Simple.new $stderr, 0
  end

  def web_console
    require 'dynflow/web'
    world = @world
    dynflow_console = ::Dynflow::Web.setup do
      set :world, world
    end
    dynflow_console
  end

  class << self
    attr_reader :instance

    def initialize
      @instance = Proxy::Dynflow.new
    end

    def world
      instance.world
    end
  end
end

Proxy::Dynflow.initialize
