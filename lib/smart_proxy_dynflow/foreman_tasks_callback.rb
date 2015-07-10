require 'proxy/request'

module Proxy
  class Dynflow
    class ForemanTasksCallback < Proxy::HttpRequest::ForemanRequest
      def callback(task_id, step_id, data)
        send_request(request_factory.create_post("/foreman_tasks/api/tasks/#{ task_id }/callback/#{ step_id }", {:data => data}.to_json))
      end

      def self.send_to_foreman_tasks(task_id, step_id, data)
        self.new.callback(task_id, step_id, data)
      end
    end
  end
end
