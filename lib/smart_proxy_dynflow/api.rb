require 'sinatra/base'
require 'proxy/helpers'
require 'sinatra/authorization'

module Proxy
  module Dynflow
    class Api < ::Sinatra::Base
      helpers ::Proxy::Helpers
      helpers ::Proxy::Log
      helpers ::Proxy::Dynflow::Helpers

      include ::Sinatra::Authorization::Helpers

      TASK_UPDATE_REGEXP_PATH = %r{/tasks/(\S+)/(update|done)}

      before do
        if match = request.path_info.match(TASK_UPDATE_REGEXP_PATH)
          task_id = match[1]
          action = match[2]
          authorize_with_token(task_id: task_id, clear: action == 'done')
        else
          do_authorize_any
        end
        content_type :json
      end

      post "/tasks/status" do
        params = MultiJson.load(request.body.read)
        ids = params.fetch('task_ids', [])
        result = world.persistence
                      .find_execution_plans(:filters => { :uuid => ids }).reduce({}) do |acc, plan|
          acc.update(plan.id => { 'state' => plan.state, 'result' => plan.result })
        end
        MultiJson.dump(result)
      end

      post "/tasks/launch/?" do
        params = MultiJson.load(request.body.read)
        launcher = launcher_class(params).new(world, callback_host(params, request), params.fetch('options', {}))
        plan = launcher.launch!(params['input'])
        launcher.results.to_json
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

      # capturing post "/tasks/:task_id/(update|done)"
      post TASK_UPDATE_REGEXP_PATH do |task_id, _action|
        data = MultiJson.load(request.body.read)
        dispatch_external_event(task_id, data)
      end

      get "/tasks/operations" do
        TaskLauncherRegistry.operations.to_json
      end

      private

      def callback_host(params, request)
        params.fetch('action_input', {})['proxy_url'] ||
          request.env.values_at('HTTP_X_FORWARDED_FOR', 'HTTP_HOST').compact.first
      end

      def launcher_class(params)
        operation = params.fetch('operation')
        if TaskLauncherRegistry.key?(operation)
          TaskLauncherRegistry.fetch(operation)
        else
          halt 404, MultiJson.dump(:error => "Unknown operation '#{operation}' requested.")
        end
      end
    end
  end
end
