module Proxy
  class Dynflow
    module Helpers
      def relay_request(from = %r{^/dynflow}, to = '')
        response = Proxy::Dynflow::Callback::Core.relay(request, from, to)
        content_type response.content_type
        status response.code
        body response.body
      end
    end
  end
end
