require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = false
  t.warning = false
end

Rake::TestTask.new(:bench) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_benchmark.rb']
  t.verbose = false
  t.warning = false
end

# a long running brute force burn-in test
Rake::TestTask.new(:burn) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_brute.rb']
  t.verbose = false
  t.warning = false
end

task :test_all => [:test, :bench, :burn]

task default: :test
