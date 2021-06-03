class Proxy::Dynflow
  class OutputCollectorAction < ::Proxy::Dynflow::Runner::Action
    def init_run
      output[:result] = []
      suspend
    end
  end
end
