# frozen_string_literal: true

require 'io/wait'
require 'pty'
require 'smart_proxy_dynflow/runner/command'

module Proxy::Dynflow
  module Runner
    # This class is now soft-deprecated, see {::Proxy::Dynflow::Runner::Command}
    class CommandRunner < Base
      include Command
    end
  end
end
