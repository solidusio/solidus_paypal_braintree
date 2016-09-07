class SolidusPaypalBraintree::Source < ApplicationRecord
  belongs_to :user, class_name: "Spree::User"
  belongs_to :payment_method, class_name: 'Spree::PaymentMethod'

  belongs_to :customer, class_name: "SolidusPaypalBraintree::Customer"

  # we are not currenctly supporting an "imported" flag
  def imported
    false
  end
end
