# smart_proxy_dynflow

A plugin into Foreman's Smart Proxy for running Dynflow actions on the Smart
Proxy.

## Public API

### GET /console
Serves the Dynflow console for human friendly task inspection.

### POST /tasks
**Deprecated** it still works, but you should use `POST /tasks/launch`

Used for triggering a task, expects `action_class` and `action_input` in the
request's body. The action specified by `action_class` is then planned with
`action_input` provided to the action's `#plan` method.

```
curl -X POST localhost:8008/tasks -d @- <<-END
   {
     "action_name": "ForemanRemoteExecutionCore::Actions::RunScript",
     "action_input": {
       "ssh_user": "root",
       "effective_user": "root",
       "effective_user_method": "sudo",
       "ssh_port": 22,
       "hostname": "172.17.0.3",
       "script": "true",
       "execution_timeout_interval": null,
       "connection_options": {
         "retry_interval": 15,
         "retry_count": 4,
         "timeout": 60
       },
       "proxy_url": "http://172.17.0.1:8000",
       "proxy_action_name": "ForemanRemoteExecutionCore::Actions::RunScript"
     }
   }
END
{
  "task_id": "6905065d-8808-4b02-9ed3-c1e27ce53de1"
}
```

Note: The example above requires `smart_proxy_remote_execution_ssh` Smart Proxy
plugin.

### POST /tasks/$TASK_ID/cancel
Tries to cancel a task.

```
curl -X POST localhost:8008/tasks/dd5a8306-0e52-4f68-9e83-c7f51c9e95c3/cancel -d '' 2>/dev/null
{
  "task_id": "dd5a8306-0e52-4f68-9e83-c7f51c9e95c3",
  "canceled_steps_count": 1
}
```

### GET /tasks/$TASK_ID/status
Allows querying the task by its id. Returns the full hash of the execution plan,
for details about output of this API call see `::Dynflow::ExecutionPlan#to_hash` and
`::Dynflow::Action#to_hash`.

### GET /tasks/count

Returns the number of tasks. Optionally a state parameter can be provided to
obtain count of tasks in the specified state.

Example:
```
curl localhost:8008/tasks/count?state='stopped' 2>/dev/null
{
  "count": 20,
  "state": "all"
}


curl localhost:8008/tasks/count?state='stopped' 2>/dev/null
{
  "count": 1,
  "state": "stopped"
}

```

### POST /tasks/$TASK_ID/done

Sends an `::ForemanTasksCore::Runner::ExternalEvent` event with full copy of the
parsed request's body to the task's step specified by `step_id`.

```
curl -X POST localhost:8008/tasks/dd5a8306-0e52-4f68-9e83-c7f51c9e95c3/done \
  -d '{"step_id": 1, "my_custom_data": "something"}'
```

### GET /tasks/operations

`smart_proxy_dynflow` allows registering `TaskLauncher`s into a registry. A
`TaskLauncher` is an abstraction which defines how to start a suite of execution
plans to accomplish a goal. It decouples the operation from the actual
implementation of the actions and their inputs.

This endpoint returns a list of registered `TaskLauncher`s from the registry.

### POST /tasks/launch

Launches a suite of execution plans to perform an operation. Parameter
`operation` specifies the operation and `input` is an input for task launcher
registered with the operation. `input` is specific to each operation.

More details can be found in [Task Launching docs](developer_docs/task_launching.asciidoc)

# Installation

**Clone smart-proxy**
```shell
git clone https://github.com/theforeman/smart-proxy
```
Configure smart proxy

**Clone all the repositories**
```shell
git clone https://github.com/theforeman/smart_proxy_dynflow
```


**In smart-proxy directory**
```shell
mkdir logs
```

Then add a line that contains `:log_file: logs/proxy.log` to file `config/settings.yml`

Configure `smart_proxy_dynflow` as usually
```bash
cat > config/settings.d/dynflow.yml <<EOF
---
:enabled: true
EOF
```


### All-in-one solution
Add all the gems to smart-proxy's `bundler.d` from local checkouts.
All commands are started from the smart-proxy's directory
```shell
cat <<-END > bundler.d/dynflow.local.rb
gem 'smart_proxy_dynflow', :path => '../smart_proxy_dynflow'
gem 'smart_proxy_dynflow_core', :path => '../smart_proxy_dynflow'
END
```


Install the gems and start smart proxy
```shell
bundle install
bundle exec bin/smart-proxy
```

Your smart proxy should now be usable
