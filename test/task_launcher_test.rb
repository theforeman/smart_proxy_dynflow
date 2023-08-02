# frozen_string_literal: true

require 'test_helper'
require 'smart_proxy_dynflow/action/batch'
require 'smart_proxy_dynflow/task_launcher'

module Proxy::Dynflow
  module TaskLauncher
    class TaskLauncherTest < Minitest::Spec
      include WithPerTestWorld

      class DummyDynflowAction < Dynflow::Action
        def plan(input)
          callback input
        end

        def callback(_input); end
      end

      describe TaskLauncher do
        let(:launcher) { launcher_class.new Proxy::Dynflow::Core.world, {} }
        let(:launcher_input) { { 'action_class' => DummyDynflowAction.to_s, 'action_input' => input } }
        let(:input) { { :do => 'something' } }
        let(:expected_result) { Dynflow::Utils::IndifferentHash.new(input.merge(:callback_host => {})) }

        describe TaskLauncher::Single do
          let(:launcher_class) { Single }

          it 'triggers an action' do
            DummyDynflowAction.any_instance.expects(:callback).with do |arg|
              Dynflow::Utils::IndifferentHash.new(arg) == expected_result
            end
            launcher.launch!(launcher_input)
          end

          it 'provides results' do
            plan = launcher.launch!(launcher_input).finished.value!
            _(launcher.results[:result]).must_equal 'success'
            _(plan.result).must_equal :success
          end
        end

        describe TaskLauncher::Batch do
          let(:launcher_class) { Batch }

          it 'triggers the actions' do
            DummyDynflowAction.any_instance.expects(:callback).with do |arg|
              arg == expected_result
            end.twice

            parent = launcher.launch!('foo' => launcher_input, 'bar' => launcher_input)
            wait_until(iterations: 15, interval: 1) do
              load_execution_plan(parent[:task_id]).state == :stopped
            end
            plan = load_execution_plan(parent[:task_id])
            _(plan.result).must_equal :success
            _(plan.sub_plans.count).must_equal 2
          end

          it 'provides results' do
            launcher.launch!('foo' => launcher_input, 'bar' => launcher_input)
            _(launcher.results.keys).must_equal [:parent]
            parent = launcher.results[:parent]
            _(parent[:result]).must_equal 'success'
          end
        end
      end
    end
  end
end
