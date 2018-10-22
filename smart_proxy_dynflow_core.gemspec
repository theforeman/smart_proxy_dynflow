# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'smart_proxy_dynflow_core/version'

Gem::Specification.new do |gem|
  gem.name          = "smart_proxy_dynflow_core"
  gem.version       = SmartProxyDynflowCore::VERSION
  gem.authors       = ['Ivan Nečas']
  gem.email         = ['inecas@redhat.com']
  gem.homepage      = "https://github.com/theforeman/smart_proxy_dynflow"
  gem.summary       = "Dynflow runtime for Foreman smart proxy"
  gem.description   = <<-EOS
    Use the Dynflow inside Foreman smart proxy
  EOS

  gem.executables   = ['smart_proxy_dynflow_core']
  gem.files         = Dir['lib/smart_proxy_dynflow_core.rb', 'config/settings.yml.example',
                          'lib/smart_proxy_dynflow_core/*', 'LICENSE', 'Gemfile',
                          'bin/smart_proxy_dynflow_core', 'deploy/*', 'smart_proxy_dynflow_core.gemspec']
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.license = 'GPL-3.0'

  gem.add_development_dependency "bundler", "~> 1.7"
  gem.add_development_dependency "rake", "~> 10.0"
  gem.add_development_dependency('minitest')
  gem.add_development_dependency('mocha', '~> 1')
  gem.add_development_dependency('webmock', '~> 1')
  gem.add_development_dependency('rack-test', '~> 0')
  gem.add_development_dependency('rubocop', '~> 0.52.1')

  gem.add_runtime_dependency('dynflow', "~> 1.1")
  gem.add_runtime_dependency('foreman-tasks-core', '>= 0.1.7')
  gem.add_runtime_dependency('sequel')
  gem.add_runtime_dependency('sqlite3')
  gem.add_runtime_dependency('sinatra')
  gem.add_runtime_dependency('rack')
  gem.add_runtime_dependency('rest-client')
end
