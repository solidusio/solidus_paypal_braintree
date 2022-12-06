# frozen_string_literal: true

module SolidusBraintree
  module OrdersControllerDecorator
    def self.prepended(base)
      base.helper ::SolidusBraintree::BraintreeCheckoutHelper
    end

    ::Spree::OrdersController.prepend(self) if SolidusSupport.frontend_available?
  end
end
