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

  class << self
    attr_reader :instance

    def ensure_initialized
      return @instance if @instance
      @instance = Proxy::Dynflow.new
      after_initialize_blocks.each(&:call)
      @instance
    end

    def web_console
      require 'dynflow/web'
      dynflow_console = ::Dynflow::Web.setup do
        # we can't use the proxy's after_actionvation hook, as
        # it happens before the Daemon forks the process (including
        # closing opened file descriptors)
        # TODO: extend smart proxy to enable hooks that happen after
        # the forking
        Proxy::Dynflow.ensure_initialized
        set :world, Proxy::Dynflow.world
      end
      dynflow_console
    end

    def world
      instance.world
    end

    def after_initialize(&block)
      after_initialize_blocks << block
    end

    private

    def after_initialize_blocks
      @after_initialize_blocks ||= []
    end
  end
end
