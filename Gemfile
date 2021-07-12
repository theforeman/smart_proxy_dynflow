source 'https://rubygems.org'

group :development do
  gem 'pry'
end

group :test do
  gem 'smart_proxy', :git => "https://github.com/theforeman/smart-proxy", :branch => "develop"
  gem 'smart_proxy_dynflow', :path => '.'

  gem 'minitest'
  gem 'mocha'
  gem 'public_suffix'
  gem 'rack-test'
  gem 'rake'
  gem 'rubocop', '~> 0.52.1'
end

gem 'logging-journald', '~> 2.0', :platforms => [:ruby], :require => false
gem 'rack', '>= 1.1'
gem 'sinatra'

# load local gemfile
local_gemfile = File.join(File.dirname(__FILE__), 'Gemfile.local.rb')
self.instance_eval(Bundler.read_file(local_gemfile)) if File.exist?(local_gemfile)
