# frozen_string_literal: true

require 'solidus_core'
require 'solidus_support'

module SolidusPaypalBraintree
  class Engine < Rails::Engine
    include SolidusSupport::EngineExtensions

    isolate_namespace SolidusPaypalBraintree
    engine_name 'solidus_paypal_braintree'
  end
end
