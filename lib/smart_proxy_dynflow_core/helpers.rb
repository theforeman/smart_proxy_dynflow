module SmartProxyDynflowCore
  module Helpers
    def world
      SmartProxyDynflowCore::Core.world
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
      ep.to_hash.merge(:actions => ep.actions.map(&:to_hash))
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

    def complete_task(task_id, params)
      world.event(task_id,
                  params['step_id'].to_i,
                  ::ForemanTasksCore::Runner::ExternalEvent.new(params))
    end
  end
end
