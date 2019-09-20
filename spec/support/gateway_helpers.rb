module SolidusPaypalBraintree::GatewayHelpers
  def new_gateway(opts = {})
    SolidusPaypalBraintree::Gateway.new({
      name: "Braintree",
      preferences: {
        environment: 'sandbox',
        public_key: ENV.fetch('BRAINTREE_PUBLIC_KEY', 'dummy_public_key'),
        private_key: ENV.fetch('BRAINTREE_PRIVATE_KEY', 'dummy_private_key'),
        merchant_id: ENV.fetch('BRAINTREE_MERCHANT_ID', 'dummy_merchant_id'),
        merchant_currency_map: {
          'EUR' => 'stembolt_EUR'
        },
        paypal_payee_email_map: {
          'EUR' => ENV.fetch('BRAINTREE_PAYPAL_PAYEE_EMAIL', 'paypal+europe@example.com')
        }
      }
    }.merge(opts))
  end

  def create_gateway(opts = {})
    new_gateway(opts).tap(&:save!)
  end
end

RSpec.configure do |config|
  config.include SolidusPaypalBraintree::GatewayHelpers
end
