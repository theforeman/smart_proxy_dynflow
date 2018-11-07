require 'sinatra/base'
require 'proxy/helpers'
require 'sinatra/authorization'

module Proxy
  class Dynflow
    class Api < ::Sinatra::Base
      helpers ::Proxy::Helpers
      helpers ::Proxy::Log
      helpers ::Proxy::Dynflow::Helpers

      before do
        content_type :json
        if request.env['HTTP_AUTHORIZATION'] && request.env['PATH_INFO'].end_with?('/done')
          # Halt running before callbacks if a token is provided and the request is notifying about task being done
          return
        else
          do_authorize_with_ssl_client
          do_authorize_with_trusted_hosts
        end
      end


      # TODO: move this to foreman-proxy to reduce code duplicities
      def do_authorize_with_trusted_hosts
        # When :trusted_hosts is given, we check the client against the list
        # HTTPS: test the certificate CN
        # HTTP: test the reverse DNS entry of the remote IP
        trusted_hosts = Proxy::SETTINGS.trusted_hosts
        if trusted_hosts
          if [ 'yes', 'on', 1 ].include? request.env['HTTPS'].to_s
            fqdn = https_cert_cn
            source = 'SSL_CLIENT_CERT'
          else
            fqdn = remote_fqdn(Proxy::SETTINGS.forward_verify)
            source = 'REMOTE_ADDR'
          end
          fqdn = fqdn.downcase
          logger.debug "verifying remote client #{fqdn} (based on #{source}) against trusted_hosts #{trusted_hosts}"

          unless Proxy::SETTINGS.trusted_hosts.include?(fqdn)
            log_halt 403, "Untrusted client #{fqdn} attempted " \
                          "to access #{request.path_info}. Check :trusted_hosts: in settings.yml"
          end
        end
      end

      def do_authorize_with_ssl_client
        if ['yes', 'on', '1'].include? request.env['HTTPS'].to_s
          if request.env['SSL_CLIENT_CERT'].to_s.empty?
            log_halt 403, "No client SSL certificate supplied"
          end
        else
          logger.debug('require_ssl_client_verification: skipping, non-HTTPS request')
        end
      end

      post "/*" do
        relay_request
      end

      get "/*" do
        relay_request
      end
    end
  end
end
