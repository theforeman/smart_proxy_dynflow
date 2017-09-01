require 'sinatra/base'
require 'proxy/helpers'

module Proxy
  class Dynflow
    class Api < ::Sinatra::Base
      helpers ::Proxy::Helpers
      helpers ::Proxy::Dynflow::Helpers

      before do
        logger = Proxy::LogBuffer::Decorator.instance
        content_type :json
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
