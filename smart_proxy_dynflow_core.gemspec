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

  gem.add_development_dependency "bundler", ">= 1.7"
  gem.add_runtime_dependency('smart_proxy_dynflow', '~> 0.5')
end
