require 'test_helper'
require 'json'
require 'smart_proxy_dynflow_core/api.rb'
require 'foreman_tasks_core/runner/update'

module SmartProxyDynflowCore
  class ApiTest < Minitest::Spec
    include Rack::Test::Methods

    def app
      SmartProxyDynflowCore::Api.new
    end

    class DummyAction < ::Dynflow::Action
      def run
        output[:result] = "Hello #{input[:name]}"
      end
    end

    class StuckAction < ::Dynflow::Action
      include ::Dynflow::Action::Cancellable

      def run(event = nil)
        if event.nil?
          suspend
        end
      end
    end

    def wait_until(iterations = 10, interval = 0.2)
      iterations.times do
        break if yield
        sleep interval
      end
    end

    before do
      header 'Content-Type', 'application/json'
    end

    let(:hostname) { 'somehost.somedomain.org:9000' }
    let(:forwarded) { "forwarded.#{hostname}" }
    let(:request_headers) { { 'HTTP_X_FORWARDED_FOR' => forwarded, 'HTTP_HOST' => hostname } }

    describe 'POST /tasks' do
      it 'triggers the action' do
        post "/tasks",
             { 'action_name' => 'SmartProxyDynflowCore::ApiTest::DummyAction',
               'action_input' => { 'name' => 'World' } }.to_json,
             request_headers

        response = JSON.load(last_response.body)
        wait_until { WORLD.persistence.load_execution_plan(response['task_id']).state == :stopped }
        execution_plan = WORLD.persistence.load_execution_plan(response['task_id'])
        execution_plan.state.must_equal :stopped
        execution_plan.result.must_equal :success
        execution_plan.entry_action.input[:callback_host].must_equal forwarded
      end

      it 'fallbacks to HTTP_HOST if X-Forwarded-For is not set as callback host' do
        post "/tasks",
             { 'action_name' => 'SmartProxyDynflowCore::ApiTest::DummyAction',
               'action_input' => { 'name' => 'World' } }.to_json,
             request_headers.reject { |key, _| key == 'HTTP_X_FORWARDED_FOR' }
        response = JSON.load(last_response.body)
        wait_until { WORLD.persistence.load_execution_plan(response['task_id']).state == :stopped }
        execution_plan = WORLD.persistence.load_execution_plan(response['task_id'])
        execution_plan.state.must_equal :stopped
        execution_plan.result.must_equal :success
        execution_plan.entry_action.input[:callback_host].must_equal hostname
      end
    end

    describe 'POST /tasks/:task_id/cancel' do
      it 'cancels the action' do
        triggered = WORLD.trigger(StuckAction)
        wait_until { WORLD.persistence.load_execution_plan(triggered.id).state == :running }

        post "/tasks/#{triggered.id}/cancel"
        triggered.finished.wait(5)

        execution_plan = WORLD.persistence.load_execution_plan(triggered.id)
        execution_plan.state.must_equal :stopped
        execution_plan.result.must_equal :success
      end
    end

    describe 'POST /tasks/:task_id/done' do
      it 'passes the external event' do
        task_id = '12345'
        step_id = 15
        params = { 'step_id' => step_id }
        WORLD.expects(:event).with do |task, step, update|
          task_id == task &&
            step_id == step &&
            update.data == params
        end
        post "/tasks/#{task_id}/done", params.to_json, request_headers
      end
    end

    describe 'GET /tasks/count' do
      it 'counts the actions in state' do
        get "/tasks/count", { :state => 'stopped' }, request_headers
        response = JSON.load(last_response.body)
        old_count = response['count']

        triggered = WORLD.trigger(DummyAction)
        wait_until { WORLD.persistence.load_execution_plan(triggered.id).state == :stopped }

        get "/tasks/count", :state => 'stopped'
        response = JSON.load(last_response.body)
        response['count'].must_equal old_count + 1
      end
    end
  end
end
