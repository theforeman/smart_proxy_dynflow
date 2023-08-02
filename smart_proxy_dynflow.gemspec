# frozen_string_literal: true
lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'smart_proxy_dynflow/version'

Gem::Specification.new do |gem|
  gem.name          = "smart_proxy_dynflow"
  gem.version       = Proxy::Dynflow::VERSION
  gem.authors       = ['Ivan Nečas']
  gem.email         = ['inecas@redhat.com']
  gem.homepage      = "https://github.com/theforeman/smart_proxy_dynflow"
  gem.summary       = "Dynflow runtime for Foreman smart proxy"
  gem.description   = <<-EOS
    Use the Dynflow inside Foreman smart proxy
  EOS

  gem.files         = Dir['lib/smart_proxy_dynflow.rb', '{bundler.d,lib/smart_proxy_dynflow,settings.d}/**/*',
                          'LICENSE', 'Gemfile']
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.license = 'GPL-3.0'

  gem.required_ruby_version = '>= 2.7', '< 4'

  gem.add_runtime_dependency('dynflow', "~> 1.6")
  gem.add_runtime_dependency('rest-client', '~> 2.0')
  gem.add_runtime_dependency('sqlite3', '~> 1.0')

  gem.metadata['rubygems_mfa_required'] = 'true'
end
