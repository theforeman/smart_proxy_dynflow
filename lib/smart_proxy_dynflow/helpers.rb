module Proxy
  class Dynflow
    module Helpers
      def relay_request(from = /^\/dynflow/, to = '/api')
        response = Proxy::Dynflow::Callback::Core.relay(request, from, to)
        status response.code
        body response.body
      end
    end
  end
end
