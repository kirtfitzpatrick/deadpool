require 'bundler/gem_tasks'
require 'rake/clean'
require 'rake/testtask'
require 'bump/tasks'
require 'github_changelog_generator/task'


GitHubChangelogGenerator::RakeTask.new :changelog do |config|
  config.user = 'kirtfitzpatrick'
  config.project = 'deadpool'
  config.since_tag = 'v1.0.0'
end

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task :default => :test
