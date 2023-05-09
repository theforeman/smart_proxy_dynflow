require 'rake'
require 'rake/testtask'
require 'rubocop/rake_task'

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
  Rake::Task['rubocop'].invoke if defined? RuboCop
  Rake::Task['test:core'].invoke
end

begin
  require 'ci/reporter/rake/test_unit'
rescue LoadError
  # test group not enabled
else
  namespace :jenkins do
    desc nil # No description means it's not listed in rake -T
    task unit: ['ci:setup:testunit', :test]
  end
end

if defined? RuboCop
  desc 'Run RuboCop on the lib directory'
  RuboCop::RakeTask.new(:rubocop) do |task|
    task.fail_on_error = true
  end
end
