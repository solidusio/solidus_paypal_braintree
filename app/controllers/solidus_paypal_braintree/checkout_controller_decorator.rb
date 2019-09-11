module SolidusPaypalBraintree
  module CheckoutControllerDecorator

    def self.prepended(base)
      base.helper ::SolidusPaypalBraintree::BraintreeCheckoutHelper
    end

    ::Spree::CheckoutController.prepend(self)
  end
end
