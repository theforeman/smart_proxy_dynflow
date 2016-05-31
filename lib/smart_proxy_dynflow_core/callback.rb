require 'rest-client'
require 'dynflow'

begin
  require 'smart_proxy_dynflow/callback'
rescue LoadError
end

module SmartProxyDynflowCore
  module Callback
    class Request
      def callback(payload)
        response = callback_resource.post payload
        if response.code != 200
          raise "Failed performing callback to smart proxy: #{response.code} #{response.body}"
        end
        response
      end

      def self.callback(callback, data)
        self.new.callback(self.prepare_payload(callback, data))
      end

      private

      def self.prepare_payload(callback, data)
        { :callback => callback, :data => data }.to_json
      end

      def callback_resource
        @resource ||= RestClient::Resource.new Settings.instance.callback_url + '/dynflow/tasks/callback',
                                               ssl_options
      end

      def ssl_options
        return {} unless Settings.instance.use_https
        client_key = File.read  Settings.instance.ssl_private_key
        client_cert = File.read Settings.instance.ssl_certificate
        {
          :ssl_client_cert => OpenSSL::X509::Certificate.new(client_cert),
          :ssl_client_key  => OpenSSL::PKey::RSA.new(client_key),
          :ssl_ca_file     => Settings.instance.ssl_ca_file,
          :verify_ssl      => OpenSSL::SSL::VERIFY_PEER
        }
      end
    end

    class Action < ::Dynflow::Action
      def plan(callback, data)
        plan_self(:callback => callback, :data => data)
      end

      def run
        callback = (Settings.instance.standalone ? Callback::Request : Proxy::Dynflow::Callback::Request).new
        callback.callback(SmartProxyDynflowCore::Callback::Request.prepare_payload(input[:callback], input[:data]))
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
