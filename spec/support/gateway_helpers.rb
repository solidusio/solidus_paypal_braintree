module SolidusPaypalBraintree::GatewayHelpers
  def new_gateway(opts = {})
    SolidusPaypalBraintree::Gateway.new({
      name: "Braintree",
      preferences: {
        environment: 'sandbox',
        public_key:  'mwjkkxwcp32ckhnf',
        private_key: 'a9298f43b30c699db3072cc4a00f7f49',
        merchant_id: '7rdg92j7bm7fk5h3',
        merchant_currency_map: {
          'EUR' => 'stembolt_EUR'
        },
        paypal_payee_email_map: {
          'EUR' => 'paypal+europe@example.com'
        }
      }
    }.merge(opts))
  end

  def create_gateway(opts = {})
    new_gateway(opts).tap(&:save!)
  end

  # Using order.update! was deprecated in Solidus v2.3
  def recalculate(order)
    order.respond_to?(:recalculate) ? order.recalculate : order.update!
  end
end
