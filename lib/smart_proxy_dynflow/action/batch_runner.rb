require 'smart_proxy_dynflow/action/runner'

module Proxy::Dynflow::Action
  class BatchRunner < ::Proxy::Dynflow::Action::Runner
    def plan(launcher, input)
      plan_self :targets => launcher.runner_input(input), :operation => launcher.operation
    end

    def initiate_runner
      launcher = Proxy::Dynflow::TaskLauncherRegistry.fetch(input[:operation])
      launcher.runner_class.new(input[:targets], suspended_action: suspended_action)
    end
  end
end
