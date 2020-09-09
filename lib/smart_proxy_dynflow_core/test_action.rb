#
# Test dynflow action. Does nothing. To call it:
#
# curl localhost:8008/tasks/ -X POST -d '{ "action_name": "SmartProxyDynflowCore::TestAction", "action_input": {} }'
#
# To raise a dummy exception:
#
# curl localhost:8008/tasks/ -X POST -d '{ "action_name": "SmartProxyDynflowCore::TestAction", "action_input": {"exception": "true"} }'
#
module SmartProxyDynflowCore
  class TestAction < ::Dynflow::Action
    def run
      raise "test exception" if input["exception"]
    end
  end
end
