require 'ostruct'
require 'test_helper'
require 'foreman_tasks_core/otp_manager'

class Proxy::Dynflow
  class HelpersTest < Minitest::Spec
    include Rack::Test::Methods

    def app
      @app ||= Proxy::Dynflow::Api.new
    end

    before do
      header 'Content-Type', 'application/json'
    end

    it 'is not authenticated over HTTP' do
      get '/tasks/count', {}, {}
      assert last_response.status == 200
    end

    it 'requires client SSL certificate when using https' do
      Log.instance.expects(:error)
      # HTTPS without client cert
      get '/tasks/count', {}, { 'HTTPS' => 'yes' }
      assert last_response.status == 403

      # HTTPS with valid cert
      get '/tasks/count', {}, { 'HTTPS' => 'yes', 'SSL_CLIENT_CERT' => 'valid cert' }
      assert last_response.status == 200
    end

    it 'performs token-based authentication for task update/done paths' do
      task_id = username = 'task-id'
      other_task_id = 'other-task-id'

      # Happy path for update
      otp = ::ForemanTasksCore::OtpManager.generate_otp(username)
      http_auth = 'Basic ' + ::ForemanTasksCore::OtpManager.tokenize(username, otp)
      Log.instance.stubs(:debug)
      post "/tasks/#{task_id}/update", '{}', 'HTTP_AUTHORIZATION' => http_auth
      assert last_response.status == 200

      # Wrong password
      http_auth = 'Basic ' + ::ForemanTasksCore::OtpManager.tokenize(username, 'wrong pass')
      post "/tasks/#{task_id}/update", '{}', 'HTTP_AUTHORIZATION' => http_auth
      assert last_response.status == 403

      # Wrong task id
      http_auth = 'Basic ' + ::ForemanTasksCore::OtpManager.tokenize(username, otp)
      post "/tasks/#{other_task_id}/update", '{}', 'HTTP_AUTHORIZATION' => http_auth
      assert last_response.status == 403

      # Happy path for done
      http_auth = 'Basic ' + ::ForemanTasksCore::OtpManager.tokenize(username, otp)
      post "/tasks/#{task_id}/done", '{}', 'HTTP_AUTHORIZATION' => http_auth
      assert last_response.status == 200

      # Call to done should remove the token, so using it the second time should fail
      http_auth = 'Basic ' + ::ForemanTasksCore::OtpManager.tokenize(username, otp)
      post "/tasks/#{task_id}/done", '{}', 'HTTP_AUTHORIZATION' => http_auth
      assert last_response.status == 403
    end
  end
end
