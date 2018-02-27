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
    requires :foreman_proxy, ">= 1.12.0"
    default_settings :core_url => 'http://localhost:8008'
    plugin :dynflow, Proxy::Dynflow::VERSION

    after_activation do
      begin
        require 'smart_proxy_dynflow_core'
      rescue LoadError # rubocop:disable Lint/HandleExceptions
        # Dynflow core is not available in the proxy, will be handled
        # by standalone Dynflow core
      end
    end
  end
end
