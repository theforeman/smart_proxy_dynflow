module Proxy::Dynflow::Action
  class Batch < ::Dynflow::Action
    include Dynflow::Action::WithSubPlans
    include Dynflow::Action::WithPollingSubPlans

    # { task_id => { :action_class => Klass, :input => input } }
    def plan(launcher, input_hash)
      launcher.launch_children(self, input_hash)
      plan_self
    end

    def initiate
      ping suspended_action
      wait_for_sub_plans sub_plans
    end

    def rescue_strategy
      Dynflow::Action::Rescue::Fail
    end
  end

  class AsyncBatch < ::Dynflow::Action
    include Dynflow::Action::WithSubPlans
    include Dynflow::Action::WithPollingSubPlans

    # { execution_plan_uuid => { :action_class => Klass, :input => input } }
    def plan(launcher, input_hash)
      plan_self :input_hash => input_hash,
                :launcher => launcher.to_hash
    end

    def create_sub_plans
      Proxy::Dynflow::TaskLauncher::Abstract
        .new_from_hash(world, input[:launcher])
        .launch_children(self, input[:input_hash])
    end

    def rescue_strategy
      Dynflow::Action::Rescue::Fail
    end
  end
end
