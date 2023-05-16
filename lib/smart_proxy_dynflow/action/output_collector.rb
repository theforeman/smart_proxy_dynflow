# frozen_string_literal: true
module Proxy::Dynflow::Action
  class OutputCollector < ::Proxy::Dynflow::Action::Runner
    def init_run
      output[:result] = []
      output[:runner_id] = input[:runner_id]
      suspend
    end
  end
end
