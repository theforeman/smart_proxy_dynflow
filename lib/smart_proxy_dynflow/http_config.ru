require 'smart_proxy_dynflow/api'

map "/dynflow" do
  map '/'do
    run Proxy::Dynflow::Api
  end
end
