require 'rest-client'
module Proxy
  class Dynflow
    module Helpers
      def relay_request(host = Proxy::Dynflow::Plugin.settings.core_url)
        path = request.env['REQUEST_PATH'].gsub(/^\/dynflow/, '/api')
        result = case request.env['REQUEST_METHOD']
        when 'GET'
          resource[path].get
        when 'POST'
          resource[path].post request.body.read
        end
        status result.code
        body result.body
      rescue RestClient::Exception => e
        status e.http_code
        body e.http_body
      end

      def headers
        {
          :content_type => :json,
          :accept => :json
        }
      end

      def resource
        @resource ||= RestClient::Resource.new(host, :headers => headers)
      end
    end
  end
end
