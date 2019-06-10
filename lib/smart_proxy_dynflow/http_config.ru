# Internal core will be used if external core is either disabled or unset
# and the core gem can be loaded
internal_core = unless Proxy::Dynflow::Plugin.settings.external_core
                  begin
                    require 'smart_proxy_dynflow_core'
                    true
                  rescue LoadError
                    false
                  end
                end

if internal_core
  require 'smart_proxy_dynflow_core/api'
  require 'smart_proxy_dynflow_core/launcher'

  SmartProxyDynflowCore::Settings.load_from_proxy(p)

  map "/dynflow" do
    SmartProxyDynflowCore::Launcher.route_mapping(self)
  end
else
  require 'smart_proxy_dynflow/api'

  map "/dynflow" do
    map '/' do
      run Proxy::Dynflow::Api
    end
  end
end
