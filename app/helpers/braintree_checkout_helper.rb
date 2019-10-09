module BraintreeCheckoutHelper
  def paypal_button_preference(key, store:)
    store.braintree_configuration.preferences[key]
  end
end
