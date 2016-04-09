module Proxy
  class Dynflow
    class Api < ::Sinatra::Base
      helpers ::Proxy::Helpers
      helpers ::Proxy::Dynflow::Helpers

      authorize_with_trusted_hosts
      authorize_with_ssl_client

      before do
        content_type :json
      end

      post "/tasks/callback" do
        Proxy::Dynflow::Callback::Request.send_to_foreman_tasks(request.body.read)
      end

      post "/*" do
        relay_request
      end

      get "/*" do
        relay_request
      end
    end
  end
end
