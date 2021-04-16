# frozen_string_literal: true

Spree.config do |config|
  config.static_model_preferences.add(
    SolidusPaypalBraintree::Gateway,
    'braintree_credentials', {
      environment: Rails.env.production? ? 'production' : 'sandbox',
      merchant_id: ENV['BRAINTREE_MERCHANT_ID'],
      public_key: ENV['BRAINTREE_PUBLIC_KEY'],
      private_key: ENV['BRAINTREE_PRIVATE_KEY'],
      paypal_flow: 'vault', # 'checkout' is accepted too
    }
  )
end
