require 'smart_proxy_dynflow_core/api'

SmartProxyDynflowCore::Settings.load_from_proxy(p)

map "/dynflow" do
  map '/console' do
    run SmartProxyDynflowCore::Core.web_console
  end

  map '/' do
    run SmartProxyDynflowCore::Api
  end
end
