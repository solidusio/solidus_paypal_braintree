# Run Coverage report
require 'simplecov'

if ENV["CI"]
  SimpleCov.minimum_coverage(100)
end

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

require File.expand_path('../dummy/config/environment.rb', __FILE__)

require 'rspec/rails'
require 'vcr'
require 'webmock'
require 'database_cleaner'
require 'ffaker'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each { |f| require f }

# Requires factories and other useful helpers defined in spree_core.
require 'spree/testing_support/authorization_helpers'
require 'spree/testing_support/capybara_ext'
require 'spree/testing_support/controller_requests'
require 'spree/testing_support/factories'
require 'spree/testing_support/url_helpers'

# Requires factories defined in lib/solidus_paypal_braintree/factories.rb
require 'solidus_paypal_braintree/factories'

# Requires poltergeist for feature specs
require 'capybara/poltergeist'
Capybara.register_driver :poltergeist do |app|
  # Paypal requires TLS v1.2 for ssl connections
  Capybara::Poltergeist::Driver.new(app, {
    phantomjs_logger: Rails.logger,
    phantomjs_options: ['--ssl-protocol=any'],
    timeout: 2.minutes
  })
end
Capybara.register_driver :chrome do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome)
end

require 'capybara-screenshot/rspec'

VCR.configure do |c|
  c.cassette_library_dir = "spec/fixtures/cassettes"
  c.hook_into :webmock
  c.ignore_localhost = true
  c.configure_rspec_metadata!
  c.default_cassette_options = { match_requests_on: [:method, :uri, :body], allow_unused_http_interactions: false }
  c.allow_http_connections_when_no_cassette = false
end

require 'braintree'

Braintree::Configuration.logger = Rails.logger

module BraintreeHelpers
  def new_gateway(opts = {})
    SolidusPaypalBraintree::Gateway.new({
      name: "Braintree",
      preferences: {
        environment: 'sandbox',
        public_key:  'mwjkkxwcp32ckhnf',
        private_key: 'a9298f43b30c699db3072cc4a00f7f49',
        merchant_id: '7rdg92j7bm7fk5h3',
        merchant_currency_map: {
          'EUR' => 'stembolt_EUR'
        },
        paypal_payee_email_map: {
          'EUR' => 'paypal+europe@example.com'
        }
      }
    }.merge(opts))
  end

  def create_gateway(opts = {})
    new_gateway(opts).tap(&:save!)
  end

  # Using order.update! was deprecated in Solidus v2.3
  def recalculate(order)
    order.respond_to?(:recalculate) ? order.recalculate : order.update!
  end
end

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
  config.mock_with :rspec

  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  config.use_transactional_fixtures = false

  config.order = :random
  config.example_status_persistence_file_path = "tmp/failed_examples.txt"

  config.fail_fast = ENV['FAIL_FAST'] || false

  config.include FactoryGirl::Syntax::Methods
  config.include Spree::TestingSupport::UrlHelpers
  config.include BraintreeHelpers

  config.before(:each, type: :feature, js: true) do |ex|
    Capybara.current_driver = ex.metadata[:driver] || :poltergeist
  end

  config.before :suite do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with :truncation
  end

  config.before :each do
    DatabaseCleaner.strategy = RSpec.current_example.metadata[:js] ? :truncation : :transaction
    DatabaseCleaner.start
  end

  config.after :each do
    DatabaseCleaner.clean
  end
end
