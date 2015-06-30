# Smart-proxy Dynflow plugin 

This a plugin for foreman smart-proxy allowing using dynflow for the
[remote execution](http://theforeman.github.io/foreman_remote_execution/)

## Installation

Add this line to your smart proxy bundler.d/dynflow.rb gemfile:

```ruby
gem 'smart_proxy_dynflow
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install smart_proxy_dynflow

## Usage

To configure this plugin you can use template from settings.d/dynflow.yml.example.
You must place dynflow.yml config file (based on this template) to your 
smart-proxy config/settings.d/ directory.
