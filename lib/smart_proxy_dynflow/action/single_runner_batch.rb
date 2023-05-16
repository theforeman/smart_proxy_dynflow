# frozen_string_literal: true
module Proxy::Dynflow::Action
  class SingleRunnerBatch < Batch
    include Dynflow::Action::WithPollingSubPlans

    def plan(launcher, input_hash)
      results = super
      plan_action BatchCallback, input_hash, results.output[:results]
    end

    def check_for_errors!(optional = true)
      super unless optional
    end

    def on_finish
      output[:results] = sub_plans.map(&:entry_action).reduce({}) do |acc, cur|
        acc.merge(cur.execution_plan_id => cur.output)
      end
    end

    def finalize
      output.delete(:results)
      check_for_errors!
    end

    def rescue_strategy_for_self
      Dynflow::Action::Rescue::Skip
    end
  end
end
