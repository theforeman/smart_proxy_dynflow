module Proxy::Dynflow
  module TaskLauncher
    class Single < Abstract
      def self.input_format
        { :action_class => "MyActionClass", :action_input => {} }
      end

      def launch!(input, id: nil)
        triggered = trigger(options[:parent],
                            action_class(input),
                            with_callback(input.fetch('action_input', {})),
                            id: id)
        @results = format_result(triggered)
        triggered
      end
    end
  end
end
