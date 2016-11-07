module SmartProxyDynflowCore
  module AuthorizationHelper
    def authorize_with_proxy_ssl_client
      return if @authenticated

      if %w(yes on 1).include? request.env['HTTPS'].to_s
        if request.env['SSL_CLIENT_CERT'].to_s.empty?
          Log.instance.error "No client SSL certificate supplied"
          halt 403, MultiJson.dump(:error => "No client SSL certificate supplied")
        else
          client_cert = OpenSSL::X509::Certificate.new(request.env['SSL_CLIENT_CERT'])
          if SmartProxyDynflowCore::Core.instance.accepted_cert_serial == client_cert.serial
            @authenticated = true
          else
            Log.instance.error "SSL certificate with unexpected serial supplied"
            halt 403, MultiJson.dump(:error => "SSL certificate with unexpected serial supplied")
          end
        end
      else
        Log.instance.debug 'require_ssl_client_verification: skipping, non-HTTPS request'
      end
    end
    
    def authorize_with_token
      return if @authenticated

      if request.env.key? 'HTTP_AUTHORIZATION'
        if defined?(::ForemanTasksCore)
          auth = request.env['HTTP_AUTHORIZATION']
          basic_prefix = /\ABasic /
          if !auth.to_s.empty? && auth =~ basic_prefix &&
              ForemanTasksCore::OtpManager.authenticate(auth.gsub(basic_prefix, ''))
            Log.instance.debug('authorized with token')
            @authenticated = true
          end
        end
        halt 403, MultiJson.dump(:error => 'Invalid username or password supplied')
      end
    end
  end
end
