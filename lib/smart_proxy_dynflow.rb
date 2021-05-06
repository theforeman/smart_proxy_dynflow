require 'dynflow'

require 'smart_proxy_dynflow/task_launcher_registry'
require 'smart_proxy_dynflow/middleware/keep_current_request_id'

require 'foreman_tasks_core'

require 'smart_proxy_dynflow/log'
require 'smart_proxy_dynflow/settings'
require 'smart_proxy_dynflow/core'
require 'smart_proxy_dynflow/callback'

require 'smart_proxy_dynflow/version'
require 'smart_proxy_dynflow/plugin'
require 'smart_proxy_dynflow/helpers'
require 'smart_proxy_dynflow/api'

module Proxy
  class Dynflow
    Core.after_initialize do |dynflow_core|
      ForemanTasksCore.dynflow_setup(dynflow_core.world)
    end
    Core.register_silencer_matchers ForemanTasksCore.silent_dead_letter_matchers
  end
end
