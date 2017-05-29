require 'ostruct'

# Implement hash-like access for 1.9.3 and older
if RUBY_VERSION.split('.').first.to_i < 2
  class OpenStruct
    def [](key)
      self.send key
    end

    def []=(key, value)
      self.send "#{key}=", value
    end

    def to_h
      marshal_dump
    end
  end
end

module SmartProxyDynflowCore
  class Settings < OpenStruct

    DEFAULT_SETTINGS = {
        :database => '/var/lib/foreman-proxy/dynflow/dynflow.sqlite',
        :foreman_url => 'https://127.0.0.1:3000',
        :console_auth => true,
        :listen => '127.0.0.1',
        :port => '8008',
        :use_https => false,
        :ssl_ca_file => nil,
        :ssl_private_key => nil,
        :ssl_certificate => nil,
        :ssl_disabled_ciphers => [],
        :foreman_ssl_ca => nil,
        :foreman_ssl_key => nil,
        :foreman_ssl_cert => nil,
        :standalone => false,
        :log_file => '/var/log/foreman-proxy/smart_proxy_dynflow_core.log',
        :log_level => :ERROR,
        :plugins => {},
        :pid_file => '/var/run/foreman-proxy/smart_proxy_dynflow_core.pid',
        :daemonize => false,
        :loaded => false
    }

    PROXY_SETTINGS = [:ssl_ca_file, :ssl_certificate, :ssl_private_key, :foreman_url,
                      :foreman_ssl_ca, :foreman_ssl_cert, :foreman_ssl_key,
                      :log_file, :log_level, :ssl_disabled_ciphers]
    PLUGIN_SETTINGS = [:database, :core_url, :console_auth]

    def initialize(settings = {})
      super(DEFAULT_SETTINGS.merge(settings))
    end

    def self.instance
      SmartProxyDynflowCore::SETTINGS
    end

    def self.load_global_settings(path)
      if File.exists? File.join(path)
        YAML.load_file(path).each do |key, value|
          SETTINGS[key] = value
        end
      end
    end

    def self.loaded!
      Settings.instance.loaded = true
      Log.instance.info 'Settings loaded, reloading logger'
      Log.reload!
    end

    def self.load_from_proxy(plugin)
      plugin_class = if Proxy::VERSION >= '1.16.0'
                       plugin
                     else
                       # DEPRECATION: Remove this branch when dropping support for smart-proxy < 1.16
                       plugin[:class]
                     end
      settings = plugin_class.settings.to_h
      PROXY_SETTINGS.each do |key|
        SETTINGS[key] = Proxy::SETTINGS[key]
      end
      PLUGIN_SETTINGS.each do |key|
        SETTINGS[key] = settings[key] if settings.key?(key)
      end
      SETTINGS.plugins.values.each { |plugin| plugin.load_settings_from_proxy }
      Settings.loaded!
    end

    def self.load_plugin_settings(path)
      settings = YAML.load_file(path)
      name = File.basename(path).gsub(/\.yml$/, '')
      if SETTINGS.plugins.key? name
        settings = SETTINGS.plugins[name].to_h.merge(settings)
      end
      SETTINGS.plugins[name] = OpenStruct.new settings
    end
  end
end

SmartProxyDynflowCore::SETTINGS = SmartProxyDynflowCore::Settings.new
