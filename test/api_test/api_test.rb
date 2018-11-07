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

    def request_factory(kind, path, env = {})
      body = mock
      body.stubs(:read).returns("")
      env = env.merge(
        'REQUEST_METHOD' => kind,
        'rack.request.query_hash' => {},
        'HTTP_HOST' => hostname,
        'PATH_INFO' => "/dynflow#{path}"
      )
      Sinatra::Request.new(env).tap do |r|
        r.stubs(:body).returns(body)
      end
    end

    let(:new_request) { Net::HTTP::Get.new 'example.org' }

    def mock_core_service(method, path, response)
      factory = mock
      factory.expects(method).with { |p| p == path }.returns(new_request)
      Proxy::Dynflow::Callback::Core.any_instance.expects(:request_factory).returns(factory)
      Proxy::Dynflow::Callback::Core.any_instance
                                    .expects(:send_request).with(new_request)
                                    .returns(OpenStruct.new(response))
    end

    it 'relays GET requests' do
      mock_core_service(:create_get, '/tasks/count', :code => 200, :body => {'count' => 0})
      Proxy::Dynflow::Api.any_instance.stubs(:request).returns(request_factory('GET', '/tasks/count'))
      get '/tasks/count'
      new_request['X-Forwarded-For'].must_equal hostname
    end

    it 'relays POST requests' do
      factory = mock
      factory.expects(:create_post).with('/tasks/12345/cancel', '').returns(new_request)
      Proxy::Dynflow::Callback::Core.any_instance.expects(:request_factory).returns(factory)
      Proxy::Dynflow::Callback::Core.any_instance
                                    .expects(:send_request).with(new_request)
                                    .returns(OpenStruct.new(:code => 200, :body => {'count' => 0}))
      Proxy::Dynflow::Api.any_instance.stubs(:request).returns(request_factory('POST', '/tasks/12345/cancel'))
      post '/tasks/12345/cancel', {}
      new_request['X-Forwarded-For'].must_equal hostname
    end

    it 'refuses unauthorized http connections (using remote_fqdn)' do
      Proxy::Dynflow::Api.any_instance.stubs(:request).returns(request_factory('POST', '/tasks'))
      Proxy::Dynflow::Api.any_instance.stubs(:remote_fqdn).returns('unauthorized_host.example.com')
      Proxy::SETTINGS.stubs(:trusted_hosts).returns(["mytrustedhost.example.com"])
      post '/tasks'
      assert(last_response.forbidden?, 'The request should be forbidden')
    end

    it 'accepts authorized http connections (using remote_fqdn)' do
      mock_core_service(:create_post, '/tasks', :code => 200, :body => {})
      Proxy::Dynflow::Api.any_instance.stubs(:request).returns(request_factory('POST', '/tasks'))
      Proxy::Dynflow::Api.any_instance.stubs(:remote_fqdn).returns('mytrustedhost.example.com')
      Proxy::SETTINGS.stubs(:trusted_hosts).returns(["mytrustedhost.example.com"])
      post '/tasks'
      assert(last_response.ok?, 'The response should be ok')
    end

    it 'refuses unauthorized https connections (using https_cert_cn)' do
      Proxy::Dynflow::Api.any_instance.stubs(:request)
                         .returns(request_factory('POST', '/tasks', 'HTTPS' => 'yes', 'SSL_CLIENT_CERT' => 'mytrustedcert'))
      Proxy::Dynflow::Api.any_instance.stubs(:https_cert_cn).returns('unauthorized_host.example.com')
      Proxy::SETTINGS.stubs(:trusted_hosts).returns(["mytrustedhost.example.com"])
      post '/tasks'
      assert(last_response.forbidden?, 'The request should be forbidden')
    end

    it 'accepts unauthorized https connections (using https_cert_cn)' do
      mock_core_service(:create_post, '/tasks', :code => 200, :body => {})
      Proxy::Dynflow::Api.any_instance.stubs(:request)
                         .returns(request_factory('POST', '/tasks', 'HTTPS' => 'yes', 'SSL_CLIENT_CERT' => 'mytrustedcert'))
      Proxy::Dynflow::Api.any_instance.stubs(:https_cert_cn).returns('mytrustedhost.example.com')
      Proxy::SETTINGS.stubs(:trusted_hosts).returns(["mytrustedhost.example.com"])
      post '/tasks'
      assert(last_response.ok?, 'The response should be ok')
    end

    it 'refuses unauthorized https connections (when client cert is not supplied)' do
      Proxy::Dynflow::Api.any_instance.stubs(:request)
                         .returns(request_factory('POST', '/tasks', 'HTTPS' => 'yes'))
      Proxy::Dynflow::Api.any_instance.stubs(:https_cert_cn).returns('mytrustedhost.example.com')
      Proxy::SETTINGS.stubs(:trusted_hosts).returns(["mytrustedhost.example.com"])
      post '/tasks'
      assert(last_response.forbidden?, 'The request should be forbidden')
    end

    it 'passes the done requests to the core service, when authorization keys are provided' do
      mock_core_service(:create_post, '/tasks/123/done', :code => 200, :body => {})
      Proxy::Dynflow::Api.any_instance.stubs(:request)
                         .returns(request_factory('POST', '/tasks/123/done', 'HTTPS' => 'yes',
                                                           'HTTP_AUTHORIZATION' => 'Basic ValidToken'))
      Proxy::Dynflow::Api.any_instance.stubs(:https_cert_cn).returns('mytrustedhost.example.com')
      Proxy::SETTINGS.stubs(:trusted_hosts).returns(["mytrustedhost.example.com"])
      post '/tasks'
      assert(last_response.ok?, 'The response should be ok')
    end
  end
end
