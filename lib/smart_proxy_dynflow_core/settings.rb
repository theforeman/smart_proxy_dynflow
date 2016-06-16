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
        :callback_url => 'https://127.0.0.1:8443',
        :console_auth => true,
        :foreman_url => 'http://127.0.0.1:3000',
        :listen => '127.0.0.1',
        :port => '8008',
        :use_https => false,
        :ssl_ca_file => nil,
        :ssl_private_key => nil,
        :ssl_certificate => nil,
        :standalone => false,
        :log_file => '/var/log/foreman-proxy/smart_proxy_dynflow_core.log',
        :log_level => :ERROR,
        :plugins => {},
        :pid_file => '/var/run/foreman-proxy/smart_proxy_dynflow_core.pid',
        :daemonize => false,
        :loaded => false
    }

    PROXY_SETTINGS = [:ssl_certificate, :ssl_ca_file, :ssl_private_key, :foreman_url,
                      :log_file, :log_level]
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
      PROXY_SETTINGS.each do |key|
        SETTINGS[key] = Proxy::SETTINGS[key]
      end
      SETTINGS.callback_url = SETTINGS.foreman_url
      PLUGIN_SETTINGS.each do |key|
        SETTINGS[key] = plugin.settings[key]
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
