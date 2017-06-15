# encoding: UTF-8

$:.push File.expand_path('../lib', __FILE__)
require 'solidus_paypal_braintree/version'

Gem::Specification.new do |s|
  s.name        = 'solidus_paypal_braintree'
  s.version     = SolidusPaypalBraintree::VERSION
  s.summary     = 'Officially supported Paypal/Braintree extension'
  s.description = 'Uses the javascript API for seamless braintree payments'
  s.license     = 'BSD-3-Clause'

  s.author    = 'Stembolt'
  s.email     = 'braintree+gemfile@stembolt.com'
  s.homepage  = 'https://stembolt.com'

  s.files = Dir["{app,config,db,lib}/**/*", 'LICENSE', 'Rakefile', 'README.md']
  s.test_files = Dir['test/**/*']

  s.add_dependency "solidus", ['>= 1.0', '< 3']
  s.add_dependency "solidus_support"
  s.add_dependency "braintree", '~> 2.65'

  s.add_development_dependency 'capybara'
  s.add_development_dependency 'poltergeist'
  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'sass-rails'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'factory_girl'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'rubocop', '>= 0.47'
  s.add_development_dependency 'rubocop-rspec'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'webmock'
  s.add_development_dependency 'vcr'
end
