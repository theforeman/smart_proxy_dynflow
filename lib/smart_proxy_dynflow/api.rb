require 'sinatra/base'
require 'proxy/helpers'
require 'sinatra/authorization'

module Proxy
  class Dynflow
    class Api < ::Sinatra::Base
      helpers ::Proxy::Helpers
      helpers ::Proxy::Dynflow::Helpers

      before do
        logger = Proxy::LogBuffer::Decorator.instance
        content_type :json
        if request.env['HTTP_AUTHORIZATION'] && request.env['PATH_INFO'].end_with?('/done')
          # Halt running before callbacks if a token is provided and the request is notifying about task being done
          return
        end
      end

      helpers Sinatra::Authorization

      post "/*" do
        relay_request
      end

      get "/*" do
        relay_request
      end
    end
  end
end
