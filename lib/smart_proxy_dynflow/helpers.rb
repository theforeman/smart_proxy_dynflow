module Proxy
  module Dynflow
    module Helpers
      def world
        Proxy::Dynflow::Core.world
      end

      def authorize_with_token(task_id:, clear: true)
        if request.env.key? 'HTTP_AUTHORIZATION'
          if defined?(::Proxy::Dynflow)
            auth = request.env['HTTP_AUTHORIZATION']
            basic_prefix = /\ABasic /
            if !auth.to_s.empty? && auth =~ basic_prefix &&
               Proxy::Dynflow::OtpManager.authenticate(auth.gsub(basic_prefix, ''),
                                                       expected_user: task_id, clear: clear)
              Log.instance.debug('authorized with token')
              return true
            end
          end
          halt 403, MultiJson.dump(:error => 'Invalid username or password supplied')
        end
        false
      end

      def trigger_task(*args)
        triggered = world.trigger(*args)
        { :task_id => triggered.id }
      end

      def cancel_task(task_id)
        execution_plan = world.persistence.load_execution_plan(task_id)
        cancel_events = execution_plan.cancel
        { :task_id => task_id, :canceled_steps_count => cancel_events.size }
      end

      def task_status(task_id)
        ep = world.persistence.load_execution_plan(task_id)
        actions = ep.actions.map do |action|
          hash = action.to_hash
          if action.is_a?(Proxy::Dynflow::Action::Runner)
            output = action.stored_output_chunks.map { |c| c[:chunk] }.reduce(&:concat)
            hash[:output][:result] = output
          end
          hash
        end
        ep.to_hash.merge(:actions => actions)
      rescue KeyError => _e
        status 404
        {}
      end

      def tasks_count(state)
        state ||= 'all'
        filter = state != 'all' ? { :filters => { :state => [state] } } : {}
        tasks = world.persistence.find_execution_plans(filter)
        { :count => tasks.count, :state => state }
      end

      def dispatch_external_event(task_id, params)
        world.event(task_id,
                    params['step_id'].to_i,
                    ::Proxy::Dynflow::Runner::ExternalEvent.new(params))
      end
    end
  end
end
