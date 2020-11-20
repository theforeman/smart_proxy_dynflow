source 'https://rubygems.org'

gemspec :name => 'smart_proxy_dynflow_core'

group :development do
  gem 'pry'
end

group :test do
  gem 'smart_proxy', :git => "https://github.com/theforeman/smart-proxy", :branch => "develop"
  gem 'smart_proxy_dynflow', :path => '.'

  gem 'public_suffix'
  gem 'rack-test'
  gem 'rubocop', '~> 0.52.1'
end

gem 'rack', '>= 1.1'
gem 'sinatra'

# load bundler.d
Dir["#{File.dirname(__FILE__)}/bundler.d/*.rb"].each do |bundle|
  self.instance_eval(Bundler.read_file(bundle))
end

# load local gemfile
local_gemfile = File.join(File.dirname(__FILE__), 'Gemfile.local.rb')
self.instance_eval(Bundler.read_file(local_gemfile)) if File.exist?(local_gemfile)
