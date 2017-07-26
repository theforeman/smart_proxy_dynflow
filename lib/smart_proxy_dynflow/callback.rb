require 'proxy/request'

module Proxy
  class Dynflow
    module Callback
      class Core < Proxy::HttpRequest::ForemanRequest
        def uri
          @uri ||= URI.parse Proxy::Dynflow::Plugin.settings.core_url
        end

        def relay(request, from, to)
          path = request.path.gsub(from, to)
          Proxy::LogBuffer::Decorator.instance.debug "Proxy request from #{request.host_with_port}#{request.path} to #{uri.to_s}#{path}"
          req = case request.env['REQUEST_METHOD']
                  when 'GET'
                    request_factory.create_get path, request.env['rack.request.query_hash']
                  when 'POST'
                    request_factory.create_post path, request.body.read
                end
          req['X-Forwarded-For'] = request.env['HTTP_HOST']
          response = send_request req
          Proxy::LogBuffer::Decorator.instance.debug "Proxy request status #{response.code} - #{response}"
          response
        end

        def self.relay(request, from, to)
          self.new.relay request, from, to
        end
      end
    end
  end
end
