module Proxy::Dynflow::Action
  module WithExternalPolling
    Poll = Algebrick.atom

    def run(event = nil)
      if event.is_a?(Poll)
        poll
        suspend
      else
        super
      end
    end

    def poll; end
  end
end
