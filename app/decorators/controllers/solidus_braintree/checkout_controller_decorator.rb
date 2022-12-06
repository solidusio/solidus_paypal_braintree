# frozen_string_literal: true

module SolidusPaypalBraintree
  module CheckoutControllerDecorator
    def self.prepended(base)
      base.helper ::SolidusPaypalBraintree::BraintreeCheckoutHelper
    end

    ::Spree::CheckoutController.prepend(self) if SolidusSupport.frontend_available?
  end
end
