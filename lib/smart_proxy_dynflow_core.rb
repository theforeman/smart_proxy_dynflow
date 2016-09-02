require 'dynflow'
require 'foreman_tasks_core'
require 'smart_proxy_dynflow_core/log'
require 'smart_proxy_dynflow_core/settings'
require 'smart_proxy_dynflow_core/core'
require 'smart_proxy_dynflow_core/helpers'
require 'smart_proxy_dynflow_core/callback'
require 'smart_proxy_dynflow_core/api'

SmartProxyDynflowCore::Core.after_initialize do |dynflow_core|
  ForemanTasksCore.dynflow_setup(dynflow_core.world)
end
