require 'rest-client'

# rubocop:disable Lint/HandleExceptions
begin
  require 'smart_proxy_dynflow/callback'
rescue LoadError
end
# rubocop:enable Lint/HandleExceptions

module SmartProxyDynflowCore
  module Callback
    class Request
      class << self
        def send_to_foreman_tasks(callback_info, data)
          self.new.callback(prepare_payload(callback_info, data))
        end

        def ssl_options
          return @ssl_options if defined? @ssl_options
          @ssl_options = {}
          settings = Settings.instance
          return @ssl_options unless URI.parse(settings.foreman_url).scheme == 'https'

          @ssl_options[:verify_ssl] = OpenSSL::SSL::VERIFY_PEER

          private_key_file = settings.foreman_ssl_key || settings.ssl_private_key
          if private_key_file
            private_key = File.read(private_key_file)
            @ssl_options[:ssl_client_key] = OpenSSL::PKey::RSA.new(private_key)
          end
          certificate_file = settings.foreman_ssl_cert || settings.ssl_certificate
          if certificate_file
            certificate = File.read(certificate_file)
            @ssl_options[:ssl_client_cert] = OpenSSL::X509::Certificate.new(certificate)
          end
          ca_file = settings.foreman_ssl_ca || settings.ssl_ca_file
          @ssl_options[:ssl_ca_file] = ca_file if ca_file
          @ssl_options
        end
        # rubocop:enable Metrics/PerceivedComplexity

        private

        def prepare_payload(callback, data)
          { :callback => callback, :data => data }.to_json
        end
      end

      def callback(payload)
        response = callback_resource.post(payload, :content_type => :json)
        if response.code.to_s != "200"
          raise "Failed performing callback to Foreman server: #{response.code} #{response.body}"
        end
        response
      end

      private

      def callback_resource
        @resource ||= RestClient::Resource.new(Settings.instance.foreman_url + '/foreman_tasks/api/tasks/callback',
                                               self.class.ssl_options)
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
        plan_action(Callback::Action, callback, planned_action.output) if callback
      end
    end
  end
end
