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

  gem.files         = Dir['lib/smart_proxy_dynflow_core.rb', 'lib/smart_proxy_dynflow_core/**/*',
                          'LICENSE', 'Gemfile', 'smart_proxy_dynflow_core.gemspec']
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.license = 'GPL-3.0'

  gem.required_ruby_version = '~> 2.5'

  gem.add_development_dependency "bundler", ">= 1.7"
  gem.add_development_dependency('minitest')
  gem.add_development_dependency('mocha', '~> 1')
  gem.add_development_dependency('rack-test', '~> 0')
  gem.add_development_dependency "rake", "~> 10.0"
  gem.add_development_dependency('webmock', '~> 1')

  gem.add_runtime_dependency('dynflow', "~> 1.1")
  gem.add_runtime_dependency('foreman-tasks-core', '>= 0.3.3')
  gem.add_runtime_dependency('logging')
  gem.add_runtime_dependency('rack')
  gem.add_runtime_dependency('rest-client')
  gem.add_runtime_dependency('sd_notify', '~> 0.1')
  gem.add_runtime_dependency('sequel')
  gem.add_runtime_dependency('sinatra')
  gem.add_runtime_dependency('smart_proxy_dynflow')
  gem.add_runtime_dependency('sqlite3')
end
