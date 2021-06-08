module Proxy::Dynflow::Action
  class OutputCollector < ::Proxy::Dynflow::Runner::Action
    def init_run
      output[:result] = []
      suspend
    end
  end
end
