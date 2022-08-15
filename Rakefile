# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

# optional libraries
%w[ redgreen ].each do |lib|
  begin
    require lib
  rescue LoadError
  end
end
require 'rake'

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

desc "Generate coverage report for tests"
task :coverage do |cov|
  ENV['COVERAGE'] = 'true'
  Rake::Task[:test].execute
end

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = Gem::Specification.find_by_name('safemode').version

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "safemode #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
