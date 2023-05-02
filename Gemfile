source 'https://rubygems.org'

gemspec :name => 'smart_proxy_dynflow'

group :rubocop do
  gem 'rubocop', '~> 1.28.0'
  gem 'rubocop-minitest'
  gem 'rubocop-performance'
  gem 'rubocop-rake'
end

group :development do
  gem 'pry'
end

group :test do
  gem 'ci_reporter_test_unit'
  gem 'minitest'
  gem 'mocha'
  gem 'public_suffix'
  gem 'rack-test'
  gem 'rake'
  gem 'smart_proxy', :git => "https://github.com/theforeman/smart-proxy", :branch => "develop"
  gem 'webmock'
end

gem 'logging-journald', '~> 2.0', :platforms => [:ruby], :require => false
gem 'rack', '>= 1.1'
gem 'sinatra'

# load local gemfile
local_gemfile = File.join(File.dirname(__FILE__), 'Gemfile.local.rb')
self.instance_eval(Bundler.read_file(local_gemfile)) if File.exist?(local_gemfile)
