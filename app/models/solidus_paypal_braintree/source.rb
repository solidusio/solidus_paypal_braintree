module SolidusPaypalBraintree
  class Source < ApplicationRecord
    PAYPAL = "PayPalAccount"
    APPLE_PAY = "ApplePayCard"

    belongs_to :user, class_name: "Spree::User"
    belongs_to :payment_method, class_name: 'Spree::PaymentMethod'
    has_many :payments, as: :source, class_name: "Spree::Payment"

    belongs_to :customer, class_name: "SolidusPaypalBraintree::Customer"

    scope :with_payment_profile, -> { joins(:customer) }

    delegate :last_4, :card_type, to: :braintree_payment_method

    # we are not currenctly supporting an "imported" flag
    def imported
      false
    end

    def actions
      %w[capture void credit]
    end

    def can_capture?(payment)
      payment.pending? || payment.checkout?
    end

    def can_void?(payment)
      !payment.failed? && !payment.void?
    end

    def can_credit?(payment)
      payment.completed? && payment.credit_allowed > 0
    end

    def friendly_payment_type
      I18n.t(payment_type.underscore, scope: "solidus_paypal_braintree.payment_type")
    end

    def apple_pay?
      payment_type == APPLE_PAY
    end

    def paypal?
      payment_type == PAYPAL
    end

    private

    def braintree_payment_method
      @braintree_payment_method ||= braintree_client.payment_method.find(token)
    end

    def braintree_client
      @braintree_client ||= payment_method.braintree
    end
  end
end
