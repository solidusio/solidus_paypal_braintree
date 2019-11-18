if SolidusSupport.backend_available?
  Spree::Admin::PaymentsController.helper :braintree_admin
end

if SolidusSupport.frontend_available?
  Spree::CheckoutController.helper :braintree_checkout
  Spree::OrdersController.helper :braintree_checkout
end
