require 'logger'

module SmartProxyDynflowCore
  class Log < ::Logger

    alias_method :write, :debug

    class << self
      def instance
        if @logger.nil?
          @logger = Logger.new log_file
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

      private

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
  end
end
