require 'sinatra/base'
require 'multi_json'

module SmartProxyDynflowCore
  class Api < ::Sinatra::Base
    helpers Helpers
    include AuthorizationHelper

    before do
      logger = Log.instance
      authorize_with_token
      content_type :json
    end

    if defined?(::Proxy::Launcher)
      require 'sinatra/authorization'
      extend Sinatra::Authorization
      authorize_with_trusted_hosts
      authorize_with_ssl_client
    else
      before do
        authorize_with_proxy_ssl_client
      end
    end

    post "/tasks/?" do
      params = MultiJson.load(request.body.read)
      trigger_task(::Dynflow::Utils.constantize(params['action_name']),
                   params['action_input'].merge(:callback_host => callback_host(params, request))).to_json
    end

    post "/tasks/:task_id/cancel" do |task_id|
      cancel_task(task_id).to_json
    end

    get "/tasks/:task_id/status" do |task_id|
      task_status(task_id).to_json
    end

    get "/tasks/count" do
      tasks_count(params['state']).to_json
    end

    post "/tasks/:task_id/done" do |task_id|
      data = MultiJson.load(request.body.read)
      complete_task(task_id, data)
    end

    private

    def callback_host(params, request)
      params.fetch('action_input', {})['proxy_url'] || request.env.values_at('HTTP_X_FORWARDED_FOR', 'HTTP_HOST').compact.first
    end
  end
end
