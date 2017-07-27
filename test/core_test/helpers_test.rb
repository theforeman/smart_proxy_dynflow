require 'ostruct'
require 'foreman_tasks_core/otp_manager'

module SmartProxyDynflowCore
  class HelpersTest < Minitest::Spec
    include Rack::Test::Methods

    def app
      @app ||= SmartProxyDynflowCore::Api.new
    end

    before do
      header 'Content-Type', 'application/json'
    end

    it 'is not authenticated over HTTP' do
      get '/tasks/count', {}, { }
      assert last_response.status == 200
    end

    it 'requires client SSL certificate when using https' do
      Log.instance.expects(:error).twice
      # HTTPS without client cert
      get '/tasks/count', {}, { 'HTTPS' => 'yes' }
      assert last_response.status == 403

      serial = 1
      cert = 'valid cert'
      OpenSSL::X509::Certificate.expects(:new).with(cert)
                                .returns(OpenStruct.new(:serial => serial)).twice
      # HTTPS with invalid cert
      get '/tasks/count', {}, { 'HTTPS' => 'yes', 'SSL_CLIENT_CERT' => 'valid cert' }
      assert last_response.status == 403

      SmartProxyDynflowCore::Core.instance.expects(:accepted_cert_serial).returns(serial)
      # HTTPS with valid cert
      get '/tasks/count', {}, { 'HTTPS' => 'yes', 'SSL_CLIENT_CERT' => 'valid cert' }
      assert last_response.status == 200
    end

    it 'skips client cert authentication if token succeeds' do
      username = 'user'
      otp = ::ForemanTasksCore::OtpManager.generate_otp(username)
      http_auth = 'Basic ' + ::ForemanTasksCore::OtpManager.tokenize(username, otp)
      Log.instance.expects(:debug).with('authorized with token')
      get '/tasks/count', {}, 'HTTP_AUTHORIZATION' => http_auth
      assert last_response.status == 200
    end

    it 'tries ssl client cert based authorization when token based fails' do
      ForemanTasksCore::OtpManager.generate_otp('someone')
      http_auth = 'Basic ' + ::ForemanTasksCore::OtpManager.tokenize('someone', 'wrong pass')
      get '/tasks/count', {}, 'HTTPS' => 'yes', 'HTTP_AUTHORIZATION' => http_auth
      assert last_response.status == 403
    end
  end
end
