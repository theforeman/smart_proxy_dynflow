# Whatever is here is just a compatibility layer
# Once all the _core have been migrated, this can be dropped.

require 'smart_proxy_dynflow'

# REX core explicitly requires this file, otherwise we could use the trick we
# use with callback
require 'smart_proxy_dynflow_core/task_launcher_registry'

module SmartProxyDynflowCore
  Callback = Proxy::Dynflow::Callback
  Log = Proxy::Dynflow::Log
end
