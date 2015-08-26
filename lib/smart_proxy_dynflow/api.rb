module Proxy
  class Dynflow
    class Api < ::Sinatra::Base
      helpers ::Proxy::Helpers
      helpers ::Proxy::Dynflow::Helpers

      authorize_with_trusted_hosts
      authorize_with_ssl_client

      before do
        content_type :json
      end

      post "/tasks/?" do
        params = parse_json_body
        trigger_task(::Dynflow::Utils.constantize(params['action_name']), params['action_input']).to_json
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
