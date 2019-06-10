require 'proxy/log'
require 'proxy/pluggable'
require 'proxy/plugin'

class Proxy::Dynflow
  class Plugin < Proxy::Plugin
    rackup_path = File.expand_path('http_config.ru', File.expand_path("../", __FILE__))
    http_rackup_path rackup_path
    https_rackup_path rackup_path

    settings_file "dynflow.yml"
    requires :foreman_proxy, ">= 1.12.0"
    default_settings :core_url => 'http://localhost:8008'
    plugin :dynflow, Proxy::Dynflow::VERSION

    after_activation do
      # Ensure the core gem is loaded, if configure NOT to use the external core
      require 'smart_proxy_dynflow_core' if Proxy::Dynflow::Plugin.settings.external_core == false
    end
  end
end
