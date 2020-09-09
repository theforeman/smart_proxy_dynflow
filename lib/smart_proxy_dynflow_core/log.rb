require 'logger'

module SmartProxyDynflowCore
  class Log < ::Logger
    alias_method :write, :debug

    class << self
      def instance
        if @logger.nil?
          @logger = self.new log_file
          @logger.level = log_level
        end
        @logger
      end

      def instance=(logger)
        @logger = logger
      end

      def reload!
        @logger = nil
        instance
      end

      def log_level
        if Settings.instance.loaded && Settings.instance.log_level
          ::Logger.const_get(Settings.instance.log_level.upcase)
        else
          Logger::WARN
        end
      end

      def log_file
        if Settings.instance.loaded && Settings.instance.log_file
          Settings.instance.log_file
        else
          $stdout
        end
      end
    end

    def initialize(file, *rest)
      @file = file
      @fd = @file.is_a?(IO) ? @file : File.open(@file, 'a')
      @fd.sync = true
      super(@fd, *rest)
    end

    def roll_log
      unless @file.is_a? IO
        @fd.reopen @file, 'a'
        @fd.sync = true
      end
    end

    class ProxyStructuredFormater < ::Dynflow::LoggerAdapters::Formatters::Abstract
      def initialize(*args)
        super
        @original_formatter = ::Logger::Formatter.new
      end

      def call(severity, datetime, prog_name, message)
        if message.is_a?(::Exception)
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

      def format(message)
        call(nil, nil, nil, message)
      end
    end

    class ProxyAdapter < ::Dynflow::LoggerAdapters::Simple
      def initialize(logger, level = Logger::DEBUG, _formatters = [])
        @logger           = logger
        @logger.level     = level
        @logger.formatter = ProxyStructuredFormater.new(@logger)
        @action_logger    = apply_formatters(ProgNameWrapper.new(@logger, ' action'), [])
        @dynflow_logger   = apply_formatters(ProgNameWrapper.new(@logger, 'dynflow'), [])
      end
    end
  end
end
