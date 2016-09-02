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
    @payment = Spree::PaymentCreate.new(@order, payment_params).build

    if @payment.save
      render text: "ok"
    else
      render text: "not-ok"
    end
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
