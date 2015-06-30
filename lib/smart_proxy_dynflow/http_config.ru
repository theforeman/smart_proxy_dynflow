map "/dynflow" do
  run Proxy::Dynflow.instance.web_console
end
