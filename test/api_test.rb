require 'test_helper'
require 'json'
require 'smart_proxy_dynflow/api.rb'

class Proxy::Dynflow
  class ApiTest < Minitest::Spec
    include Rack::Test::Methods

    def app
      Proxy::Dynflow::Api.new
    end

    it 'relays GET requests' do
      factory = mock()
      factory.expects(:create_get).with('/tasks/count', {})
      Proxy::Dynflow::Callback::Core.any_instance.expects(:request_factory).returns(factory)
      Proxy::Dynflow::Callback::Core.any_instance
                                    .expects(:send_request)
                                    .returns(OpenStruct.new(:code => 200, :body => {'count' => 0}))
      get '/tasks/count'
    end

    it 'relays POST requests' do
      factory = mock()
      factory.expects(:create_post).with('/tasks/12345/cancel', '')
      Proxy::Dynflow::Callback::Core.any_instance.expects(:request_factory).returns(factory)
      Proxy::Dynflow::Callback::Core.any_instance
                                    .expects(:send_request)
                                    .returns(OpenStruct.new(:code => 200, :body => {'count' => 0}))
      post '/tasks/12345/cancel', {}
    end

    it 'relays callbacks' do
      data = '{"callback": "callback", "data": "data"}'
      Proxy::Dynflow::Callback::Request.expects(:send_to_foreman_tasks).with(data)
                                       .returns(OpenStruct.new(:code => 200, :body => data))
      post '/tasks/callback', data
    end

  end
end
