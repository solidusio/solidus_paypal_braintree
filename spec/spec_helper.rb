# frozen_string_literal: true

# Configure Rails Environment
ENV['RAILS_ENV'] ||= 'test'

# Run Coverage report
require 'solidus_dev_support/rspec/coverage'

require File.expand_path('dummy/config/environment.rb', __dir__)

# Requires factories and other useful helpers defined in spree_core.
require 'solidus_dev_support/rspec/feature_helper'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each { |f| require f }

# Requires factories defined in lib/solidus_paypal_braintree/factories.rb
require 'solidus_paypal_braintree/factories'

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
  config.use_transactional_fixtures = false
  config.raise_errors_for_deprecations!
  config.example_status_persistence_file_path = "./spec/examples.txt"
end
