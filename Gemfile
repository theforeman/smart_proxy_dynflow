source 'https://rubygems.org'

gemspec :name => 'smart_proxy_dynflow_core'

group :development do
  gem 'smart_proxy', :git => "https://github.com/theforeman/smart-proxy", :branch => "develop"
  gem 'pry'
end

# load local gemfile
local_gemfile = File.join(File.dirname(__FILE__), 'Gemfile.local.rb')
self.instance_eval(Bundler.read_file(local_gemfile)) if File.exist?(local_gemfile)
