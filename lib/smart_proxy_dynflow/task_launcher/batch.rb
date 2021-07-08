module Proxy::Dynflow
  module TaskLauncher
    class Batch < Abstract
      def launch!(input)
        plan = trigger(nil, action_class, self, input)
        results[:parent] = format_result(plan)
      end

      def launch_children(parent, input_hash)
        input_hash.map do |task_id, input|
          launcher = child_launcher(parent)
          triggered = launcher.launch!(transform_input(input), id: task_id)
          results[task_id] = launcher.results
          triggered
        end
      end

      def prepare_batch(input_hash)
        input_hash
      end

      def child_launcher(parent)
        Single.new(world, callback, :parent => parent)
      end

      private

      # Identity by default
      def transform_input(input)
        input
      end

      def action_class
        Proxy::Dynflow::Action::Batch
      end
    end

    class AsyncBatch < Batch
      def action_class
        Proxy::Dynflow::Action::AsyncBatch
      end
    end
  end
end
