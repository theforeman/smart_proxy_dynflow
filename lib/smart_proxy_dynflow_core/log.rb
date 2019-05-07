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
        return ::Proxy::LogBuffer::Decorator.instance unless Settings.instance.standalone
        return @logger if @logger
        layout = Logging::Layouts.pattern(pattern: Settings.instance.file_logging_pattern + "\n")
        notime_layout = Logging::Layouts.pattern(pattern: Settings.instance.system_logging_pattern + "\n")
        log_file = Settings.instance.log_file || ''
        @logger = Logging.logger[LOGGER_NAME]
        @reopen = ReopenAppender.new("Reopen dummy appender", @logger)
        @logger.add_appenders(@reopen)
        if !Settings.instance.loaded || log_file.casecmp('STDOUT').zero?
          @logger.add_appenders(Logging.appenders.stdout(LOGGER_NAME, layout: layout))
        elsif log_file.casecmp('SYSLOG').zero?
          unless @syslog_available
            puts "Syslog is not supported on this platform, use STDOUT or a file"
            exit(1)
          end
          @logger.add_appenders(Logging.appenders.syslog(LOGGER_NAME, layout: notime_layout, facility: ::Syslog::Constants::LOG_LOCAL5))
        elsif log_file.casecmp('JOURNAL').zero? || log_file.casecmp('JOURNALD').zero?
          begin
            @logger.add_appenders(Logging.appenders.journald(LOGGER_NAME, LOGGER_NAME: :proxy_logger, layout: notime_layout, facility: ::Syslog::Constants::LOG_LOCAL5))
          rescue NoMethodError
            @logger.add_appenders(Logging.appenders.stdout(LOGGER_NAME, layout: layout))
            @logger.warn "Journald is not available on this platform. Falling back to STDOUT."
          end
        else
          begin
            keep = Settings.instance.file_rolling_keep
            size = BASE_LOG_SIZE * Settings.instance.file_rolling_size
            age = Settings.instance.file_rolling_age
            if size.positive?
              @logger.add_appenders(Logging.appenders.rolling_file(LOGGER_NAME, layout: layout, filename: log_file, keep: keep, size: size, age: age, roll_by: 'number'))
            else
              @logger.add_appenders(Logging.appenders.file(LOGGER_NAME, layout: layout, filename: log_file))
            end
          rescue ArgumentError => ae
            @logger.add_appenders(Logging.appenders.stdout(LOGGER_NAME, layout: layout))
            @logger.warn "Log file #{log_file} cannot be opened. Falling back to STDOUT: #{ae}"
          end
        end
        @logger.level = ::Logging.level_num(Settings.instance.log_level)
        @logger
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
