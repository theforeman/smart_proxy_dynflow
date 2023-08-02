# frozen_string_literal: true
require 'rake'
require 'rake/testtask'

begin
  require 'rubocop/rake_task'
rescue LoadError
  # No Rubocop
else
  RuboCop::RakeTask.new(:rubocop) do |task|
    task.fail_on_error = true
    task.formatters << 'github' if ENV['GITHUB_ACTIONS'] == 'true'
  end
end

desc 'Default: run unit tests.'
task :default => :test

namespace :test do
  desc 'Test Dynflow core plugin'
  Rake::TestTask.new(:core) do |t|
    ENV['DYNFLOW_DB_CONN_STRING'] = 'sqlite:/'
    t.libs << '.'
    t.libs << 'lib'
    t.libs << 'test'
    t.test_files = FileList['test/*_test.rb']
  end
end

desc 'Test Dynflow plugin.'
task :test do
  Rake::Task['rubocop'].invoke if Rake::Task.task_defined?(:rubocop)
  Rake::Task['test:core'].invoke
end
