require 'smart_proxy_dynflow_core/api'

map "/dynflow" do
  map '/console' do
    run SmartProxyDynflowCore::Core.web_console
  end

  map '/' do
    run SmartProxyDynflowCore::Api
  end
end
