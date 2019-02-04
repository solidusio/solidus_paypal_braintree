# Run Coverage report
require 'simplecov'

SimpleCov.minimum_coverage(98)

SimpleCov.start do
  add_filter 'spec/dummy'
  add_group 'Controllers', 'app/controllers'
  add_group 'Helpers', 'app/helpers'
  add_group 'Mailers', 'app/mailers'
  add_group 'Models', 'app/models'
  add_group 'Views', 'app/views'
  add_group 'Libraries', 'lib'
end

# Configure Rails Environment
ENV['RAILS_ENV'] = 'test'

require File.expand_path('dummy/config/environment.rb', __dir__)

# Requires factories and other useful helpers defined in spree_core.
require "solidus_support/extension/feature_helper"
require 'spree/testing_support/controller_requests'

require 'byebug'
require 'vcr'
require 'webmock'
require 'selenium-webdriver'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each { |f| require f }

# Requires factories defined in lib/solidus_paypal_braintree/factories.rb
require 'solidus_paypal_braintree/factories'

ApplicationController.prepend_view_path "spec/fixtures/views"

FactoryBot.use_parent_strategy = false

VCR.configure do |c|
  c.cassette_library_dir = "spec/fixtures/cassettes"
  c.hook_into :webmock
  c.ignore_localhost = true
  c.configure_rspec_metadata!
  c.default_cassette_options = {
    match_requests_on: [:method, :uri, :body],
    allow_unused_http_interactions: false
  }
  c.allow_http_connections_when_no_cassette = false
end

require 'braintree'

Braintree::Configuration.logger = Rails.logger

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
  config.use_transactional_fixtures = false
  config.example_status_persistence_file_path = "tmp/failed_examples.txt"

  config.include SolidusPaypalBraintree::GatewayHelpers

  config.before(:each, type: :feature, js: true) do |ex|
    Capybara.current_driver = ex.metadata[:driver] || :selenium_chrome_headless
    page.driver.browser.manage.window.resize_to(1600, 1024)
  end
end
