require 'proxy/log'
require 'proxy/pluggable'
require 'proxy/plugin'

class Proxy::Dynflow
  class Plugin < Proxy::Plugin
    rackup_path = File.expand_path('http_config.ru', __dir__)
    http_rackup_path rackup_path
    https_rackup_path rackup_path

    settings_file "dynflow.yml"
    requires :foreman_proxy, ">= 1.16.0"
    plugin :dynflow, Proxy::Dynflow::VERSION
  end
end
