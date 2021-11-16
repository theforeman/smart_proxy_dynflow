module Proxy::Dynflow::Action
  class OutputCollector < ::Proxy::Dynflow::Action::Runner
    def init_run
      output[:result] = []
      suspend
    end

    def kill_run
      execution_plan = world.persistence.load_execution_plan(caller_execution_plan_id)
      execution_plan.cancel
    end
  end
end
