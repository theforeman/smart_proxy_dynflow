require 'proxy/log'
require 'proxy/pluggable'
require 'proxy/plugin'

class Proxy::Dynflow
  class Plugin < Proxy::Plugin
    rackup_path = begin
      require 'smart_proxy_dynflow_core'
      'http_config_with_executor.ru'
    rescue LoadError
      'http_config.ru'
    end
    http_rackup_path File.expand_path(rackup_path, File.expand_path("../", __FILE__))
    https_rackup_path File.expand_path(rackup_path, File.expand_path("../", __FILE__))

    settings_file "dynflow.yml"
    default_settings :console_auth => true
    default_settings :core_url => 'http://localhost:8008'
    plugin :dynflow, Proxy::Dynflow::VERSION
  end
end
