map "/dynflow" do
  map '/console' do
    run Proxy::Dynflow.instance.web_console
  end

  map '/'do
    run Proxy::Dynflow::Api
  end
end
