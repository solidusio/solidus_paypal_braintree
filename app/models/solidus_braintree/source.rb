# frozen_string_literal: true

require 'solidus_braintree/request_protection'

module SolidusBraintree
  class Source < ::Spree::PaymentSource
    include RequestProtection

    PAYPAL = "PayPalAccount"
    APPLE_PAY = "ApplePayCard"
    VENMO = "VenmoAccount"
    CREDIT_CARD = "CreditCard"

    enum paypal_funding_source: {
      applepay: 0, bancontact: 1, blik: 2, boleto: 3, card: 4, credit: 5, eps: 6, giropay: 7, ideal: 8,
      itau: 9, maxima: 10, mercadopago: 11, mybank: 12, oxxo: 13, p24: 14, paylater: 15, paypal: 16, payu: 17,
      sepa: 18, sofort: 19, trustly: 20, venmo: 21, verkkopankki: 22, wechatpay: 23, zimpler: 24
    }, _suffix: :funding

    belongs_to :user, class_name: ::Spree::UserClassHandle.new, optional: true
    belongs_to :payment_method, class_name: 'Spree::PaymentMethod'
    has_many :payments, as: :source, class_name: "Spree::Payment", dependent: :destroy

    belongs_to :customer, class_name: "SolidusBraintree::Customer", optional: true

    validates :payment_type, inclusion: [PAYPAL, APPLE_PAY, VENMO, CREDIT_CARD]

    before_save :clear_paypal_funding_source, unless: :paypal?

    scope(:with_payment_profile, -> { joins(:customer) })
    scope(:credit_card, -> { where(payment_type: CREDIT_CARD) })

    delegate :bin, :last_4, :card_type, :expiration_month, :expiration_year, :email,
      :username, :source_description, to: :braintree_payment_method, allow_nil: true

    # Aliases to match Spree::CreditCard's interface
    alias_method :last_digits, :last_4
    alias_method :month, :expiration_month
    alias_method :year, :expiration_year
    alias_method :cc_type, :card_type

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
      return false unless payment.response_code

      transaction = protected_request do
        braintree_client.transaction.find(payment.response_code)
      end
      Gateway::VOIDABLE_STATUSES.include?(transaction.status)
    rescue ActiveMerchant::ConnectionError
      false
    end

    def can_credit?(payment)
      payment.completed? && payment.credit_allowed > 0
    end

    def friendly_payment_type
      I18n.t(payment_type.underscore, scope: "solidus_braintree.payment_type")
    end

    def apple_pay?
      payment_type == APPLE_PAY
    end

    def paypal?
      payment_type == PAYPAL
    end

    def venmo?
      payment_type == VENMO
    end

    def reusable?
      token.present?
    end

    def credit_card?
      payment_type == CREDIT_CARD
    end

    def display_number
      if paypal?
        email
      elsif venmo?
        username
      else
        "XXXX-XXXX-XXXX-#{last_digits.to_s.rjust(4, 'X')}"
      end
    end

    def display_paypal_funding_source
      I18n.t(paypal_funding_source,
        scope: 'solidus_braintree.paypal_funding_sources',
        default: paypal_funding_source)
    end

    def display_payment_type
      "#{I18n.t('solidus_braintree.payment_type.label')}: #{friendly_payment_type}"
    end

    private

    def braintree_payment_method
      return unless braintree_client

      @braintree_payment_method ||= protected_request do
        braintree_client.payment_method.find(token)
      end
    rescue ActiveMerchant::ConnectionError, ArgumentError => e
      Rails.logger.warn("#{e}: token unknown or missing for #{inspect}")
      nil
    end

    def braintree_client
      @braintree_client ||= payment_method.try(:braintree)
    end

    def clear_paypal_funding_source
      self.paypal_funding_source = nil
    end
  end
end
