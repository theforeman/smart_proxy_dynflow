class Proxy::Dynflow
  class Plugin < Proxy::Plugin
    http_rackup_path File.expand_path("http_config.ru", File.expand_path("../", __FILE__))
    https_rackup_path File.expand_path("http_config.ru", File.expand_path("../", __FILE__))

    settings_file "dynflow.yml"
    default_settings :dynflow_identity_key => '~/.vagrant.d/insecure_private_key',
        :dynflow_user => 'root'
    plugin :dynflow, Proxy::Dynflow::VERSION
  end
end
