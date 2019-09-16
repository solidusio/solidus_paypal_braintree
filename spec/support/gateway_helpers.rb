module SolidusPaypalBraintree::GatewayHelpers
  def new_gateway(opts = {})
    SolidusPaypalBraintree::Gateway.new({
      name: "Braintree",
      preferences: {
        environment: 'sandbox',
        public_key: ENV['BRAINTREE_PUBLIC_KEY'],
        private_key: ENV['BRAINTREE_PRIVATE_KEY'],
        merchant_id: ENV['BRAINTREE_MERCHANT_ID'],
        merchant_currency_map: {
          'EUR' => 'stembolt_EUR'
        },
        paypal_payee_email_map: {
          'EUR' => ENV['BRAINTREE_PAYPAL_PAYEE_EMAIL']
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
