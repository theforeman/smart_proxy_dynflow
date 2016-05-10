require 'sinatra/base'
require 'multi_json'
require 'dynflow'

module SmartProxyDynflowCore
  class Api < ::Sinatra::Base
    helpers Helpers

    before do
      authorize_with_ssl_client
      content_type :json
    end

    post "/tasks/?" do
      params = MultiJson.load(request.body.read)
      trigger_task(::Dynflow::Utils.constantize(params['action_name']), params['action_input']).to_json
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
  end
end
