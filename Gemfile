# frozen_string_literal: true

source 'http://rubygems.org'

gem 'ruby2ruby', '>= 2.4.0'
gem 'ruby_parser', '>= 3.10.1'
gem 'sexp_processor', '>= 4.10.0'

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.
group :development do
  gem 'jeweler'
  gem 'rake'
  gem 'rdoc', '~> 3.12'
  # rubocop:disable Style/SymbolArray,Metrics/LineLength
  gem 'simplecov', platforms: [:ruby_20, :ruby_21, :ruby_22, :ruby_23, :ruby_24, :ruby_25, :jruby]
  gem 'test-unit', platforms: [:ruby_20, :ruby_21, :ruby_22, :ruby_23, :ruby_24, :ruby_25, :jruby]
  # rubocop:enable Style/SymbolArray,Metrics/LineLength
end
