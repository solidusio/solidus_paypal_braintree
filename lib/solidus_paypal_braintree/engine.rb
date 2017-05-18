module SolidusPaypalBraintree
  class Engine < Rails::Engine
    isolate_namespace SolidusPaypalBraintree
    engine_name 'solidus_paypal_braintree'

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    initializer "register_solidus_paypal_braintree_gateway", after: "spree.register.payment_methods" do |app|
      app.config.spree.payment_methods << SolidusPaypalBraintree::Gateway
      Spree::PermittedAttributes.source_attributes.concat [:nonce, :payment_type]
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    config.assets.precompile += ["spree/backend/solidus_paypal_braintree"]

    config.to_prepare(&method(:activate).to_proc)

    def self.frontend_available?
      defined?(Spree::Frontend::Engine) == "constant"
    end

    def self.backend_available?
      defined?(Spree::Backend::Engine) == "constant"
    end

    if frontend_available?
      config.assets.precompile += [
        'spree/frontend/solidus_paypal_braintree',
        'spree/frontend/paypal_button',
        'spree/checkout/braintree'
      ]
      paths["app/controllers"] << "lib/controllers/frontend"
      paths["app/views"] << "lib/views/frontend"
    end

    if backend_available?
      paths["app/controllers"] << "lib/controllers/backend"
      paths["app/views"] << "lib/views/backend"
    end
  end
end
