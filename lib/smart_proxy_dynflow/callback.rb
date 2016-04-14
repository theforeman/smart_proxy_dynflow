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

      class Core < Proxy::HttpRequest::ForemanRequest
        def uri
          @uri ||= URI.parse Proxy::Dynflow::Plugin.settings.core_url
        end

        def relay(request)
          path = request.env['REQUEST_PATH'].gsub(/^\/dynflow/, '/api')
          req = case request.env['REQUEST_METHOD']
          when 'GET'
            request_factory.create_get path
          when 'POST'
            request_factory.create_post path, request.body.read
          end
          send_request req
        end

        def self.relay(request)
          self.new.relay request
        end
      end
    end
  end
end
