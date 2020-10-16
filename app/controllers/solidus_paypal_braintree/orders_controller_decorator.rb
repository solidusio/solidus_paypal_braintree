module SolidusPaypalBraintree
  module OrdersControllerDecorator

    def self.prepended(base)
      base.helper ::SolidusPaypalBraintree::BraintreeCheckoutHelper
    end

    ::Spree::OrdersController.prepend(self)
  end
end
