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

      def cancel_task(task_id)
        execution_plan = world.persistence.load_execution_plan(task_id)
        cancel_events = execution_plan.cancel
        { :task_id => task_id, :canceled_steps_count => cancel_events.size }
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
