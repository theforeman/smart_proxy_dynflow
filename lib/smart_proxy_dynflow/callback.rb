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
          logger.debug "Proxy request from #{request.host_with_port}#{request.path} to #{uri}#{path}"
          req = case request.env['REQUEST_METHOD']
                when 'GET'
                  request_factory.create_get path, request.env['rack.request.query_hash']
                when 'POST'
                  request_factory.create_post path, request.body.read
                end
          req['X-Forwarded-For'] = request.env['HTTP_HOST']
          req['AUTHORIZATION'] = request.env['HTTP_AUTHORIZATION']
          response = send_request req
          logger.debug "Proxy request status #{response.code} - #{response}"
          response
        end

        def self.relay(request, from, to)
          self.new.relay request, from, to
        end

        private

        def logger
          Proxy::LogBuffer::Decorator.instance
        end
      end
    end
  end
end
