module Proxy
  class Dynflow
    module Helpers
      def world
        Proxy::Dynflow.world
      end

      def trigger_task(*args)
        triggered = world.trigger(*args)
        { :task_id => triggered.id }
      end

      def cancel_task(task_id, step_ids = nil)
        unless step_ids
          execution_plan = world.persistence.load_execution_plan(task_id)
          step_ids = execution_plan.steps_in_state(:running, :suspended).find_all do |step|
            step.action(execution_plan).is_a?(::Dynflow::Action::Cancellable)
          end.map(&:id)
        end
        step_ids.each do |step_id|
          world.event(task_id, step_id, ::Dynflow::Action::Cancellable::Cancel)
        end
        { :task_id => task_id, :canceled_steps => step_ids }
      end

      def task_status(task_id)
        ep = world.persistence.load_execution_plan(task_id)
        ep.to_hash.merge(:actions => ep.actions.map(&:to_hash))
      rescue KeyError => e
        status 404
        {}
      end
    end
  end
end
