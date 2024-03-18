# frozen_string_literal: true

require 'date'

Gem::Specification.new do |s|
  s.name = "safemode".freeze
  s.version = "1.5.0"
  s.date = Date.today

  s.summary = "A library for safe evaluation of Ruby code based on ParseTree/RubyParser and Ruby2Ruby"
  s.description = "A library for safe evaluation of Ruby code based on RubyParser and Ruby2Ruby. Provides Rails ActionView template handlers for ERB and Haml."
  s.homepage = "https://github.com/svenfuchs/safemode"
  s.licenses = ["MIT"]

  s.authors = [
    "Sven Fuchs",
    "Peter Cooper",
    "Matthias Viehweger",
    "Kingsley Hendrickse",
    "Ohad Levy",
    "Dmitri Dolguikh",
  ]

  s.extra_rdoc_files = [
    "LICENSE",
    "README.markdown"
  ]
  s.files = [
    "Gemfile",
    "LICENSE",
    "README.markdown",
    "Rakefile",
    "demo.rb",
    "init.rb",
    "lib/action_view/template_handlers/safe_erb.rb",
    "lib/action_view/template_handlers/safe_haml.rb",
    "lib/action_view/template_handlers/safemode_handler.rb",
    "lib/haml/safemode.rb",
    "lib/safemode.rb",
    "lib/safemode/blankslate.rb",
    "lib/safemode/core_ext.rb",
    "lib/safemode/core_jails.rb",
    "lib/safemode/exceptions.rb",
    "lib/safemode/jail.rb",
    "lib/safemode/parser.rb",
    "lib/safemode/scope.rb",
    "safemode.gemspec",
    "test/test_erb_eval.rb",
    "test/test_helper.rb",
    "test/test_jail.rb",
    "test/test_safemode_eval.rb",
    "test/test_safemode_parser.rb"
  ]

  s.required_ruby_version = ">= 2.7", "< 3.2"

  s.add_runtime_dependency "ruby2ruby", ">= 2.4.0"
  s.add_runtime_dependency "ruby_parser", ">= 3.10.1"
  s.add_runtime_dependency "sexp_processor", ">= 4.10.0"

  s.add_development_dependency "rake"
  s.add_development_dependency "rdoc"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "test-unit"
end
