raise LoadError, 'Ruby >= 2.1 is required' unless RUBY_VERSION >= '2.1'

require 'dynflow'
require 'smart_proxy_dynflow_core/task_launcher_registry'
require 'foreman_tasks_core'
require 'smart_proxy_dynflow_core/log'
require 'smart_proxy_dynflow_core/settings'
require 'smart_proxy_dynflow_core/core'
require 'smart_proxy_dynflow_core/helpers'
require 'smart_proxy_dynflow_core/callback'
require 'smart_proxy_dynflow_core/api'

module SmartProxyDynflowCore
  Core.after_initialize do |dynflow_core|
    ForemanTasksCore.dynflow_setup(dynflow_core.world)
  end
  Core.register_silencer_matchers ForemanTasksCore.silent_dead_letter_matchers
end
