require 'test_helper'

module Proxy
  module Dynflow
    class CallbackTest < MiniTest::Spec
      class DummyAction < ::Dynflow::Action
        include Callback::PlanHelper

        def plan
          plan_with_callback('callback' => { 'task_id' => '123', 'step_id' => 123 }, 'name' => 'World')
        end

        def run
          output[:result] = "Hello #{input[:name]}"
        end
      end

      describe Callback::Action do
        it 'sends the data to the Foreman using the callback API' do
          data = { :callback => { 'task_id' => '123', 'step_id' => 123 }, :data => { 'result' => 'Hello World' } }.to_json
          Callback::Request.any_instance.expects(:callback).with(data)
          triggered = WORLD.trigger(DummyAction)
          triggered.finished.wait
        end
      end
    end
  end
end
