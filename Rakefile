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

if RUBY_VERSION >= "1.9"
  desc "Generate coverage report for tests"
  task :coverage do |cov|
    ENV['COVERAGE'] = 'true'
    Rake::Task[:test].execute
  end
else
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
    test.rcov_opts << '--exclude "gems/*"'
  end
end

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "safemode #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

Rake::TestTask.new(:generate) do
  $:.unshift File.join(File.dirname(__FILE__), "lib")
  require "safemode"
  default_methods = Safemode.class_variable_get("@@default_methods")
  dangerous_methods = %w(
  !~
  =~
  class
  class_eval
  clone
  deep_clone
  deep_dup
  define_singleton_method
  display
  dup
  enum_for
  extend
  gem
  __id__
  inspect
  instance_eval
  instance_exec
  instance_of?
  instance_variable_defined?
  instance_variable_get
  instance_variables
  instance_variable_set
  itself
  marshal_dump
  marshal_load
  method
  methods
  object_id
  pathmap
  pathmap_explode
  pathmap_partial
  pathmap_replace
  pp
  prepend
  private_methods
  protected_methods
  public_method
  public_methods
  public_send
  remove_instance_variable
  __send__
  send
  silently
  singleton_class
  singleton_method
  singleton_method_added
  singleton_methods
  taint
  tainted?
  to_enum
  trust
  try
  untaint
  untrust
  untrusted?
  with_options
  )
  common = {}
  additional_methods = {}
  additional_methods["String"] = %w(
  iseuc
  isjis
  issjis
  isutf8
  kconv
  toeuc
  tojis
  tolocale
  tosjis
  toutf16
  toutf32
  toutf8
  )

  objects = [
    Array.new,
    1.0,
    Hash.new,
    (1..2),
    String.new,
    :symbol,
    Time.new,
    Date.new,
    DateTime.new,
    nil,
    false,
    true]
  if RUBY_VERSION >= '2.4.0'
    # append Bignum and Fixnum
    objects << (2 ** 62)
    objects << 1
  else
    # append just Integer
    objects << 1
  end
  objects.each do |object|
    puts "  '#{object.class}' => %w("
    object.methods.sort.each do |method|
      next if default_methods.include?(method.to_s) || dangerous_methods.include?(method.to_s)
      common[method] = 0 unless common[method]
      common[method] += 1
      puts "    #{method}"
    end
    if additional_methods.has_key?(object.class.to_s)
      puts "    # methods from other classes named as #{object.class}"
      additional_methods[object.class.to_s].sort.each do |method|
        puts "    #{method}"
      end
    end
    puts "  ),"
    common.each_pair do |method, count|
      puts " # common method: #{method}" if count >= objects.count
    end
  end
end

task :default => :test
