class Proxy::Dynflow
  class Plugin < Proxy::Plugin
    http_rackup_path File.expand_path("http_config.ru", File.expand_path("../", __FILE__))
    https_rackup_path File.expand_path("http_config.ru", File.expand_path("../", __FILE__))

    settings_file "dynflow.yml"
    default_settings :console_auth => true
    default_settings :core_url => 'http://localhost:8001'
    plugin :dynflow, Proxy::Dynflow::VERSION
  end
end
