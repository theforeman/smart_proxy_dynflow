require 'io/wait'
require 'pty'
require 'smart_proxy_dynflow/runner/command'

module Proxy::Dynflow
  module Runner
    class CommandRunner < Base
      include Command
    end
  end
end
