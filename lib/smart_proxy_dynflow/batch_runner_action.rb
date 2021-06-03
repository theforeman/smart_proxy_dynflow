require 'smart_proxy_dynflow/runner/action'

class Proxy::Dynflow
  class BatchRunnerAction < ::Proxy::Dynflow::Runner::Action
    def plan(launcher, input)
      plan_self :targets => launcher.runner_input(input), :operation => launcher.operation
    end

    def initiate_runner
      launcher = SmartProxyDynflowCore::TaskLauncherRegistry.fetch(input[:operation])
      launcher.runner_class.new(input[:targets], suspended_action: suspended_action)
    end
  end
end
