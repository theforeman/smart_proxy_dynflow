module Proxy
  class Dynflow
    class Api < ::Sinatra::Base
      helpers ::Proxy::Helpers
      helpers ::Proxy::Dynflow::Helpers

      before do
        content_type :json
      end

      post "/tasks/?" do
        params = parse_json_body
        trigger_task(params['action_name'].constantize, params['action_input']).to_json
      end

      post "/tasks/:task_id/cancel" do |task_id|
        cancel_task(task_id).to_json
      end

      get "/tasks/:task_id/status" do |task_id|
        task_status(task_id).to_json
      end
    end
  end
end
