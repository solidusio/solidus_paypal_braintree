# frozen_string_literal: true

module SolidusBraintree
  class CheckoutsController < ::Spree::CheckoutController
    PERMITTED_PAYMENT_PARAMS = [
      :payment_method_id,
      { source_attributes: [
        :nonce,
        :payment_type
      ] }
    ].freeze

    def update
      @payment = ::Spree::PaymentCreate.new(@order, payment_params).build

      if @payment.save
        render plain: "ok"
      else
        render plain: "not-ok"
      end
    end

    def payment_params
      params.
        require(:order).
        require(:payments_attributes).
        first.
        permit(PERMITTED_PAYMENT_PARAMS)
    end
  end
end
