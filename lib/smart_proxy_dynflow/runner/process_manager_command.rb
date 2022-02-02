require 'smart_proxy_dynflow/process_manager'

module Proxy::Dynflow
  module Runner
    module ProcessManagerCommand
      def initialize_command(*command)
        @process_manager = ProcessManager.new(command)
        set_process_manager_callbacks(@process_manager)
        @process_manager.start!
        if @process_manager.done? && @process_manager.status == 255
          publish_exception("Error running command '#{command.join(' ')}'", @process_manager.stderr.to_s)
        end
      end

      def set_process_manager_callbacks(pm)
        pm.on_stdout { |data| publish_data(data, 'stdout'); '' }
        pm.on_stderr { |data| publish_data(data, 'stderr'); '' }
      end

      def refresh
        @process_manager.process(timeout: 0.1)
        publish_exit_status(@process_manager.status) if @process_manager.done?
      end

      def close
        @process_manager&.close
      end
    end
  end
end
