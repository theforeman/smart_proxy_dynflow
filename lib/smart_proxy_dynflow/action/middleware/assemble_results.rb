# frozen_string_literal: true

module Proxy::Dynflow::Action::Middleware
  class AssembleResults < ::Dynflow::Middleware
    def present
      unless %i[error success skipped].include?(action.run_step&.state)
        action.output[:result] = action.output_result
      end
      pass
    end
  end
end
