require 'webrick/https'
require 'smart_proxy_dynflow_core/bundler_helper'
require 'smart_proxy_dynflow_core/settings'
module SmartProxyDynflowCore
  class Launcher

    def self.launch!
      self.new.start
    end

    def start
      load_settings!
      Settings.instance.standalone = true
      Core.ensure_initialized
      Rack::Server.new(rack_settings).start
    end

    def load_settings!
      config_dir = File.join(File.dirname(__FILE__), '..', '..', 'config')
      Settings.load_global_settings(File.join(config_dir, 'settings.yml'))

      BundlerHelper.require_groups(:default)

      Dir[File.join(config_dir, 'settings.d', '*.yml')].each { |path| Settings.load_plugin_settings(path) }
    end

    def self.route_mapping(rack_builder)
      rack_builder.map '/console' do
        run Core.web_console
      end

      rack_builder.map '/' do
        run Api
      end
    end

    private

    def rack_settings
      settings = if https_enabled?
                   # TODO: Use a logger
                   puts "Using HTTPS"
                   https_app
                 else
                   # TODO: Use a logger
                   puts "Using HTTP"
                   {}
                 end
      settings.merge(base_settings)
    end

    def app
      Rack::Builder.new do
        SmartProxyDynflowCore::Launcher.route_mapping(self)
      end
    end

    def base_settings
      {
        :app => app,
        :Host => Settings.instance.Host,
        :Port => Settings.instance.Port,
        :daemonize => false
      }
    end

    def https_app
      ssl_options  = OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:options]
      ssl_options |= OpenSSL::SSL::OP_CIPHER_SERVER_PREFERENCE if defined?(OpenSSL::SSL::OP_CIPHER_SERVER_PREFERENCE)
      # This is required to disable SSLv3 on Ruby 1.8.7
      ssl_options |= OpenSSL::SSL::OP_NO_SSLv2 if defined?(OpenSSL::SSL::OP_NO_SSLv2)
      ssl_options |= OpenSSL::SSL::OP_NO_SSLv3 if defined?(OpenSSL::SSL::OP_NO_SSLv3)
      ssl_options |= OpenSSL::SSL::OP_NO_TLSv1 if defined?(OpenSSL::SSL::OP_NO_TLSv1)

      {
        :SSLEnable => true,
        :SSLVerifyClient => OpenSSL::SSL::VERIFY_PEER,
        :SSLPrivateKey => ssl_private_key,
        :SSLCertificate => ssl_certificate,
        :SSLCACertificateFile => Settings.instance.ssl_ca_file,
        :SSLOptions => ssl_options
      }
    end

    def https_enabled?
      Settings.instance.use_https
    end

    def ssl_private_key
      OpenSSL::PKey::RSA.new(File.read(Settings.instance.ssl_private_key))
    rescue Exception => e
      # TODO: Use a logger
      STDERR.puts "Unable to load private SSL key. Are the values correct in settings.yml and do permissions allow reading?: #{e}"
      # logger.error "Unable to load private SSL key. Are the values correct in settings.yml and do permissions allow reading?: #{e}"
      raise e
    end

    def ssl_certificate
      OpenSSL::X509::Certificate.new(File.read(Settings.instance.ssl_certificate))
    rescue Exception => e
      # TODO: Use a logger
      STDERR.puts "Unable to load SSL certificate. Are the values correct in settings.yml and do permissions allow reading?: #{e}"
      # logger.error "Unable to load SSL certificate. Are the values correct in settings.yml and do permissions allow reading?: #{e}"
      raise e
    end
  end
end
