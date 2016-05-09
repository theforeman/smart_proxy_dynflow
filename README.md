Clone smart-proxy
```shell
git clone https://github.com/theforeman/smart-proxy
```
Configure smart proxy

Clone smart-proxy-dynflow api branch
```shell
for repo in smart_proxy_dynflow smart_proxy_remote_execution_ssh; do
  for branch in api core; do
    git clone https://github.com/adamruzicka/$repo ${repo}_$branch
    cd ${repo}_$branch
    git checkout $branch
    cd -
  done
done
```
Configure `smart_proxy_dynflow` and `smart_proxy_remote_execution_ssh` as usually

### All-in-one solution
Add all the gems to smart-proxy's bundler.d from local checkouts.
All comands are started from the smart-proxy's directory
```shell
cat <<-END > bundler.d/dynflow.local.rb
gem 'smart_proxy_dynflow', :path => '../smart_proxy_dynflow_api'
gem 'smart_proxy_dynflow_core', :path => '../smart_proxy_dynflow_core'
gem 'smart_proxy_remote_execution_ssh', :path => '../smart_proxy_remote_execution_ssh_api'
gem 'smart_proxy_remote_execution_ssh_core', :path => '../smart_proxy_remote_execution_ssh_core'
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
gem 'smart_proxy_dynflow', :path => '../smart_proxy_dynflow_api'
gem 'smart_proxy_remote_execution_ssh', :path => '../smart_proxy_remote_execution_ssh_api'
END
```

Symlink smart_proxy_remote_execuiton_ssh's config from smart-proxy to smart_proxy_dynflow_core
```shell
ln -s config/settings.d/remote_execution_ssh.yml ../smart-proxy-dynflow-core/config/settings.d/smart_proxy_remote_execution_ssh_core.yml
```

Copy smart_proxy_dynflow_core example config and optionally edit it manually
```shell
cp ../smart_proxy_dynflow_core/config/settings.yml{.example,}
```

Install smart proxy dynflow core's gems and start it
```shell
cd ../smart_proxy_dynflow_core
bundle install
budnle exec bin/smart_proxy_dynflow_core
```

Install smart proxy gems and start it
```shell
bundle install
bundle exec bin/smart-proxy
```




