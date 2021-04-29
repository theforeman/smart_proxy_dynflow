require 'logging'

module SmartProxyDynflowCore
  class ReopenAppender < ::Logging::Appender
    def initialize(name, logger, opts = {})
      @reopen = false
      @logger = logger
      super(name, opts)
    end

    def set(status = true)
      @reopen = status
    end

    def append(_event)
      if @reopen
        Logging.reopen
        @reopen = false
      end
    end
  end

  class Log
    BASE_LOG_SIZE = 1024 * 1024 # 1 MiB
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

      def reopen
        return if @logger.nil? || @reopen.nil?
        if Settings.instance.log_file !~ /^(STDOUT|SYSLOG|JOURNALD?)$/i
          @reopen.set
        end
      end

      def instance
        ::Proxy::LogBuffer::Decorator.instance
      end

      def with_fields(fields = {})
        ::Logging.ndc.push(fields) do
          yield
        end
      end

      # Standard way for logging exceptions to get the most data in the log. By default
      # it logs via warn level, this can be changed via options[:level]
      def exception(context_message, exception, options = {})
        level = options[:level] || :warn
        unless ::Logging::LEVELS.keys.include?(level.to_s)
          raise "Unexpected log level #{level}, expected one of #{::Logging::LEVELS.keys}"
        end
        # send class, message and stack as structured fields in addition to message string
        backtrace = exception.backtrace ? exception.backtrace : []
        extra_fields = {
          exception_class: exception.class.name,
          exception_message: exception.message,
          exception_backtrace: backtrace
        }
        extra_fields[:foreman_code] = exception.code if exception.respond_to?(:code)
        with_fields(extra_fields) do
          @logger.public_send(level) do
            ([context_message, "#{exception.class}: #{exception.message}"] + backtrace).join("\n")
          end
        end
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
