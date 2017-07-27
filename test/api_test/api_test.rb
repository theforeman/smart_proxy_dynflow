require 'test_helper'
require 'json'
require 'smart_proxy_dynflow/api.rb'

class Proxy::Dynflow
  class ApiTest < Minitest::Spec
    include Rack::Test::Methods

    def app
      Proxy::Dynflow::Api.new
    end

    def hostname
      'somehost.somedomain.org:9000'
    end

    def request_factory(kind, path)
      body = mock()
      body.stubs(:read).returns("")
      env = {
        'REQUEST_METHOD' => kind,
        'rack.request.query_hash' => {},
        'HTTP_HOST' => hostname
      }
      OpenStruct.new(:env => env, :body => body, :path => '/dynflow' + path)
    end

    let(:new_request) { Net::HTTP::Get.new 'example.org' }

    it 'relays GET requests' do
      factory = mock()
      factory.expects(:create_get).with('/tasks/count', {}).returns(new_request)
      Proxy::Dynflow::Callback::Core.any_instance.expects(:request_factory).returns(factory)
      Proxy::Dynflow::Callback::Core.any_instance
                                    .expects(:send_request).with(new_request)
                                    .returns(OpenStruct.new(:code => 200, :body => {'count' => 0}))
      Sinatra::Base.any_instance.expects(:request).times(4).returns(request_factory('GET', '/tasks/count'))
      get '/tasks/count'
      new_request['X-Forwarded-For'].must_equal hostname
    end

    it 'relays POST requests' do
      factory = mock()
      factory.expects(:create_post).with('/tasks/12345/cancel', '').returns(new_request)
      Proxy::Dynflow::Callback::Core.any_instance.expects(:request_factory).returns(factory)
      Proxy::Dynflow::Callback::Core.any_instance
                                    .expects(:send_request).with(new_request)
                                    .returns(OpenStruct.new(:code => 200, :body => {'count' => 0}))
      Sinatra::Base.any_instance.expects(:request).times(4).returns(request_factory('POST', '/tasks/12345/cancel'))
      post '/tasks/12345/cancel', {}
      new_request['X-Forwarded-For'].must_equal hostname
    end
  end
end
