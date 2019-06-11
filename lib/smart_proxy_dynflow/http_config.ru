# Internal core will be used if external core is either disabled or unset
# and the core gem can be loaded

if !::Proxy::Dynflow::Plugin.settings.external_core && Proxy::Dynflow::Plugin.internal_core_available?
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
