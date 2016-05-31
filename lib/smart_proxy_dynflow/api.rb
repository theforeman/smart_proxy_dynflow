require 'sinatra/base'
require 'proxy/helpers'
require 'sinatra/authorization'
module Proxy
  class Dynflow
    class Api < ::Sinatra::Base
      helpers ::Proxy::Helpers
      helpers ::Proxy::Dynflow::Helpers
      extend ::Sinatra::Authorization

      authorize_with_trusted_hosts
      authorize_with_ssl_client

      before do
        logger = Proxy::LogBuffer::Decorator.instance
        content_type :json
      end

      post "/tasks/callback" do
        response = Proxy::Dynflow::Callback::Request.send_to_foreman_tasks(request.body.read)
        logger.info "Callback to foreman #{response.code} - #{response}"
        status response.code
        body response.body
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
