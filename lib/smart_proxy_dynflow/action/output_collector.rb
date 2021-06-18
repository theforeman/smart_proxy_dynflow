module Proxy::Dynflow::Action
  class OutputCollector < ::Proxy::Dynflow::Action::Runner
    def init_run
      output[:result] = []
      suspend
    end
  end
end
