module Proxy
  class Dynflow
    module Helpers
      def relay_request
        response = Proxy::Dynflow::Callback::Core.relay(request)
        status response.code
        body response.body
      end
    end
  end
end
