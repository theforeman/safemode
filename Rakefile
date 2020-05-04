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

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "safemode"
  gem.homepage = "http://github.com/svenfuchs/safemode"
  gem.license = "MIT"
  gem.summary = %Q{A library for safe evaluation of Ruby code based on ParseTree/RubyParser and Ruby2Ruby}
  gem.description = %Q{A library for safe evaluation of Ruby code based on RubyParser and Ruby2Ruby. Provides Rails ActionView template handlers for ERB and Haml.}
  gem.email = "ohadlevy@gmail.com"
  gem.authors = [
    "Sven Fuchs",
    "Peter Cooper",
    "Matthias Viehweger",
    "Kingsley Hendrickse",
    "Ohad Levy",
    "Dmitri Dolguikh",
  ]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

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
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "safemode #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
