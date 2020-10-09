if SolidusSupport.backend_available?
  Spree::Admin::PaymentsController.helper :braintree_admin
end
