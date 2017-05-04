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
      @fd = @file.kind_of?(IO) ? @file : File.open(@file, 'a')
      @fd.sync = true
      super(@fd, rest)
    end

    def add(*args)
      handle_log_rolling if @roll_log
      super(*args)
    end

    def roll_log
      @roll_log = true
    end

    def handle_log_rolling
      @roll_log = false
      unless @file.kind_of? IO
        @fd.reopen @file, 'a'
        @fd.sync = true
      end
    end

    class ProxyAdapter < ::Dynflow::LoggerAdapters::Simple
      def initialize(logger, level = Logger::DEBUG, formatters = [::Dynflow::LoggerAdapters::Formatters::Exception])
        @logger           = logger
        @logger.level     = level
        @logger.formatter = method(:formatter).to_proc
        @action_logger    = apply_formatters ProgNameWrapper.new(@logger, ' action'), formatters
        @dynflow_logger   = apply_formatters ProgNameWrapper.new(@logger, 'dynflow'), formatters
      end
    end
  end
end
