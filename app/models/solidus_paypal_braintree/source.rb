class SolidusPaypalBraintree::Source < ApplicationRecord
  belongs_to :user, class_name: "Spree::User"
  belongs_to :payment_method, class_name: 'Spree::PaymentMethod'
  has_many :payments, as: :source, class_name: "Spree::Payment"

  belongs_to :customer, class_name: "SolidusPaypalBraintree::Customer"

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
end
