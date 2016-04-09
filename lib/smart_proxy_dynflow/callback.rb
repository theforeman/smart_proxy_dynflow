require 'proxy/request'

module Proxy
  class Dynflow
    module Callback
      class Request < Proxy::HttpRequest::ForemanRequest
        def callback(payload)
          response = send_request(request_factory.create_post('foreman_tasks/api/tasks/callback', payload))
          if response.code != "200"
            raise "Failed performing callback to Foreman server: #{response.code} #{response.body}"
          end
          response
        end

        def self.send_to_foreman_tasks(payload)
          self.new.callback(payload)
        end
      end
    end
  end
end
