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

    config.to_prepare(&method(:activate).to_proc)

    def self.frontend_available?
      defined?(Spree::Frontend::Engine) == "constant"
    end

    def self.backend_available?
      defined?(Spree::Backend::Engine) == "constant"
    end

    if frontend_available?
      config.assets.precompile += [
        'solidus_paypal_braintree/checkout.js',
        'solidus_paypal_braintree/frontend.js',
        'spree/frontend/paypal_button.js'
      ]
      paths["app/controllers"] << "lib/controllers/frontend"
      paths["app/views"] << "lib/views/frontend"
    end

    if backend_available?
      config.assets.precompile += ["spree/backend/solidus_paypal_braintree.js"]
      paths["app/controllers"] << "lib/controllers/backend"

      # We support Solidus v1.2, which requires some different markup in the
      # source form partial. This will take precedence over lib/views/backend.
      paths["app/views"] << "lib/views/backend_v1.2" if Gem::Version.new(Spree.solidus_version) < Gem::Version.new('1.3')

      paths["app/views"] << "lib/views/backend"
    end
  end
end
