# frozen_string_literal: true

require 'smart_proxy_dynflow/api'

map "/dynflow" do
  map '/console' do
    run Proxy::Dynflow::Core.web_console
  end

  map '/' do
    run Proxy::Dynflow::Api
  end
end
