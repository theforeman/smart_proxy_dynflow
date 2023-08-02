# frozen_string_literal: true

module Proxy::Dynflow
  module Runner
    # Runner is an object that is able to initiate some action and
    # provide update data on refresh call.
    class Base
      attr_reader :id
      attr_writer :logger

      def initialize(*_args, suspended_action: nil, id: nil)
        @suspended_action = suspended_action
        @id = id || SecureRandom.uuid
        initialize_continuous_outputs
      end

      def logger
        @logger ||= Logger.new($stderr)
      end

      def run_refresh
        logger.debug('refreshing runner')
        refresh
        generate_updates
      end

      # by default, external event just causes the refresh to be triggered: this allows the descendants
      # of the Base to add custom logic to process the external events.
      # Similarly as `run_refresh`, it's expected to return updates to be dispatched.
      def external_event(_event)
        run_refresh
      end

      def start
        raise NotImplementedError
      end

      def refresh
        raise NotImplementedError
      end

      def kill
        # Override when you can kill the runner in the middle
      end

      def close
        # if cleanup is needed
      end

      def timeout
        # Override when timeouts and regular kills should be handled differently
        publish_data('Timeout for execution passed, trying to stop the job', 'debug')
        kill
      end

      def timeout_interval
        # A number of seconds after which the runner should receive a #timeout
        #   or nil for no timeout
      end

      def publish_data(data, type)
        @continuous_output.add_output(data, type)
      end

      def publish_exception(context, exception, fatal = true)
        logger.error("#{context} - #{exception.class} #{exception.message}:\n" + \
                     exception.backtrace.join("\n"))
        dispatch_exception context, exception
        publish_exit_status('EXCEPTION') if fatal
      end

      def publish_exit_status(status)
        @exit_status = status
      end

      def dispatch_exception(context, exception)
        @continuous_output.add_exception(context, exception)
      end

      def generate_updates
        return no_update if @continuous_output.empty? && @exit_status.nil?

        new_data = @continuous_output
        @continuous_output = Proxy::Dynflow::ContinuousOutput.new
        new_update(new_data, @exit_status)
      end

      def no_update
        {}
      end

      def new_update(data, exit_status)
        { @suspended_action => Runner::Update.new(data, exit_status) }
      end

      def initialize_continuous_outputs
        @continuous_output = ::Proxy::Dynflow::ContinuousOutput.new
      end

      def run_refresh_output
        logger.debug('refreshing runner on demand')
        refresh
        generate_updates
      end
    end
  end
end
