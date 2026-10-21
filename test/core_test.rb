# frozen_string_literal: true

require 'test_helper'

module Proxy::Dynflow
  class CoreTest < Minitest::Spec
    include Rack::Test::Methods

    def app
      @app ||= Core.web_console
    end

    before do
      Proxy::SETTINGS.stubs(:trusted_hosts).returns(['console.example.org'])
      certificate = mock
      certificate.stubs(:subject).returns('CN=console.example.org')
      OpenSSL::X509::Certificate.stubs(:new).returns(certificate)
    end

    it 'allows the console for a trusted client certificate' do
      get '/', {}, 'HTTPS' => 'yes', 'SSL_CLIENT_CERT' => 'client certificate'

      assert_equal 200, last_response.status
    end

    it 'rejects a client certificate from an untrusted host' do
      certificate = mock
      certificate.stubs(:subject).returns('CN=untrusted.example.org')
      OpenSSL::X509::Certificate.stubs(:new).returns(certificate)

      get '/', {}, 'HTTPS' => 'yes', 'SSL_CLIENT_CERT' => 'client certificate'

      assert_equal 403, last_response.status
    end

    it 'rejects access without a client certificate' do
      get '/', {}, 'HTTPS' => 'yes'

      assert_equal 403, last_response.status
    end
  end
end
