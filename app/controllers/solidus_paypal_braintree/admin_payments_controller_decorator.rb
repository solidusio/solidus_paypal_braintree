module SolidusPaypalBraintree
  module AdminPaymentsControllerDecorator

    def self.prepended(base)
      base.helper ::SolidusPaypalBraintree::BraintreeAdminHelper
    end

    ::Spree::Admin::PaymentsController.prepend(self)
  end
end
