module Proxy::Dynflow::Action
  class SingleRunnerBatch < Batch
    include ::Dynflow::Action::Cancellable

    def plan(launcher, input_hash)
      launcher.launch_children(self, input_hash)
      input[:group_runner_plan_id] = launcher.group_runner_plan_id
      sequence do
        results = plan_self
        plan_action BatchCallback, launcher.prepare_batch(input_hash), results.output[:results]
      end
    end

    def run(event = nil)
      super unless event == Dynflow::Action::Skip
    end

    def initiate
      ping suspended_action
      wait_for_sub_plans sub_plans
    end

    def check_for_errors!(optional = true)
      super unless optional
    end

    def on_finish
      collect_outputs
    end

    def finalize
      output.delete(:results)
      check_for_errors!
    end

    def cancel!
      collect_outputs
      plan = world.persistence.load_execution_plan(input[:group_runner_plan_id])
      plan&.cancel
    end

    def rescue_strategy_for_self
      Dynflow::Action::Rescue::Skip
    end

    def collect_outputs
      output[:results] = sub_plans.map(&:entry_action).reduce({}) do |acc, cur|
        acc.merge(cur.execution_plan_id => cur.output)
      end
    end
  end
end
