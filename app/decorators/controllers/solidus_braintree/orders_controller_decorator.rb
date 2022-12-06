# frozen_string_literal: true

module SolidusPaypalBraintree
  module OrdersControllerDecorator
    def self.prepended(base)
      base.helper ::SolidusPaypalBraintree::BraintreeCheckoutHelper
    end

    ::Spree::OrdersController.prepend(self) if SolidusSupport.frontend_available?
  end
end
