require 'sinatra/base'
require 'proxy/helpers'
require 'sinatra/authorization'

module Proxy
  class Dynflow
    class Api < ::Sinatra::Base
      helpers ::Proxy::Helpers
      helpers ::Proxy::Log
      helpers ::Proxy::Dynflow::Helpers
    end
  end
end
