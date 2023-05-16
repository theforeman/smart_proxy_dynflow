# frozen_string_literal: true
module Proxy::Dynflow::Action
  class Batch < ::Dynflow::Action
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
