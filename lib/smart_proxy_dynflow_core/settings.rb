require 'ostruct'

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
      :tls_disabled_versions => [],
      :foreman_ssl_ca => nil,
      :foreman_ssl_key => nil,
      :foreman_ssl_cert => nil,
      :log_file => '/var/log/foreman-proxy/smart_proxy_dynflow_core.log',
      :log_level => :ERROR,
      :plugins => {},
      :pid_file => '/var/run/foreman-proxy/smart_proxy_dynflow_core.pid',
      :daemonize => false,
      :execution_plan_cleaner_age => 60 * 60 * 24,
      :loaded => false,
      :file_logging_pattern => '%d %.8X{request} [%.1l] %m',
      :system_logging_pattern => '%.8X{request} [%.1l] %m',
      :file_rolling_keep => 6,
      :file_rolling_size => 0,
      :file_rolling_age => 'weekly'
    }.freeze

    PROXY_SETTINGS = %i[ssl_ca_file ssl_certificate ssl_private_key foreman_url
                        foreman_ssl_ca foreman_ssl_cert foreman_ssl_key
                        log_file log_level ssl_disabled_ciphers].freeze
    PLUGIN_SETTINGS = %i[database core_url console_auth
                         execution_plan_cleaner_age].freeze

    def initialize(settings = {})
      super(DEFAULT_SETTINGS.merge(settings))
    end

    def self.instance
      SmartProxyDynflowCore::SETTINGS
    end

    def self.load_global_settings(path)
      if File.exist? File.join(path)
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
      settings = plugin.settings.to_h
      PROXY_SETTINGS.each do |key|
        SETTINGS[key] = Proxy::SETTINGS[key]
      end
      PLUGIN_SETTINGS.each do |key|
        SETTINGS[key] = settings[key] if settings.key?(key)
      end
      SETTINGS.plugins.values.each(&:load_settings_from_proxy)
      Settings.loaded!
    end

    def self.load_plugin_settings(path)
      settings = YAML.load_file(path)
      name = File.basename(path).gsub(/\.yml$/, '')
      if SETTINGS.plugins.key? name
        settings = SETTINGS.plugins[name].to_h.merge(settings || {})
      end
      SETTINGS.plugins[name] = OpenStruct.new settings
    end
  end
end

SmartProxyDynflowCore::SETTINGS = SmartProxyDynflowCore::Settings.new
