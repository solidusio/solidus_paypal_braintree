# frozen_string_literal: true

module SolidusBraintree
  module CheckoutControllerDecorator
    def self.prepended(base)
      base.helper ::SolidusBraintree::BraintreeCheckoutHelper
    end

    ::Spree::CheckoutController.prepend(self) if SolidusSupport.frontend_available?
  end
end
