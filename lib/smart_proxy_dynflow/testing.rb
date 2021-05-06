require 'dynflow/testing'

unless defined? DYNFLOW_TESTING_LOG_LEVEL
  DYNFLOW_TESTING_LOG_LEVEL = 4
end

class Proxy::Dynflow
  # Helper for usage in other dependent plugins that need Dynflow
  # related things, such as testing instance of world etc.
  module Testing
    class << self
      def create_world(&block)
        Core.ensure_initialized
        Core.instance.create_world do |config|
          config.exit_on_terminate = false
          config.auto_terminate    = false
          config.logger_adapter    = ::Dynflow::LoggerAdapters::Simple.new $stderr, DYNFLOW_TESTING_LOG_LEVEL
          config.execution_plan_cleaner = nil
          yield(config) if block
        end
      end
    end
  end
end
