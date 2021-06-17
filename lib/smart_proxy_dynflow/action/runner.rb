require 'smart_proxy_dynflow/action/shareable'
module Proxy::Dynflow
  module Action
    class Runner < Shareable
      include ::Dynflow::Action::Cancellable

      def run(event = nil)
        case event
        when nil
          init_run
        when Proxy::Dynflow::Runner::Update
          process_update(event)
        when Proxy::Dynflow::Runner::ExternalEvent
          process_external_event(event)
        when ::Dynflow::Action::Cancellable::Cancel
          kill_run
        else
          raise "Unexpected event #{event.inspect}"
        end
      rescue => e
        action_logger.error(e)
        process_update(Proxy::Dynflow::Runner::Update.encode_exception('Proxy error', e))
      end

      def finalize
        # To mark the task as a whole as failed
        error! 'Script execution failed' if on_proxy? && failed_run?
      end

      def rescue_strategy_for_self
        ::Dynflow::Action::Rescue::Fail
      end

      def initiate_runner
        raise NotImplementedError
      end

      def init_run
        output[:result] = []
        output[:runner_id] = runner_dispatcher.start(suspended_action, initiate_runner)
        suspend
      end

      def runner_dispatcher
        Proxy::Dynflow::Runner::Dispatcher.instance
      end

      def kill_run
        runner_dispatcher.kill(output[:runner_id])
        suspend
      end

      def finish_run(update)
        output[:exit_status] = update.exit_status
        output[:result] = stored_output_chunks.map { |c| c[:chunk] }.reduce(&:concat)
      end

      def process_external_event(event)
        runner_dispatcher.external_event(output[:runner_id], event)
        suspend
      end

      def process_update(update)
        output_chunk(update.continuous_output.raw_outputs) unless update.continuous_output.raw_outputs.empty?
        if update.exit_status
          finish_run(update)
        else
          suspend
        end
      end

      def failed_run?
        output[:exit_status] != 0
      end
    end
  end
end
