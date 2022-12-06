# frozen_string_literal: true

require 'solidus_core'
require 'solidus_support'

module SolidusBraintree
  class Engine < Rails::Engine
    include SolidusSupport::EngineExtensions

    isolate_namespace SolidusBraintree
    engine_name 'solidus_braintree'

    ActiveSupport::Inflector.inflections do |inflect|
      inflect.acronym 'AVS'
    end

    initializer "register_solidus_braintree_gateway", after: "spree.register.payment_methods" do |app|
      config.to_prepare do
        app.config.spree.payment_methods << SolidusBraintree::Gateway
        SolidusBraintree::Gateway.allowed_admin_form_preference_types.push(:preference_select).uniq!
        ::Spree::PermittedAttributes.source_attributes.concat([:nonce, :payment_type, :paypal_funding_source]).uniq!
      end
    end

    if SolidusSupport.frontend_available?
      config.assets.precompile += [
        'solidus_braintree/checkout.js',
        'solidus_braintree/frontend.js',
        'spree/frontend/apple_pay_button.js',
        'solidus_braintree_manifest.js'
      ]
      paths["app/controllers"] << "lib/controllers/frontend"
      paths["app/views"] << "lib/views/frontend"
    end

    if SolidusSupport.backend_available?
      config.assets.precompile += ["spree/backend/solidus_braintree.js"]
      paths["app/controllers"] << "lib/controllers/backend"

      # We support Solidus v1.2, which requires some different markup in the
      # source form partial. This will take precedence over lib/views/backend.
      paths["app/views"] << "lib/views/backend_v1.2" if Spree.solidus_gem_version < Gem::Version.new('1.3')

      # Solidus v2.4 introduced preference field partials but does not ship a hash field type.
      # This is solved in Solidus v2.5.
      if Spree.solidus_gem_version <= Gem::Version.new('2.5.0')
        paths["app/views"] << "lib/views/backend_v2.4"
      end

      paths["app/views"] << "lib/views/backend"

      initializer "solidus_braintree_admin_menu_item", after: "register_solidus_braintree_gateway" do
        Spree::Backend::Config.configure do |config|
          config.menu_items << config.class::MenuItem.new(
            [:braintree],
            'cc-paypal',
            url: '/solidus_braintree/configurations/list',
            condition: -> { can?(:list, SolidusBraintree::Configuration) }
          )
        end
      end
    end

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
