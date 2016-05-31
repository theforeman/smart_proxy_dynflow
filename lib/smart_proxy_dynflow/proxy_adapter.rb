module Proxy
  class Dynflow
    class ProxyAdapter < ::Dynflow::LoggerAdapters::Simple
      def initialize(logger, level = Logger::DEBUG, formatters = [Formatters::Exception])
        super(nil, level, formatters)
        @logger = logger
      end
    end
  end
end
