require 'proxy/request'

module Proxy
  class Dynflow
    class ForemanTasksCallback < Proxy::HttpRequest::ForemanRequest
      def callback(callback, data)
        payload = {:callback => callback, :data => data}.to_json
        send_request(request_factory.create_post("/foreman_tasks/api/tasks/callback", payload))
      end

      def self.send_to_foreman_tasks(callback, data)
        self.new.callback(callback, data)
      end
    end
  end
end
