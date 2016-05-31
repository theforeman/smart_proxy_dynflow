require 'rake'
require 'rake/testtask'

desc 'Default: run unit tests.'
task :default => :test

namespace :test do

  desc 'Test Dynflow core plugin'
  Rake::TestTask.new(:core) do |t|
    ENV['DYNFLOW_DB_CONN_STRING'] = 'sqlite:/'
    t.libs << '.'
    t.libs << 'lib'
    t.libs << 'test/core_test'
    t.test_files = FileList['test/core_test/*_test.rb']
  end

  desc 'Test Dynflow api plugin'
  Rake::TestTask.new(:api) do |t|
    ENV['DYNFLOW_DB_CONN_STRING'] = 'sqlite:/'
    t.libs << '.'
    t.libs << 'lib'
    t.libs << 'test/api_test'
    t.test_files = FileList['test/api_test/*_test.rb']
  end
end

desc 'Test Dynflow plugin.'
task :test do
  Rake::Task['test:core'].invoke
  Rake::Task['test:api'].invoke
end

require 'rubocop/rake_task'

desc 'Run RuboCop on the lib directory'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.patterns = ['lib/**/*.rb', 'test/**/*.rb']
  task.fail_on_error = false
end
