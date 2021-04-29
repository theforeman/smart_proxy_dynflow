require 'logging'

class Proxy::Dynflow
  class Log
    LOGGER_NAME = 'dynflow-core'.freeze

    begin
      require 'syslog/logger'
      @syslog_available = true
    rescue LoadError
      @syslog_available = false
    end

    class << self
      def reload!
        Logging.logger[LOGGER_NAME].appenders.each(&:close)
        Logging.logger[LOGGER_NAME].clear_appenders
        @logger = nil
        instance
      end

      def instance
        ::Proxy::LogBuffer::Decorator.instance
      end
    end

    class ProxyStructuredFormater < ::Dynflow::LoggerAdapters::Formatters::Abstract
      def format(message)
        if message.is_a?(Exception)
          subject = "#{message.message} (#{message.class})"
          if @base.respond_to?(:exception)
            @base.exception("Error details", message)
            subject
          else
            "#{subject}\n#{message.backtrace.join("\n")}"
          end
        else
          @original_formatter.call(severity, datetime, prog_name, message)
        end
      end
    end

    class ProxyAdapter < ::Dynflow::LoggerAdapters::Simple
      def initialize(logger, level = Logger::DEBUG, _formatters = [])
        @logger           = logger
        @logger.level     = level
        @action_logger    = apply_formatters(ProgNameWrapper.new(@logger, ' action'), [])
        @dynflow_logger   = apply_formatters(ProgNameWrapper.new(@logger, 'dynflow'), [])
      end
    end
  end
end
