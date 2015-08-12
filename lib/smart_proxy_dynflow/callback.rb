require 'proxy/request'

module Proxy
  class Dynflow
    module Callback
      class Request < Proxy::HttpRequest::ForemanRequest
        def callback(callback, data)
          payload = { :callback => callback, :data => data }.to_json
          send_request(request_factory.create_post('foreman_tasks/api/tasks/callback', payload))
        end

        def self.send_to_foreman_tasks(callback, data)
          self.new.callback(callback, data)
        end
      end

      class Action < ::Dynflow::Action
        def plan(callback, data)
          plan_self(:callback => callback, :data => data)
        end

        def run
          Callback::Request.send_to_foreman_tasks(input[:callback], input[:data])
        end
      end

      module PlanHelper
        def plan_with_callback(input)
          input = input.dup
          callback = input.delete('callback')

          planned_action = plan_self(input)
          plan_action(::Proxy::Dynflow::Callback::Action, callback, planned_action.output) if callback
        end
      end
    end
  end
end
