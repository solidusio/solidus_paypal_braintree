module SolidusPaypalBraintree
  class Engine < Rails::Engine
    require 'spree/core'
    isolate_namespace Spree
    engine_name 'solidus_paypal_braintree'

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    initializer "register_solidus_paypal_braintree_gateway", after: "spree.register.payment_methods" do |app|
      app.config.spree.payment_methods << SolidusPaypalBraintree::Gateway
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    config.to_prepare(&method(:activate).to_proc)
  end
end
