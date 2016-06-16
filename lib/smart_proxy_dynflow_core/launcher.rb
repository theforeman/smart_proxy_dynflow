require 'webrick/https'
require 'smart_proxy_dynflow_core/bundler_helper'
require 'smart_proxy_dynflow_core/settings'
module SmartProxyDynflowCore
  class Launcher

    def self.launch!(options)
      self.new.start options
    end

    def start(options)
      load_settings!(options)
      Settings.instance.standalone = true
      Rack::Server.new(rack_settings).start
    end

    def load_settings!(options = {})
      config_dir, one_config = options.values_at(:config_dir, :one_config)
      possible_config_dirs = [
        '/etc/smart_proxy_dynflow_core',
        File.expand_path('~/.config/smart_proxy_dynflow_core'),
        File.join(File.dirname(__FILE__), '..', '..', 'config'),
      ]
      possible_config_dirs << config_dir if config_dir
      BundlerHelper.require_groups(:default)
      possible_config_dirs.reverse! if one_config
      possible_config_dirs.select { |config_dir| File.directory? config_dir }.each do |config_dir|
        break if load_config_dir(config_dir) && one_config
      end
      Settings.instance.daemonize = options[:daemonize] if options.key?(:daemonize)
      Settings.instance.pid_file = options[:pid_file] if options.key?(:pid_file)
      Settings.loaded!
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
                   Log.instance.debug "Using HTTPS"
                   https_app
                 else
                   Log.instance.debug "Using HTTP"
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
        :Host => Settings.instance.listen,
        :Port => Settings.instance.port,
        :AccessLog => [[Log.log_file, WEBrick::AccessLog::COMMON_LOG_FORMAT]],
        :Logger => Log.instance,
        :daemonize => Settings.instance.daemonize,
        :pid => Settings.instance.pid_file
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
      Log.instance.fatal "Unable to load private SSL key. Are the values correct in settings.yml and do permissions allow reading?: #{e}"
      raise e
    end

    def ssl_certificate
      OpenSSL::X509::Certificate.new(File.read(Settings.instance.ssl_certificate))
    rescue Exception => e
      Log.instance.fatal "Unable to load SSL certificate. Are the values correct in settings.yml and do permissions allow reading?: #{e}"
      raise e
    end

    def load_config_dir(dir)
      settings_yml = File.join(dir, 'settings.yml')
      if File.exist? settings_yml
        Log.instance.debug "Loading settings from #{dir}"
        Settings.load_global_settings settings_yml
        Dir[File.join(dir, 'settings.d', '*.yml')].each { |path| Settings.load_plugin_settings(path) }
        true
      end
    end
  end
end
