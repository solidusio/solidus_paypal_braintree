require 'solidus_support'

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

    if SolidusSupport.frontend_available?
      config.assets.precompile += [
        'solidus_paypal_braintree/checkout.js',
        'solidus_paypal_braintree/frontend.js',
        'spree/frontend/apple_pay_button.js'
      ]
      paths["app/controllers"] << "lib/controllers/frontend"
      paths["app/views"] << "lib/views/frontend"
    end

    if SolidusSupport.backend_available?
      config.assets.precompile += ["spree/backend/solidus_paypal_braintree.js"]
      paths["app/controllers"] << "lib/controllers/backend"

      # We support Solidus v1.2, which requires some different markup in the
      # source form partial. This will take precedence over lib/views/backend.
      paths["app/views"] << "lib/views/backend_v1.2" if SolidusSupport.solidus_gem_version < Gem::Version.new('1.3')

      # Solidus v2.4 introduced preference field partials but does not ship a hash field type.
      # This is solved in Solidus v2.5.
      if SolidusSupport.solidus_gem_version <= Gem::Version.new('2.5.0')
        paths["app/views"] << "lib/views/backend_v2.4"
      end

      paths["app/views"] << "lib/views/backend"

      initializer "solidus_paypal_braintree_admin_menu_item", after: "register_solidus_paypal_braintree_gateway" do |app|
        Spree::Backend::Config.configure do |config|
          config.menu_items << config.class::MenuItem.new(
            [:braintree],
            'cc-paypal',
            url: '/solidus_paypal_braintree/configurations/list',
            condition: -> { can?(:list, SolidusPaypalBraintree::Configuration) }
          )
        end
      end
    end
  end
end
