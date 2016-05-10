require 'ostruct'

module SmartProxyDynflowCore
  class Settings < OpenStruct

    DEFAULT_SETTINGS = {
        :database => '/var/lib/foreman-proxy/dynflow/dynflow.sqlite',
        :callback_url => 'https://127.0.0.1:8443',
        :console_auth => true,
        :foreman_url => 'http://127.0.0.1:3000',
        :Host => '127.0.0.1',
        :Port => '8008',
        :use_https => false,
        :ssl_ca_file => nil,
        :ssl_private_key => nil,
        :ssl_certificate => nil,
        :standalone => false,
        :plugins => {}
    }

    def initialize(settings = {})
      super(DEFAULT_SETTINGS.merge(settings))
    end

    def self.instance
      SmartProxyDynflowCore::SETTINGS
    end

    def self.load_global_settings(path)
      if File.exists? File.join(path)
        YAML.load(File.read(path)).each do |key, value|
          SETTINGS[key] = value
        end
      end
    end

    def self.load_from_proxy(plugin)
      [:ssl_certificate, :ssl_ca_file, :ssl_private_key, :foreman_url].each do |key|
        SETTINGS[key] = Proxy::SETTINGS[key]
      end
      SETTINGS.callback_url = SETTINGS.foreman_url
      [:database, :core_url, :console_auth].each do |key|
        SETTINGS[key] = plugin.settings[key]
      end
      SETTINGS.plugins.values.each { |plugin| plugin.load_settings_from_proxy }
    end

    def self.load_plugin_settings(path)
      settings = YAML.load(File.read(path))
      name = File.basename(path).gsub(/\.yml$/, '')
      if SETTINGS.plugins.key? name
        settings = SETTINGS.plugins[name].to_h.merge(settings)
      end
      SETTINGS.plugins[name] = OpenStruct.new settings
    end
  end
end

SmartProxyDynflowCore::SETTINGS = SmartProxyDynflowCore::Settings.new
