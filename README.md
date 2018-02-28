# smart_proxy_dynflow

A plugin into Foreman's Smart Proxy for running Dynflow actions on the Smart
Proxy.

## Split architecture

This repository contains two gems, `smart_proxy_dynflow` and
`smart_proxy_dynflow_core`. Their usage depends on the deployment type.

### smart_proxy_dynflow

Simple Smart Proxy plugin containing only an API to forward all requests coming
to `/dynflow` and all the endpoints underneath it to the
`smart_proxy_dynflow_core` service. This gem is only used when
`smart_proxy_dynflow_core` is deployed as a standalone service.

### smart_proxy_dynflow_core

This gem can be either use as a standalone service or run as a part of the Smart
Proxy process. Either way, this gem's purpose is to allow running Dynflow
actions and provide a simple API for triggering actions and querying information
about execution plans.

#### GET /console
Serves the Dynflow console for human friendly task inspection.

#### POST /tasks
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

#### POST /tasks/$TASK_ID/cancel
Tries to cancel a task.

```
curl -X POST localhost:8008/tasks/dd5a8306-0e52-4f68-9e83-c7f51c9e95c3/cancel -d '' 2>/dev/null | jq
{
  "task_id": "dd5a8306-0e52-4f68-9e83-c7f51c9e95c3",
  "canceled_steps_count": 1
}
```

#### GET /tasks/$TASK_ID/status
Allows querying the task by its id. Returns the full hash of the execution plan,
for details about output of this API call see `::Dynflow::ExecutionPlan#to_hash` and
`::Dynflow::Action#to_hash`.

#### GET /tasks/count

Returns the number of tasks. Optionally a state parameter can be provided to
obtain count of tasks in the specified state.

Example:
```
curl localhost:8008/tasks/count?state='stopped' 2>/dev/null | jq
{
  "count": 20,
  "state": "all"
}


curl localhost:8008/tasks/count?state='stopped' 2>/dev/null | jq
{
  "count": 1,
  "state": "stopped"
}

```

#### POST /tasks/$TASK_ID/done

Sends an `::ForemanTasksCore::Runner::ExternalEvent` event with full copy of the
parsed request's body to the task's step specified by `step_id`.

```
curl -X POST localhost:8008/tasks/dd5a8306-0e52-4f68-9e83-c7f51c9e95c3/done \
  -d '{"step_id": 1, "my_custom_data": "something"}'
```

## Handling of delegated actions
Foreman Tasks allows delegating action execution to the Smart Proxy. If a Smart
Proxy is specified, the action is delegated there, otherwise the action is run
on Foreman itself.

To allow this kind of behavior, certain parts of code need to be able to be used
both from Foreman core and `smart_proxy_dynflow_core`. This is usually done by
splitting the plugin's gem into `$PLUGIN` and `${PLUGIN}_core` gems. In general
the convention is to have Dynflow actions which can be used either on the
`smart_proxy_dynflow_core` or in Foreman core itself in the `*_core` gem and the
Foreman or Smart Proxy specific parts in the other gem.

From Foreman Tasks' standpoint, there is not difference between a local and
Proxy action. In the latter case instead of using the actual action, a
placeholder tracking the state of the remote action is used. This placeholder
usually triggers the remote action and suspends itself, waiting to receive a
callback from the Smart Proxy.

Similarly, when an action is delegated to the Smart Proxy, it is either executed
directly on the Smart Proxy or transparently delegated to the
`smart_proxy_dynflow_core` without a need for changing anything.

# Installation

**Clone smart-proxy**
```shell
git clone https://github.com/theforeman/smart-proxy
```
Configure smart proxy

**Clone all the repositories**
```shell
for repo in smart_proxy_dynflow smart_proxy_remote_execution_ssh; do
  git clone https://github.com/theforeman/$repo ${repo}
done
```


**In smart-proxy directory**
```shell
mkdir logs
```

Then add a line that contains `:log_file: logs/proxy.log` to file `config/settings.yml`

Configure `smart_proxy_dynflow` and `smart_proxy_remote_execution_ssh` as usually
```bash
cat > config/settings.d/dynflow.yml <<EOF
---
:enabled: true
EOF

cat > config/settings.d/remote_execution_ssh.yml <<EOF
---
:enabled: true
EOF
```


### All-in-one solution
Add all the gems to smart-proxy's bundler.d from local checkouts.
All comands are started from the smart-proxy's directory
```shell
cat <<-END > bundler.d/dynflow.local.rb
gem 'smart_proxy_dynflow', :path => '../smart_proxy_dynflow'
gem 'smart_proxy_dynflow_core', :path => '../smart_proxy_dynflow'
gem 'smart_proxy_remote_execution_ssh', :path => '../smart_proxy_remote_execution_ssh'
gem 'smart_proxy_remote_execution_ssh_core', :path => '../smart_proxy_remote_execution_ssh'
END
```


Install the gems and start smart proxy
```shell
bundle install
bundle exec bin/smart-proxy
```

Your smart proxy should now be usable


### The separate dynflow way
All comands are started from the smart-proxy's directory
```shell
cat <<-END > bundler.d/dynflow.local.rb
gem 'smart_proxy_dynflow', :path => '../smart_proxy_dynflow'
gem 'smart_proxy_remote_execution_ssh', :path => '../smart_proxy_remote_execution_ssh'
END
```

Update the smart proxy config/settings.d/dynflow.yml with the url of core if it's not running on localhost:8008, this is needed if TLS is involved.

Install smart proxy gems and start it
```shell
bundle install
bundle exec bin/smart-proxy
```

Following commands are started from smart_proxy_dynflow folder

Symlink smart_proxy_remote_execuiton_ssh's config from smart-proxy to smart_proxy_dynflow, note the name change
```shell
mkdir config/settings.d
ln -s ../../../smart-proxy/config/settings.d/remote_execution_ssh.yml config/settings.d/smart_proxy_remote_execution_ssh_core.yml
```

Copy smart_proxy_dynflow_core example config and optionally edit it manually
```shell
cp config/settings.yml{.example,}
```

Add the smart_proxy_remote_execution_ssh gem to `Gemfile.local.rb`
```shell
echo "gem 'foreman_remote_execution_core', :path => '../foreman_remote_execution'" >> Gemfile.local.rb
```

Install smart proxy dynflow core's gems and start it
```shell
bundle install
bundle exec bin/smart_proxy_dynflow_core
```

If you want to use TLS, configure certificates that smart proxy uses for communication with Foreman.




