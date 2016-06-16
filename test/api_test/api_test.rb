require 'test_helper'
require 'json'
require 'smart_proxy_dynflow/api.rb'

class Proxy::Dynflow
  class ApiTest < Minitest::Spec
    include Rack::Test::Methods

    def app
      Proxy::Dynflow::Api.new
    end

    def request_factory(kind, path)
      body = mock()
      body.stubs(:read).returns("")
      env = {
        'REQUEST_METHOD' => kind,
        'rack.request.query_hash' => {}
      }
      OpenStruct.new(:env => env, :body => body, :path => '/dynflow' + path)
    end

    it 'relays GET requests' do
      factory = mock()
      factory.expects(:create_get).with('/tasks/count', {})
      Proxy::Dynflow::Callback::Core.any_instance.expects(:request_factory).returns(factory)
      Proxy::Dynflow::Callback::Core.any_instance
                                    .expects(:send_request)
                                    .returns(OpenStruct.new(:code => 200, :body => {'count' => 0}))
      Sinatra::Base.any_instance.expects(:request).times(4).returns(request_factory('GET', '/tasks/count'))

      get '/tasks/count'
    end

    it 'relays POST requests' do
      factory = mock()
      factory.expects(:create_post).with('/tasks/12345/cancel', '')
      Proxy::Dynflow::Callback::Core.any_instance.expects(:request_factory).returns(factory)
      Proxy::Dynflow::Callback::Core.any_instance
                                    .expects(:send_request)
                                    .returns(OpenStruct.new(:code => 200, :body => {'count' => 0}))
      Sinatra::Base.any_instance.expects(:request).times(4).returns(request_factory('POST', '/tasks/12345/cancel'))
      post '/tasks/12345/cancel', {}
    end

  end
end
