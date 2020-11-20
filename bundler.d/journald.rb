# Disable to avoid journald native gem in development setup.
# This group is only distributed in dynflow_core (not needed
# for smart-proxy plugins as logging is provided by smart-proxy).
group :journald do
  gem 'logging-journald', '~> 2.0', :platforms => [:ruby]
end
