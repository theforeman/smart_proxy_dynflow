module SmartProxyDynflowCore
  class TaskLauncherRegistry
    class << self
      def register(name, launcher)
        registry[name] = launcher
      end

      def fetch(name, default = nil)
        if default.nil?
          registry.fetch(name)
        else
          registry.fetch(name, default)
        end
      end

      def key?(name)
        registry.key?(name)
      end

      def operations
        registry.keys
      end

      private

      def registry
        @registry ||= {}
      end
    end
  end
end
