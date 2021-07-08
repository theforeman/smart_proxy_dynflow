module Proxy::Dynflow
  module TaskLauncher
    class Abstract
      attr_reader :callback, :options, :results, :world
      def initialize(world, callback, options = {})
        @world = world
        @callback = callback
        @options = options
        @results = {}
      end

      def launch!(_input)
        raise NotImplementedError
      end

      def self.input_format; end

      def to_hash
        {:class => self.class.to_s, :callback => callback, :options => options}
      end

      def self.new_from_hash(world, hash)
        ::Dynflow::Utils.constantize(hash[:class]).new(world, hash[:callback], hash[:options])
      end

      private

      def format_result(result)
        if result.triggered?
          { :result => 'success', :task_id => result.execution_plan_id }
        else
          plan = world.persistence.load_execution_plan(result.id)
          { :result => 'error', :errors => plan.errors }
        end
      end

      def action_class(input)
        options[:action_class_override] || ::Dynflow::Utils.constantize(input['action_class'])
      end

      def with_callback(input)
        input.merge(:callback_host => callback)
      end

      def trigger(parent, klass, *input, id: nil)
        world.trigger do
          world.plan_with_options(caller_action: parent, action_class: klass, args: input, id: id)
        end
      end
    end
  end
end
