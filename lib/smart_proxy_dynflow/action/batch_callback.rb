module Proxy::Dynflow::Action
  class BatchCallback < ::Dynflow::Action
    def plan(input_hash, results)
      callbacks = input_hash.reduce({}) do |acc, (key, value)|
        acc.merge(key => value['action_input']['callback'])
      end
      plan_self :targets => callbacks, :results => results
    end

    def run
      payload = format_payload(input['targets'], input['results'])
      Proxy::Dynflow::Callback::Request.new.callback({ :callbacks => payload }.to_json)
    end

    private

    def format_payload(input_hash, results)
      input_hash.map do |task_id, callback|
        { :callback => callback, :data => results[task_id] }
      end
    end
  end
end
