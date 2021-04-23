# frozen_string_literal: true

$:.push File.expand_path('lib', __dir__)
require 'solidus_paypal_braintree/version'

Gem::Specification.new do |s|
  s.name        = 'solidus_paypal_braintree'
  s.version     = SolidusPaypalBraintree::VERSION
  s.summary     = 'Officially supported Paypal/Braintree extension'
  s.description = 'Uses the javascript API for seamless braintree payments'
  s.license     = 'BSD-3-Clause'

  s.author    = 'Stembolt'
  s.email     = 'braintree+gemfile@stembolt.com'
  s.homepage  = 'https://github.com/solidusio/solidus_paypal_braintree'

  s.required_ruby_version = '~> 2.4'

  s.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  s.test_files = Dir['spec/**/*']
  s.bindir = "exe"
  s.executables = s.files.grep(%r{^exe/}) { |f| File.basename(f) }
  s.require_paths = ["lib"]

  if s.respond_to?(:metadata)
    s.metadata["homepage_uri"] = s.homepage if s.homepage
    s.metadata["source_code_uri"] = s.homepage if s.homepage
  end

  s.add_dependency 'activemerchant', '~> 1.48'
  s.add_dependency 'braintree', '~> 2.65'
  s.add_dependency 'solidus_api', ['>= 2.0.0', '< 4']
  s.add_dependency 'solidus_core', ['>= 2.0.0', '< 4']
  s.add_dependency 'solidus_support', ['>= 0.8.1', '< 1']

  s.add_development_dependency 'selenium-webdriver'
  s.add_development_dependency 'solidus_dev_support'
  s.add_development_dependency 'vcr'
  s.add_development_dependency 'webmock'
end
