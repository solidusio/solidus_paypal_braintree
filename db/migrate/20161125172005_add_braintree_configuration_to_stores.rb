class AddBraintreeConfigurationToStores < SolidusSupport::Migration[4.2]
  # The content of this migration has been removed because store's Braintree
  # configuration doesn't already have paypal_button_preferences fields, so
  # their validations will break this migration.
  #
  # Ref here for more info https://github.com/solidusio/solidus_paypal_braintree/pull/249
end
