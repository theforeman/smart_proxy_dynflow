require 'smart_proxy_dynflow_core/api'
require 'smart_proxy_dynflow_core/launcher'

SmartProxyDynflowCore::Settings.load_from_proxy(p)

map "/dynflow" do
  SmartProxyDynflowCore::Launcher.route_mapping(self)
end
