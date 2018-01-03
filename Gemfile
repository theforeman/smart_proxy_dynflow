source 'https://rubygems.org'

gemspec :name => 'smart_proxy_dynflow_core'

group :development do
  gem 'pry'
end

group :test do
  gem 'smart_proxy_dynflow', :path => '.'
  gem 'smart_proxy', :git => "https://github.com/theforeman/smart-proxy", :branch => "develop"

  if RUBY_VERSION < '2.1'
    gem 'public_suffix', '< 3'
  else
    gem 'public_suffix'
  end

  if RUBY_VERSION < '2.2'
    gem 'rack-test', '< 0.8'
  else
    gem 'rack-test'
  end
end

if RUBY_VERSION < '2.2'
  gem 'sinatra', '< 2'
  gem 'rack', '>= 1.1', '< 2.0.0'
else
  gem 'sinatra'
  gem 'rack', '>= 1.1'
end

# load bundler.d
Dir["#{File.dirname(__FILE__)}/bundler.d/*.rb"].each do |bundle|
  self.instance_eval(Bundler.read_file(bundle))
end

# load local gemfile
local_gemfile = File.join(File.dirname(__FILE__), 'Gemfile.local.rb')
self.instance_eval(Bundler.read_file(local_gemfile)) if File.exist?(local_gemfile)
