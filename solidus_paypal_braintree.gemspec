# frozen_string_literal: true

require_relative 'lib/solidus_paypal_braintree/version'

Gem::Specification.new do |spec|
  spec.name = 'solidus_paypal_braintree'
  spec.version = SolidusPaypalBraintree::VERSION
  spec.authors = ['Stembolt']
  spec.email = 'braintree+gemfile@stembolt.com'

  spec.summary = 'Officially supported Paypal/Braintree extension'
  spec.description = 'Uses the javascript API for seamless braintree payments'
  spec.homepage = 'https://github.com/solidusio/solidus_paypal_braintree'
  spec.license = 'BSD-3-Clause'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/solidusio/solidus_paypal_braintree'
  spec.metadata['changelog_uri'] = 'https://github.com/solidusio/solidus_paypal_braintree/blob/master/CHANGELOG.md'

  spec.required_ruby_version = Gem::Requirement.new('>= 2.5', '< 4')

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  files = Dir.chdir(__dir__) { `git ls-files -z`.split("\x0") }

  spec.files = files.grep_v(%r{^(test|spec|features)/})
  spec.test_files = files.grep(%r{^(test|spec|features)/})
  spec.bindir = "exe"
  spec.executables = files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'solidus_braintree', '~> 2.0'
  spec.post_install_message = %q{
ACTION REQUIRED: This extension has been renamed to solidus_braintree.

To upgrade to the new name, follow the instructions here:
https://github.com/solidusio/solidus_braintree/wiki/Upgrading-from-SolidusPaypalBraintree-To-SolidusBraintree
  }

  spec.add_development_dependency 'rails-controller-testing'
  spec.add_development_dependency 'solidus_dev_support', '~> 2.5'
  spec.add_development_dependency 'vcr'
  spec.add_development_dependency 'webmock'
end
