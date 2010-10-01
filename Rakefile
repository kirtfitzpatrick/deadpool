require 'rake/clean'
require 'rake/testtask'

task :default => [:test]

task :test do
  Rake::TestTask.new do |t|
    t.libs << "test"
    t.pattern = 'test/{unit}/**/*_test.rb'
    t.verbose = true
  end
end

require 'rcov/rcovtask'
Rcov::RcovTask.new do |t|
  t.libs << "test"
  t.pattern = 'test/{unit}/**/*_test.rb'
  t.rcov_opts << "-x /Users"
  t.verbose = true
end
