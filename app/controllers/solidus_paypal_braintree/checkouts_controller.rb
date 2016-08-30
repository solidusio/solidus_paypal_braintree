class SolidusPaypalBraintree::CheckoutsController < Spree::CheckoutController
  PERMITTED_ORDER_PARAMS = [
  ].freeze

  PERMITTED_PAYMENT_PARAMS = [
    :payment_method_id,
    source_attributes: [
      :nonce,
      :payment_type
    ]
  ].freeze

  def update
    @order.payments.create!(payment_params)

    render text: 'ok'
  end

  def order_params
    params.require(:order).permit(PERMITTED_ORDER_PARAMS)
  end

  def payment_params
    params.
      require(:order).
      require(:payments_attributes).
      first.
      permit(PERMITTED_PAYMENT_PARAMS)
  end
end
