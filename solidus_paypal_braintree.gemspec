# frozen_string_literal: true

$:.push File.expand_path('lib', __dir__)
require 'solidus_paypal_braintree/version'

Gem::Specification.new do |spec|
  spec.name        = 'solidus_paypal_braintree'
  spec.version     = SolidusPaypalBraintree::VERSION
  spec.summary     = 'Officially supported Paypal/Braintree extension'
  spec.description = 'Uses the javascript API for seamless braintree payments'
  spec.license     = 'BSD-3-Clause'

  spec.author    = 'Stembolt'
  spec.email     = 'braintree+gemfile@stembolt.com'
  spec.homepage  = 'https://github.com/solidusio/solidus_paypal_braintree'

  spec.required_ruby_version = '>= 2.5'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  if spec.respond_to?(:metadata)
    spec.metadata["homepage_uri"] = spec.homepage if spec.homepage
    spec.metadata["source_code_uri"] = spec.homepage if spec.homepage
    spec.metadata["rubygems_mfa_required"] = 'true'
  end

  spec.add_dependency 'activemerchant', '~> 1.48'
  spec.add_dependency 'braintree', '~> 3.4'
  spec.add_dependency 'solidus_api', ['>= 2.4.0', '< 4']
  spec.add_dependency 'solidus_core', ['>= 2.4.0', '< 4']
  spec.add_dependency 'solidus_support', ['>= 0.8.1', '< 1']

  spec.add_development_dependency 'rails-controller-testing'
  spec.add_development_dependency 'solidus_dev_support', '~> 2.5'
  spec.add_development_dependency 'vcr'
  spec.add_development_dependency 'webmock'
end
