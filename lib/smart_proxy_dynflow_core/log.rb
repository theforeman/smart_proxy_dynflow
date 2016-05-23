require 'logger'

module SmartProxyDynflowCore
  class Log < ::Logger

    alias_method :write, :debug

    class << self
      def instance
        if @logger.nil?
          destination = if Settings.instance.loaded && Settings.instance.log_file
                          Settings.instance.log_file
                        else
                          $stdout
                        end
          @logger = Logger.new destination
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
    end
  end
end
