module SmartProxyDynflowCore
  module Helpers
    def world
      SmartProxyDynflowCore::Core.world
    end

    def authorize_with_token
      if request.env.key? 'HTTP_AUTHORIZATION'
        if defined?(::ForemanTasksCore)
          auth = request.env['HTTP_AUTHORIZATION']
          basic_prefix = /\ABasic /
          if !auth.to_s.empty? && auth =~ basic_prefix &&
              ForemanTasksCore::OtpManager.authenticate(auth.gsub(basic_prefix, ''))
            Log.instance.debug('authorized with token')
            return true
          end
        end
        halt 403, MultiJson.dump(:error => 'Invalid username or password supplied')
      end
      false
    end

    def authorize_with_ssl_client
      if %w(yes on 1).include? request.env['HTTPS'].to_s
        if request.env['SSL_CLIENT_CERT'].to_s.empty?
          Log.instance.error "No client SSL certificate supplied"
          halt 403, MultiJson.dump(:error => "No client SSL certificate supplied")
        else
          client_cert = OpenSSL::X509::Certificate.new(request.env['SSL_CLIENT_CERT'])
          unless SmartProxyDynflowCore::Core.instance.accepted_cert_serial == client_cert.serial
            Log.instance.error "SSL certificate with unexpected serial supplied"
            halt 403, MultiJson.dump(:error => "SSL certificate with unexpected serial supplied")
          end
        end
      else
        Log.instance.debug 'require_ssl_client_verification: skipping, non-HTTPS request'
      end
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
